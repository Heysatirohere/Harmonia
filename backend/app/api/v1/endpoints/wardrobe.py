"""
CRUD de Peças do Acervo Virtual com Isolamento Multi-Tenant (RN01) e Cota Freemium (RN02, RF06)
"""

from typing import List, Optional
from datetime import datetime, timezone
from uuid import UUID
import base64
import uuid

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from fastapi.concurrency import run_in_threadpool
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, asc, desc

from app.core.database import get_db
from app.core.config import settings
from app.core.security import get_current_user, get_current_user_id
from app.core.supabase_admin import SupabaseAdmin, SupabaseAdminError, get_supabase_admin
from app.models.entities import User, ClothingItem, LookFeedback
from app.schemas.dtos import (
    CapsuleSummaryResponse,
    ClothingItemCreate,
    ClothingItemResponse,
    ClothingItemUpdate,
    ColorShareResponse,
    ExtractedColorResponse,
    GarmentSuggestionResponse,
    GarmentUsageResponse,
    SegmentationResponse,
    WardrobeAnalyticsResponse,
    WardrobeItemResponse,
)
from app import vision
from app.vision import garment_attributes
from app.engine.wardrobe_analytics import color_distribution, color_family as calc_color_family, garment_usage, rotation_bucket

ACCEPTED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp"}

router = APIRouter()


async def _worn_on(db: AsyncSession, user_id: UUID) -> dict[str, list[datetime]]:
    """Datas de uso de cada peça: um uso por look aprovado que a contém (RF13). Só do próprio usuário (RN01)."""
    approved = (await db.execute(
        select(LookFeedback).where(LookFeedback.user_id == user_id, LookFeedback.action == "APPROVED")
    )).scalars().all()
    worn_on: dict[str, list[datetime]] = {}
    for look in approved:
        for item_id in look.item_ids:
            worn_on.setdefault(str(item_id), []).append(look.created_at)
    return worn_on


@router.post("/segment", response_model=SegmentationResponse, status_code=status.HTTP_200_OK)
async def segment_garment_photo(
    file: UploadFile = File(..., description="Foto da peça (JPEG, PNG ou WebP)"),
    current_user_id: UUID = Depends(get_current_user_id),
):
    """
    Remove o fundo da foto (RF04), extrai as cores dominantes em CIE L*a*b* e sugere categoria,
    nome com estampa e formalidade (RF05). Não persiste nada: o app confirma os atributos e
    envia o PNG ao Storage no cadastro.
    """
    if file.content_type not in ACCEPTED_IMAGE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Formato de imagem não suportado. Envie JPEG, PNG ou WebP."
        )

    data = await file.read(settings.MAX_UPLOAD_BYTES + 1)
    if len(data) > settings.MAX_UPLOAD_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_CONTENT_TOO_LARGE,
            detail="Foto muito grande. O limite é de 10 MB."
        )

    try:
        result = await run_in_threadpool(vision.segment_garment, data)
    except vision.InvalidImageError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail=str(exc))

    if not result.colors:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Nenhuma peça foi identificada na foto. Tente fotografar sobre um fundo liso."
        )

    return SegmentationResponse(
        image_png_base64=base64.b64encode(result.png_bytes).decode("ascii"),
        width=result.width,
        height=result.height,
        colors=[ExtractedColorResponse(**vars(c)) for c in result.colors],
        style_embedding=result.style_embedding,
        processing_ms=result.processing_ms,
        suggestion=_suggest(result.style_embedding),
    )


def _suggest(embedding: Optional[List[float]]) -> Optional[GarmentSuggestionResponse]:
    attrs = garment_attributes.classify(embedding) if embedding else None
    if attrs is None:
        return None
    return GarmentSuggestionResponse(
        category=attrs.category,
        name=attrs.name,
        pattern=attrs.pattern,
        formality=attrs.formality,
        confidence=attrs.category_confidence,
        cut_type=attrs.cut_type,
        thermal_category=attrs.thermal_category,
        season=attrs.season,
    )


def _compute_cost_per_use(purchase_price: Optional[float], wear_count: int) -> Optional[float]:
    if purchase_price is None or purchase_price <= 0:
        return None
    return round(float(purchase_price) / max(1, wear_count), 2)


