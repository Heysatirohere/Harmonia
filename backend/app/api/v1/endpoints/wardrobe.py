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
    ClothingItemCreate,
    ClothingItemResponse,
    ClothingItemUpdate,
    ColorShareResponse,
    ExtractedColorResponse,
    GarmentUsageResponse,
    SegmentationResponse,
    WardrobeAnalyticsResponse,
)
from app import vision
from app.engine.wardrobe_analytics import color_distribution, garment_usage, rotation_bucket

ACCEPTED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp"}

router = APIRouter()


@router.post("/segment", response_model=SegmentationResponse, status_code=status.HTTP_200_OK)
async def segment_garment_photo(
    file: UploadFile = File(..., description="Foto da peça (JPEG, PNG ou WebP)"),
    current_user_id: UUID = Depends(get_current_user_id),
):
    """
    Remove o fundo da foto (RF04) e extrai as cores dominantes em CIE L*a*b* (RF05).
    Não persiste nada: o app confirma os atributos e envia o PNG ao Storage no cadastro.
    """
    if file.content_type not in ACCEPTED_IMAGE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Formato de imagem não suportado. Envie JPEG, PNG ou WebP."
        )

    data = await file.read(settings.MAX_UPLOAD_BYTES + 1)
    if len(data) > settings.MAX_UPLOAD_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Foto muito grande. O limite é de 10 MB."
        )

    try:
        result = await run_in_threadpool(vision.segment_garment, data)
    except vision.InvalidImageError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))

    if not result.colors:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Nenhuma peça foi identificada na foto. Tente fotografar sobre um fundo liso."
        )

    return SegmentationResponse(
        image_png_base64=base64.b64encode(result.png_bytes).decode("ascii"),
        width=result.width,
        height=result.height,
        colors=[ExtractedColorResponse(**vars(c)) for c in result.colors],
        style_embedding=result.style_embedding,
        processing_ms=result.processing_ms,
    )


@router.get("/items", response_model=List[ClothingItemResponse], status_code=status.HTTP_200_OK)
async def list_clothing_items(
    current_user_id: UUID = Depends(get_current_user_id),
    category: Optional[str] = Query(None, description="Filtrar por categoria"),
    min_formality: Optional[float] = Query(None, ge=0.0, le=1.0, description="Formalidade mínima"),
    max_formality: Optional[float] = Query(None, ge=0.0, le=1.0, description="Formalidade máxima"),
    cut_type: Optional[str] = Query(None, description="Filtrar por corte/modelagem"),
    include_archived: bool = Query(False, description="Incluir peças arquivadas"),
    sort_by: str = Query("created_at", description="Campo para ordenação"),
    order: str = Query("desc", description="Direção da ordenação (asc ou desc)"),
    db: AsyncSession = Depends(get_db),
):
    """
    Lista peças do guarda-roupa do usuário logado (RN01) com suporte a filtros multicritérios (RF06).
    """
    stmt = select(ClothingItem).where(ClothingItem.user_id == current_user_id)

    if not include_archived:
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
    items = result.scalars().all()

    return [ClothingItemResponse.model_validate(item) for item in items]


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
        style_embedding=item_in.style_embedding,
        is_archived=False,
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

    photo = admin.object_path(item.image_url)
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

    await db.commit()
    await db.refresh(item)
    return ClothingItemResponse.model_validate(item)


@router.get("/analytics", response_model=WardrobeAnalyticsResponse, status_code=status.HTTP_200_OK)
async def wardrobe_analytics(
    current_user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """
    Saúde do acervo (Seção 3.2.2): rotação em janelas de 30, 60 e 90 dias e proporção
    cromática dominante. O uso de cada peça vem dos looks aprovados (RF13), então desfazer
    uma aprovação também desfaz o uso. Só peças e looks do próprio usuário (RN01).
    """
    items = (await db.execute(
        select(ClothingItem).where(ClothingItem.user_id == current_user_id, ClothingItem.is_archived == False)
    )).scalars().all()
    approved = (await db.execute(
        select(LookFeedback).where(LookFeedback.user_id == current_user_id, LookFeedback.action == "APPROVED")
    )).scalars().all()

    worn_on: dict[str, list[datetime]] = {}
    for look in approved:
        for item_id in look.item_ids:
            worn_on.setdefault(str(item_id), []).append(look.created_at)

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

    return WardrobeAnalyticsResponse(
        total_pieces=len(items),
        active_count=buckets["active"],
        idle_30_count=buckets["idle_30"],
        idle_60_count=buckets["idle_60"],
        dormant_count=buckets["dormant"],
        never_worn_count=sum(1 for _, usage in usages if usage.wear_count == 0),
        total_wears=sum(usage.wear_count for _, usage in usages),
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
            )
            for item, usage in dormant
        ],
    )
