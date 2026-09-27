"""
Endpoint de Autenticação Mock e Geração de Sessão de Desenvolvimento
"""

from typing import Optional
from datetime import datetime, timezone
import uuid
from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.models.entities import User
from app.schemas.dtos import UserResponse

router = APIRouter()


class MockSessionRequest(BaseModel):
    """Schema para requisição da sessão mock de desenvolvimento."""
    email: Optional[str] = Field(default="dev.mock@harmonia.app", description="E-mail do usuário mock")
    body_shape: Optional[str] = Field(default="AMPULHETA", description="Biótipo corporal inicial")
    seasonal_palette: Optional[str] = Field(default="OUTONO_QUENTE", description="Cartela de cores inicial")
    is_premium: Optional[bool] = Field(default=False, description="Flag de usuário premium")


class MockSessionResponse(BaseModel):
    """Schema para resposta de criação da sessão mock."""
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


@router.post("/mock-session", response_model=MockSessionResponse, status_code=status.HTTP_200_OK)
async def create_mock_session(
    payload: Optional[MockSessionRequest] = None,
    db: AsyncSession = Depends(get_db)
):
    """
    Gera ou recupera uma sessão/usuário mock de desenvolvimento com biótipo e cartela sazonal.
    Permite testes ponta a ponta sem necessidade de credenciais da AWS.
    """
    req = payload or MockSessionRequest()
    email = req.email or "dev.mock@harmonia.app"

    stmt = select(User).where(User.email == email)
    result = await db.execute(stmt)
    user = result.scalars().first()

    if not user:
        user = User(
            id=uuid.uuid4(),
            email=email,
            hashed_password="mock_hashed_password_123",
            body_shape=req.body_shape,
            seasonal_palette=req.seasonal_palette,
            style_vector=[0.0] * 512,
            is_premium=bool(req.is_premium),
            looks_generated_today=0,
            items_count=0,
            created_at=datetime.now(timezone.utc)
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    return MockSessionResponse(
        access_token=f"mock_token_{user.id}",
        token_type="bearer",
        user=UserResponse.model_validate(user)
    )