@router.get("/items", response_model=List[WardrobeItemResponse], status_code=status.HTTP_200_OK)
async def list_clothing_items(
    current_user_id: UUID = Depends(get_current_user_id),
    category: Optional[str] = Query(None, description="Filtrar por categoria"),
    min_formality: Optional[float] = Query(None, ge=0.0, le=1.0, description="Formalidade mínima"),
    max_formality: Optional[float] = Query(None, ge=0.0, le=1.0, description="Formalidade máxima"),
    cut_type: Optional[str] = Query(None, description="Filtrar por corte/modelagem"),
    color_family: Optional[str] = Query(None, description="Filtrar por família cromática (ex: Azuis)"),
    season: Optional[str] = Query(None, description="Filtrar por estação (ex: VERAO, INVERNO)"),
    capsule: Optional[str] = Query(None, description="Filtrar por cápsula temática (ex: Mala de Viagem)"),
    usage_band: Optional[str] = Query(None, description="Filtrar por faixa de uso (active, idle_30, idle_60, dormant, never_worn)"),
    disposal_status: Optional[str] = Query(None, description="Filtrar por status ESG (ACTIVE, DONATED, DISCARDED)"),
    include_archived: bool = Query(False, description="Incluir peças arquivadas"),
    sort_by: str = Query("created_at", description="Campo para ordenação"),
    order: str = Query("desc", description="Direção da ordenação (asc ou desc)"),
    db: AsyncSession = Depends(get_db),
):
    """
    Lista peças do guarda-roupa do usuário logado (RN01) com suporte a filtros multicritérios (RF06).
    Cada peça traz a família cromática, o custo por uso e a frequência (looks aprovados).
    """
    stmt = select(ClothingItem).where(ClothingItem.user_id == current_user_id)

    if not include_archived and not disposal_status:
        stmt = stmt.where(ClothingItem.is_archived == False)

    if category:
        stmt = stmt.where(ClothingItem.category == category)

    if min_formality is not None:
        stmt = stmt.where(ClothingItem.formality_score >= min_formality)

    if max_formality is not None:
        stmt = stmt.where(ClothingItem.formality_score <= max_formality)

    if cut_type:
        stmt = stmt.where(ClothingItem.cut_type == cut_type)

    if sort_by == "formality_score":
        col = ClothingItem.formality_score
    elif sort_by == "category":
        col = ClothingItem.category
    else:
        col = ClothingItem.created_at

    if order.lower() == "asc":
        stmt = stmt.order_by(asc(col))
    else:
        stmt = stmt.order_by(desc(col))

    result = await db.execute(stmt)
    items = list(result.scalars().all())

    worn_on = await _worn_on(db, current_user_id)
    now = datetime.now(timezone.utc)
    responses: List[WardrobeItemResponse] = []
    for item in items:
        if not include_archived and not disposal_status and getattr(item, "is_archived", False):
            continue
        if category and item.category != category:
            continue
        if min_formality is not None and item.formality_score < min_formality:
            continue
        if max_formality is not None and item.formality_score > max_formality:
            continue
        if cut_type and item.cut_type != cut_type:
            continue
        if season and (getattr(item, "season", None) or "").upper() != season.strip().upper():
            continue
        if disposal_status and (getattr(item, "disposal_status", None) or "ACTIVE").upper() != disposal_status.strip().upper():
            continue
        if capsule:
            item_capsules = [c.strip().lower() for c in (getattr(item, "capsules", None) or []) if isinstance(c, str)]
            if capsule.strip().lower() not in item_capsules:
                continue
        item_cf = calc_color_family(item.dominant_l, item.dominant_a, item.dominant_b)
        if color_family and item_cf.lower() != color_family.strip().lower():
            continue

        usage = garment_usage(item.created_at, worn_on.get(str(item.id), []), now)
        if usage_band:
            ub = usage_band.strip().lower()
            if ub == "never_worn":
                if usage.wear_count != 0:
                    continue
            elif rotation_bucket(usage.days_idle) != ub:
                continue

        responses.append(WardrobeItemResponse.model_validate(item).model_copy(update={
            "usage_rate": usage.wear_count,
            "last_worn_at": usage.last_worn_at,
            "days_idle": usage.days_idle,
            "cost_per_use": _compute_cost_per_use(getattr(item, "purchase_price", None), usage.wear_count),
        }))
    return responses


