"""
Endpoints do Perfil de Estilo do Usuário Autenticado (RF02, RF18, RN02)
O perfil salvo (biótipo e cartela) alimenta os pilares S_bio e S_cor do IHE.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.core.supabase_admin import SupabaseAdmin, SupabaseAdminError, get_supabase_admin
from app.models.entities import ClothingItem, LookFeedback, User
from app.schemas.dtos import StyleProfileResponse, StyleProfileUpdate

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
    # Fotos referenciadas pelas peças (inclui uploads antigos fora da pasta do usuário) + a pasta dele
    paths = {path for item in items if (path := admin.object_path(item.image_url))}
    try:
        paths |= set(await admin.list_user_objects(user.id))
        await admin.delete_objects(paths)
    except SupabaseAdminError:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Não foi possível apagar as suas fotos agora. Nada foi excluído; tente novamente.",
        )

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
