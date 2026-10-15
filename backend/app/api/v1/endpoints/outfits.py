"""
Endpoint de Orquestração do Cálculo do Índice de Harmonia Estética (IHE)
Integração com o motor determinístico (Etapa 1) e controle da Cota Freemium (RN02, RF07, RF13)
"""

import uuid
from datetime import datetime, timezone
from typing import FrozenSet, List, Set, Tuple
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.config import settings
from app.core.quota import charge_look, has_reached_look_limit, look_request_signature, was_charged_today
from app.core.security import get_current_user
from app.models.entities import User, ClothingItem, LookFeedback
from app.schemas.dtos import (
    OutfitCalculateRequest,
    OutfitGenerateRequest,
    RecommendedOutfitResponse,
    ClothingItemResponse,
    LookFeedbackCreate,
    LookFeedbackResponse,
    ParityMatchResponse,
    StoreParityRequest,
    StoreParityResponse,
    PartnerProductResponse,
    WardrobeGapResponse,
    WardrobeGapsResponse,
)
from app.engine.ihe_calculator import calculate_ihe, IHERequest, IHEResponse
from app.engine.color_science import LabColor, calculate_garment_s_cor
from app.engine.outfit_generator import rank_store_parity, temperature_band
from app.engine.style_vector import build_style_space
from app.engine.context_rules import normalize_occasion
from app.engine.gap_analysis import analyze_gaps
from app.engine.partner_catalog import STORE_NAMES, StaticPartnerCatalog, partner_search_url
from app.vision.color_extraction import lab_to_hex

router = APIRouter()


def _look_quota_exceeded() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail=(
            f"Limite da cota Freemium de combinações diárias atingido (máximo {settings.FREEMIUM_MAX_DAILY_LOOKS} por dia). "
            "Faça upgrade para o Premium."
        ),
    )