@router.get("/capsules", response_model=List[CapsuleSummaryResponse], status_code=status.HTTP_200_OK)
async def list_wardrobe_capsules(
    current_user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Lista as cápsulas temáticas do usuário e as peças associadas a cada uma (Seção 3.2.1)."""
    items = (await db.execute(
        select(ClothingItem).where(ClothingItem.user_id == current_user_id, ClothingItem.is_archived == False)
    )).scalars().all()
    grouped: dict[str, list[UUID]] = {}
    for item in items:
        if getattr(item, "is_archived", False):
            continue
        for raw in (getattr(item, "capsules", None) or []):
            if isinstance(raw, str) and raw.strip():
                grouped.setdefault(raw.strip(), []).append(item.id)
    return [
        CapsuleSummaryResponse(name=name, items_count=len(ids), item_ids=ids)
        for name, ids in sorted(grouped.items(), key=lambda kv: (-len(kv[1]), kv[0]))
    ]


@router.post("/items", response_model=ClothingItemResponse, status_code=status.HTTP_201_CREATED)
async def create_clothing_item(
    item_in: ClothingItemCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Cadastra uma nova peça de vestuário no acervo virtual do usuário.
    Enforça a Cota Freemium (RN02 - máximo 30 peças para não-premium) e atualiza items_count.
    """
    # Validação estrita da Cota Freemium (RN02)
    if not user.is_premium and user.items_count >= settings.FREEMIUM_MAX_CLOTHING_ITEMS:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Limite da cota Freemium atingido (máximo 30 peças). Faça upgrade para o Premium."
        )

    new_item = ClothingItem(
        id=uuid.uuid4(),
        user_id=user.id,
        category=item_in.category,
        subcategory=item_in.subcategory,
        image_url=item_in.image_url,
        dominant_l=item_in.dominant_l,
        dominant_a=item_in.dominant_a,
        dominant_b=item_in.dominant_b,
        formality_score=item_in.formality_score,
        cut_type=item_in.cut_type,
        pattern=item_in.pattern,
        season=item_in.season,
        thermal_category=item_in.thermal_category,
        purchase_price=item_in.purchase_price,
        brand=item_in.brand,
        fabric_composition=item_in.fabric_composition,
        is_conscious_fashion=item_in.is_conscious_fashion,
        disposal_status=item_in.disposal_status,
        capsules=list(item_in.capsules or []),
        style_embedding=item_in.style_embedding,
        is_archived=item_in.disposal_status in ("DONATED", "DISCARDED"),
        created_at=datetime.now(timezone.utc)
    )

    user.items_count += 1

    db.add(new_item)
    await db.commit()
    await db.refresh(new_item)

    return ClothingItemResponse.model_validate(new_item)


@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_clothing_item(
    item_id: UUID,
    current_user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
    admin: SupabaseAdmin = Depends(get_supabase_admin),
):
    """
    Exclui uma peça garantindo validação de posse e isolamento Multi-Tenant estrito (RN01).
    A foto recortada sai do Storage antes do registro, para não sobrar imagem órfã (RN04).
    """
    stmt = select(ClothingItem).where(ClothingItem.id == item_id)
    result = await db.execute(stmt)
    item = result.scalars().first()

    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Peça de vestuário não encontrada."
        )

    # Validação de posse para isolamento Multi-Tenant (RN01)
    if item.user_id != current_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso negado. Esta peça não pertence ao usuário autenticado."
        )

    # Cópias da mesma peça (cadastros repetidos) dividem a foto: ela só sai com a última
    own_items = (await db.execute(
        select(ClothingItem).where(ClothingItem.user_id == current_user_id)
    )).scalars().all()
    shared = any(other.id != item.id and other.image_url == item.image_url for other in own_items)
    photo = None if shared else admin.object_path(item.image_url)
    if photo:
        try:
            await admin.delete_objects([photo])
        except SupabaseAdminError:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Não foi possível apagar a foto da peça agora. Tente novamente.",
            )

    # Decrementa o contador de peças do usuário
    user_stmt = select(User).where(User.id == current_user_id)
    user_res = await db.execute(user_stmt)
    user = user_res.scalars().first()
    if user and user.items_count > 0:
        user.items_count -= 1

    await db.delete(item)
    await db.commit()
    return None


