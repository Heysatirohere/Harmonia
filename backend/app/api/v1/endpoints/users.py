"""
Endpoints do Perfil de Estilo do Usuário Autenticado (RF02, RF18, RN02)
O perfil salvo (biótipo e cartela) alimenta os pilares S_bio e S_cor do IHE.
"""

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.entities import User
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
