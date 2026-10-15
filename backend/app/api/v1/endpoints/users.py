"""
Endpoints do Perfil de Estilo do Usuário Autenticado (RF02, RF18, RN02)
O perfil salvo (biótipo e cartela) alimenta os pilares S_bio e S_cor do IHE.
"""

from uuid import UUID

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.concurrency import run_in_threadpool
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.config import settings
from app.core.security import get_current_user, get_current_user_id
from app.core.supabase_admin import SupabaseAdmin, SupabaseAdminError, get_supabase_admin
from app.models.entities import ClothingItem, CommunityPost, LookFeedback, PostReaction, SavedPost, User
from app.schemas.dtos import ColorimetryResponse, StyleProfileResponse, StyleProfileUpdate
from app.vision import colorimetry, segmentation

ACCEPTED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp"}

router = APIRouter()


@router.get("/me", response_model=StyleProfileResponse, status_code=status.HTTP_200_OK)
async def read_own_profile(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Retorna o perfil de estilo e o uso da cota do usuário autenticado."""
    # get_current_user pode ter provisionado o perfil agora; persiste antes de responder
    await db.commit()
    return StyleProfileResponse.model_validate(user)


@router.patch("/me", response_model=StyleProfileResponse, status_code=status.HTTP_200_OK)
async def update_own_profile(
    payload: StyleProfileUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Atualiza biótipo e/ou cartela sazonal (onboarding e recalibração).
    Campos omitidos permanecem inalterados.
    """
    changes = payload.model_dump(exclude_unset=True, exclude_none=True)
    for field, value in changes.items():
        setattr(user, field, value)

    await db.commit()
    return StyleProfileResponse.model_validate(user)


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_own_account(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    admin: SupabaseAdmin = Depends(get_supabase_admin),
):
    """
    Direito ao esquecimento (RN04, RNF01): apaga as fotos do Storage, os registros do banco
    e o login do Supabase Auth, nesta ordem. Se o Storage falhar, nada é apagado; se o Auth
    falhar, o banco volta atrás e uma nova tentativa conclui a exclusão.
    """
    items = (await db.execute(select(ClothingItem).where(ClothingItem.user_id == user.id))).scalars().all()
    posts = (await db.execute(select(CommunityPost).where(CommunityPost.user_id == user.id))).scalars().all()
    # Fotos das peças e dos posts (inclui uploads antigos fora da pasta do usuário) + a pasta dele
    urls = [item.image_url for item in items] + [post.image_url for post in posts]
    paths = {path for url in urls if (path := admin.object_path(url))}
    try:
        paths |= set(await admin.list_user_objects(user.id))
        await admin.delete_objects(paths)
    except SupabaseAdminError:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Não foi possível apagar as suas fotos agora. Nada foi excluído; tente novamente.",
        )

    # Curtidas e salvos que outras pessoas deram nos posts dele caem em cascata com os posts
    await db.execute(delete(PostReaction).where(PostReaction.user_id == user.id))
    await db.execute(delete(SavedPost).where(SavedPost.user_id == user.id))
    await db.execute(delete(CommunityPost).where(CommunityPost.user_id == user.id))
    await db.execute(delete(LookFeedback).where(LookFeedback.user_id == user.id))
    await db.execute(delete(ClothingItem).where(ClothingItem.user_id == user.id))
    await db.execute(delete(User).where(User.id == user.id))
    await db.flush()

    try:
        await admin.delete_auth_user(user.id)
    except SupabaseAdminError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Suas fotos foram apagadas, mas não foi possível concluir a exclusão. Tente novamente para terminar.",
        )
    await db.commit()


@router.post("/me/colorimetry", response_model=ColorimetryResponse, status_code=status.HTTP_200_OK)
async def analyze_colorimetry(
    file: UploadFile = File(..., description="Selfie com o rosto no oval, sob luz natural"),
    current_user_id: UUID = Depends(get_current_user_id),
):
    """
    Teste assistido de colorimetria (RF02): subtom, profundidade, saturação e contraste da pele
    e a cartela sugerida entre as 12 sazonais. A selfie é lida em memória e descartada (LGPD):
    nada é gravado, e a cartela só muda quando a pessoa a confirma no PATCH /users/me.
    """
    if file.content_type not in ACCEPTED_IMAGE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Formato de imagem não suportado. Envie JPEG, PNG ou WebP.",
        )
    data = await file.read(settings.MAX_UPLOAD_BYTES + 1)
    if len(data) > settings.MAX_UPLOAD_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_CONTENT_TOO_LARGE,
            detail="Foto muito grande. O limite é de 10 MB.",
        )

    def analyze():
        return colorimetry.analyze_selfie(segmentation.load_image(data))

    try:
        result = await run_in_threadpool(analyze)
    except segmentation.InvalidImageError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail=str(exc))
    except colorimetry.FaceNotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail=str(exc))

    return ColorimetryResponse(
        palette=result.palette,
        skin_hex=result.hex,
        L=result.L,
        a=result.a,
        b=result.b,
        hue=result.hue,
        chroma=result.chroma,
        contrast=result.contrast,
        undertone=result.undertone,
        depth=result.depth,
        intensity=result.intensity,
    )