@router.patch("/items/{item_id}", response_model=ClothingItemResponse, status_code=status.HTTP_200_OK)
async def update_clothing_item(
    item_id: UUID,
    item_update: ClothingItemUpdate,
    current_user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """
    Atualiza atributos taxonômicos da peça (RF05, Seção 3.2.3 da documentação).
    Garante validação de posse e isolamento Multi-Tenant estrito (RN01).
    """
    stmt = select(ClothingItem).where(ClothingItem.id == item_id)
    result = await db.execute(stmt)
    item = result.scalars().first()

    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Peça de vestuário não encontrada."
        )

    # Validação de posse para isolamento Multi-Tenant (RN01)
    if item.user_id != current_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso negado. Esta peça não pertence ao usuário autenticado."
        )

    changes = item_update.model_dump(exclude_unset=True, exclude_none=True)
    for field, value in changes.items():
        setattr(item, field, value)
    if changes.get("disposal_status") in ("DONATED", "DISCARDED") and "is_archived" not in changes:
        item.is_archived = True

    await db.commit()
    await db.refresh(item)
    return ClothingItemResponse.model_validate(item)


@router.get("/analytics", response_model=WardrobeAnalyticsResponse, status_code=status.HTTP_200_OK)
async def wardrobe_analytics(
    current_user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """
    Saúde do acervo (Seção 3.2.2): rotação em janelas de 30, 60 e 90 dias, proporção
    cromática dominante, valor investido, custo médio por uso e indicadores ESG.
    """
    all_items = list((await db.execute(
        select(ClothingItem).where(ClothingItem.user_id == current_user_id)
    )).scalars().all())
    donated_count = sum(1 for i in all_items if (getattr(i, "disposal_status", None) or "ACTIVE") == "DONATED")
    discarded_count = sum(1 for i in all_items if (getattr(i, "disposal_status", None) or "ACTIVE") == "DISCARDED")
    items = [i for i in all_items if not getattr(i, "is_archived", False)]
    worn_on = await _worn_on(db, current_user_id)

    now = datetime.now(timezone.utc)
    usages = [(item, garment_usage(item.created_at, worn_on.get(str(item.id), []), now)) for item in items]
    buckets = {"active": 0, "idle_30": 0, "idle_60": 0, "dormant": 0}
    for _, usage in usages:
        buckets[rotation_bucket(usage.days_idle)] += 1

    dormant = sorted(
        (pair for pair in usages if rotation_bucket(pair[1].days_idle) == "dormant"),
        key=lambda pair: (-pair[1].days_idle, pair[1].wear_count),
    )
    colors = color_distribution([(i.dominant_l, i.dominant_a, i.dominant_b) for i in items])

    priced_cpus = [
        float(item.purchase_price) / max(1, usage.wear_count)
        for item, usage in usages
        if getattr(item, "purchase_price", None) is not None and item.purchase_price > 0
    ]
    total_value = round(sum(
        float(item.purchase_price) for item in items
        if getattr(item, "purchase_price", None) is not None and item.purchase_price > 0
    ), 2)
    avg_cpu = round(sum(priced_cpus) / len(priced_cpus), 2) if priced_cpus else None
    conscious_count = sum(1 for item in items if getattr(item, "is_conscious_fashion", False))
    capsules_set = {
        c.strip() for item in items for c in (getattr(item, "capsules", None) or [])
        if isinstance(c, str) and c.strip()
    }

    return WardrobeAnalyticsResponse(
        total_pieces=len(items),
        active_count=buckets["active"],
        idle_30_count=buckets["idle_30"],
        idle_60_count=buckets["idle_60"],
        dormant_count=buckets["dormant"],
        never_worn_count=sum(1 for _, usage in usages if usage.wear_count == 0),
        total_wears=sum(usage.wear_count for _, usage in usages),
        total_wardrobe_value=total_value,
        average_cost_per_use=avg_cpu,
        conscious_items_count=conscious_count,
        donated_items=donated_count,
        discarded_items=discarded_count,
        capsules_count=len(capsules_set),
        color_distribution=[
            ColorShareResponse(
                family=c.family, count=c.count, percentage=c.percentage,
                L=c.mean_lab[0], a=c.mean_lab[1], b=c.mean_lab[2],
            )
            for c in colors
        ],
        dormant_items=[
            GarmentUsageResponse(
                item=ClothingItemResponse.model_validate(item),
                wear_count=usage.wear_count,
                last_worn_at=usage.last_worn_at,
                days_idle=usage.days_idle,
                cost_per_use=_compute_cost_per_use(getattr(item, "purchase_price", None), usage.wear_count),
            )
            for item, usage in dormant
        ],
    )
