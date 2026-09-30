"""
Endpoint de Orquestração do Cálculo do Índice de Harmonia Estética (IHE)
Integração com o motor determinístico (Etapa 1) e controle da Cota Freemium (RN02, RF07, RF13)
"""

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.config import settings
from app.core.quota import charge_look, has_reached_look_limit, look_request_signature, was_charged_today
from app.core.security import get_current_user
from app.models.entities import User, ClothingItem
from app.schemas.dtos import (
    OutfitCalculateRequest,
    OutfitGenerateRequest,
    RecommendedOutfitResponse,
    ClothingItemResponse,
    ParityMatchResponse,
    StoreParityRequest,
    StoreParityResponse,
)
from app.engine.ihe_calculator import calculate_ihe, IHERequest, IHEResponse
from app.engine.color_science import LabColor, calculate_garment_s_cor
from app.engine.outfit_generator import rank_store_parity

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

    signature = look_request_signature(
        user,
        [item.id for item in items],
        payload.occasion,
        round(payload.temperature_celsius),
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
    )
    parity = rank_store_parity(
        store_item,
        items,
        user,
        occasion=payload.occasion,
        temperature_celsius=payload.temperature_celsius,
        is_raining=payload.is_raining,
        limit=payload.limit,
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