@router.post("/calculate-ihe", response_model=IHEResponse, status_code=status.HTTP_200_OK)
async def calculate_ihe_endpoint(
    payload: OutfitCalculateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Orquestra o cálculo do IHE invocando a fórmula mestra determinística.
    Aplica controle de cota Freemium diária de 5 combinações por IA (RN02).
    """
    # Validação estrita da Cota Freemium Diária (RN02)
    if has_reached_look_limit(user):
        raise _look_quota_exceeded()

    # 1. Determinar cor representativa no espaço CIE L*a*b*
    garment_color: LabColor
    if payload.direct_garment_color:
        garment_color = payload.direct_garment_color
    elif payload.item_ids:
        stmt_items = select(ClothingItem).where(
            ClothingItem.id.in_(payload.item_ids),
            ClothingItem.user_id == user.id
        )
        res_items = await db.execute(stmt_items)
        items = res_items.scalars().all()

        if items:
            avg_l = sum(item.dominant_l for item in items) / len(items)
            avg_a = sum(item.dominant_a for item in items) / len(items)
            avg_b = sum(item.dominant_b for item in items) / len(items)
            garment_color = LabColor(L=avg_l, a=avg_a, b=avg_b)
        else:
            garment_color = LabColor(L=50.0, a=0.0, b=0.0)
    else:
        garment_color = LabColor(L=50.0, a=0.0, b=0.0)

    # 2. Montar estrutura de dados IHERequest para o motor determinístico
    ihe_req = IHERequest(
        garment_color=garment_color,
        user_palette=payload.user_palette,
        user_biotype=payload.user_biotype,
        garment_cuts=payload.garment_cuts,
        garment_formality=payload.garment_formality,
        occasion=payload.occasion,
        temperature_celsius=payload.temperature_celsius,
        is_raining=payload.is_raining,
        garment_thermal_category=payload.garment_thermal_category,
        user_style_vector=payload.user_style_vector,
        look_style_vector=payload.look_style_vector,
    )

    # 3. Processar o IHE compilado e decomposição dos 4 pilares
    ihe_result = calculate_ihe(ihe_req)

    # 4. Incrementar contador diário de looks do usuário
    charge_look(user)
    await db.commit()

    return ihe_result


@router.post("/generate-daily", response_model=List[RecommendedOutfitResponse], status_code=status.HTTP_200_OK)
async def generate_daily_outfits(
    payload: OutfitGenerateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Gera automaticamente combinações completas de looks a partir do acervo do usuário (RF07).
    Varre o inventário ativo, compõe candidatos viáveis e ranqueia pelo IHE determinístico.
    Aplica controle de cota Freemium diária de 5 combinações por IA (RN02): só consultas
    novas gastam cota, e um acervo sem combinações não gasta nada.
    """
    # Buscar itens ativos do usuário (RN01 - isolamento estrito)
    stmt_items = select(ClothingItem).where(
        ClothingItem.user_id == user.id,
        ClothingItem.is_archived == False
    )
    res_items = await db.execute(stmt_items)
    items = res_items.scalars().all()

    if not items:
        return []

    approved, discarded = await _feedback_looks(db, user)

    signature = look_request_signature(
        user,
        [item.id for item in items],
        # Descartes mudam o resultado: gerar de novo depois deles é uma consulta nova
        ";".join(sorted(",".join(sorted(look)) for look in discarded)),
        payload.occasion,
        # Clima real varia ao longo do dia; só a faixa muda o resultado
        temperature_band(payload.temperature_celsius),
        payload.is_raining,
        payload.limit,
    )
    repeated = was_charged_today(user, signature)

    # Validação estrita da Cota Freemium Diária (RN02)
    if not repeated and has_reached_look_limit(user):
        raise _look_quota_exceeded()

    # Gerar recomendações ranqueadas
    from app.engine.outfit_generator import generate_outfit_recommendations
    recommendations = generate_outfit_recommendations(
        items=list(items),
        user=user,
        occasion=payload.occasion,
        temperature_celsius=payload.temperature_celsius,
        is_raining=payload.is_raining,
        limit=payload.limit,
        excluded_looks=discarded,
        # Aprovações reordenam o ranking sem gastar cota: só descartes mudam a assinatura
        style=build_style_space(list(items), approved, discarded),
    )

    # Incrementa cota Freemium diária utilizada
    if recommendations and not repeated:
        charge_look(user, signature)
    await db.commit()

    # Mapear para DTOs de resposta
    response_list = []
    for rec in recommendations:
        response_list.append(
            RecommendedOutfitResponse(
                items=[ClothingItemResponse.model_validate(it) for it in rec.items],
                ihe_score=rec.ihe_result.ihe_score,
                ihe_percentage=rec.ihe_result.ihe_percentage,
                s_cor=rec.ihe_result.s_cor,
                s_bio=rec.ihe_result.s_bio,
                s_ocasion=rec.ihe_result.s_ocasion,
                s_cos=rec.ihe_result.s_cos,
                is_strongly_recommended=rec.ihe_result.is_strongly_recommended,
                styling_advice=rec.styling_advice,
                occasion=payload.occasion,
            )
        )

    return response_list



def _parity_rationale(ihe: IHEResponse) -> str:
    """Motivo curto da paridade, a partir dos pilares cromático e morfológico."""
    reasons = []
    if ihe.s_cor >= 0.80:
        reasons.append("cores em harmonia com a sua cartela")
    if ihe.s_bio >= 0.80:
        reasons.append("silhueta equilibrada para o seu biótipo")
    if not reasons:
        return "Combinação possível, com harmonia moderada."
    text = " e ".join(reasons)
    return text[0].upper() + text[1:] + "."


@router.post("/store-parity", response_model=StoreParityResponse, status_code=status.HTTP_200_OK)
async def analyze_store_parity(
    payload: StoreParityRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Compara uma peça vista na loja com o acervo do usuário (RF08, RF09).
    Monta looks com a peça da loja e as peças de casa, ranqueia as peças pelo IHE do melhor
    look que cada uma forma e não grava nada. Por decisão de produto, não gasta a cota RN02.
    """
    stmt_items = select(ClothingItem).where(
        ClothingItem.user_id == user.id,
        ClothingItem.is_archived == False
    )
    items = list((await db.execute(stmt_items)).scalars().all())

    # Peça transitória: existe só durante o cálculo, nunca entra na sessão
    store_item = ClothingItem(
        category=payload.category,
        dominant_l=payload.dominant_l,
        dominant_a=payload.dominant_a,
        dominant_b=payload.dominant_b,
        formality_score=payload.formality_score,
        style_embedding=payload.style_embedding,
    )
    approved, discarded = await _feedback_looks(db, user)
    parity = rank_store_parity(
        store_item,
        items,
        user,
        occasion=payload.occasion,
        temperature_celsius=payload.temperature_celsius,
        is_raining=payload.is_raining,
        limit=payload.limit,
        # O centro vem só do acervo: a peça da loja é medida contra o gosto, não o desloca
        style=build_style_space(items, approved, discarded),
    )

    palette_harmony = None
    if user.seasonal_palette:
        color = LabColor(L=payload.dominant_l, a=payload.dominant_a, b=payload.dominant_b)
        palette_harmony = round(calculate_garment_s_cor(color, user.seasonal_palette), 4)

    best = parity.best_look
    return StoreParityResponse(
        ihe_percentage=best.ihe_result.ihe_percentage if best else 0.0,
        is_strongly_recommended=best.ihe_result.is_strongly_recommended if best else False,
        palette_harmony=palette_harmony,
        styling_advice=best.styling_advice if best else None,
        looks_evaluated=parity.looks_evaluated,
        strong_looks=parity.strong_looks,
        matches=[
            ParityMatchResponse(
                item=ClothingItemResponse.model_validate(match.item),
                ihe_percentage=match.best_look.ihe_result.ihe_percentage,
                s_cor=match.best_look.ihe_result.s_cor,
                s_bio=match.best_look.ihe_result.s_bio,
                is_strongly_recommended=match.best_look.ihe_result.is_strongly_recommended,
                rationale=_parity_rationale(match.best_look.ihe_result),
            )
            for match in parity.matches
        ],
    )


# -----------------------------------------------------------------------------
# Lacunas do Acervo e Afiliação (RF11, RF12, RN03)
# -----------------------------------------------------------------------------

@router.get("/gaps", response_model=WardrobeGapsResponse, status_code=status.HTTP_200_OK)
async def wardrobe_gaps(
    occasion: str = Query(default="CASUAL", description="Ocasião usada para pontuar os looks"),
    limit: int = Query(default=3, ge=1, le=5),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Peças-chave que faltam no acervo (RF11) e onde comprá-las nos parceiros (RF12).
    Cada lacuna vale os looks fortemente recomendados que destrava com as peças do usuário;
    produtos esgotados nunca saem daqui (RN03). Só lê o acervo do próprio usuário (RN01)
    e, como a paridade em loja, não gasta a cota RN02.
    """
    try:
        occasion = normalize_occasion(occasion)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail=str(exc))

    items = list((await db.execute(
        select(ClothingItem).where(ClothingItem.user_id == user.id, ClothingItem.is_archived == False)
    )).scalars().all())
    approved, discarded = await _feedback_looks(db, user)
    analysis = analyze_gaps(
        items,
        user,
        StaticPartnerCatalog().archetypes(),
        occasion=occasion,
        limit=limit,
        style=build_style_space(items, approved, discarded),
    )

    return WardrobeGapsResponse(
        occasion=occasion,
        baseline_ihe_percentage=analysis.baseline_ihe_percentage,
        gaps=[
            WardrobeGapResponse(
                id=gap.archetype.id,
                title=gap.archetype.title,
                category=gap.archetype.category,
                rationale=gap.rationale,
                color_hex=lab_to_hex(gap.archetype.L, gap.archetype.a, gap.archetype.b),
                looks_evaluated=gap.looks_evaluated,
                strong_looks=gap.strong_looks,
                best_ihe_percentage=gap.best_ihe_percentage,
                delta_ihe=gap.delta_ihe,
                products=[
                    PartnerProductResponse(
                        id=product.id,
                        store=product.store,
                        store_name=STORE_NAMES[product.store],
                        name=product.name,
                        color_hex=lab_to_hex(product.L, product.a, product.b),
                        url=partner_search_url(product.store, product.search_query, gap.archetype.id),
                    )
                    for product in gap.products
                ],
            )
            for gap in analysis.gaps
        ],
    )


# -----------------------------------------------------------------------------
# Feedback de Recomendações (RF13)
# -----------------------------------------------------------------------------

async def _feedback_looks(db: AsyncSession, user: User) -> Tuple[List[FrozenSet[str]], Set[FrozenSet[str]]]:
    """
    Looks aprovados e descartados pelo usuário (RF13), como conjuntos de IDs de peças.
    Aprovados puxam o vetor de estilo (S_cos); descartados o empurram e nunca voltam como sugestão.
    """
    stmt = select(LookFeedback).where(LookFeedback.user_id == user.id)
    feedback = (await db.execute(stmt)).scalars().all()

    def looks(action: str) -> List[FrozenSet[str]]:
        return [frozenset(str(i) for i in entry.item_ids) for entry in feedback if entry.action == action]

    return looks("APPROVED"), set(looks("DISCARDED"))


@router.post("/feedback", response_model=LookFeedbackResponse, status_code=status.HTTP_201_CREATED)
async def create_look_feedback(
    payload: LookFeedbackCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Registra a aprovação ou o descarte de um look sugerido (RF13).
    Todas as peças precisam ser do usuário autenticado (RN01).
    """
    stmt = select(ClothingItem).where(
        ClothingItem.user_id == user.id,
        ClothingItem.id.in_(payload.item_ids),
    )
    owned = {item.id for item in (await db.execute(stmt)).scalars().all()}
    if owned != set(payload.item_ids):
        # 404 e não 403: não revela se a peça existe em outra conta
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Peça do look não encontrada no seu acervo.")

    feedback = LookFeedback(
        id=uuid.uuid4(),
        user_id=user.id,
        item_ids=[str(i) for i in payload.item_ids],
        action=payload.action,
        occasion=payload.occasion,
        ihe_percentage=payload.ihe_percentage,
        created_at=datetime.now(timezone.utc),
    )
    db.add(feedback)
    await db.commit()
    return LookFeedbackResponse.model_validate(feedback)


@router.delete("/feedback/{feedback_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_look_feedback(
    feedback_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Desfaz uma aprovação ou um descarte; o look volta a poder ser sugerido."""
    stmt = select(LookFeedback).where(LookFeedback.id == feedback_id, LookFeedback.user_id == user.id)
    feedback = (await db.execute(stmt)).scalars().first()
    if feedback is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Feedback não encontrado.")
    await db.delete(feedback)
    await db.commit()
