"""
Entidades ORM do SQLAlchemy 2.0 com Suporte a Vetores (pgvector)
Conforme Requisitos de Arquitetura e Persistência do HarmonIA.
"""

import uuid
from datetime import date, datetime, timezone
from typing import List, Optional

from sqlalchemy import String, Integer, Float, Boolean, Date, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from pgvector.sqlalchemy import Vector

from app.core.database import Base


class User(Base):
    """
    Entidade de Usuário no Banco de Dados.
    Armazena o perfil estético, biótipo, cartela de cor e o vetor latente de estilo (512d).
    """
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )
    email: Mapped[str] = mapped_column(
        String(255),
        unique=True,
        nullable=False,
        index=True
    )
    hashed_password: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )
    body_shape: Mapped[Optional[str]] = mapped_column(
        String(50),
        nullable=True
    )
    seasonal_palette: Mapped[Optional[str]] = mapped_column(
        String(50),
        nullable=True
    )
    style_vector: Mapped[Optional[List[float]]] = mapped_column(
        Vector(512),
        nullable=True
    )
    is_premium: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False
    )
    is_public: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )
    looks_generated_today: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False
    )
    # Dia (fuso da cota) a que o contador se refere; em outro dia ele vale zero (RN02)
    looks_counter_date: Mapped[Optional[date]] = mapped_column(
        Date,
        nullable=True
    )
    # Assinaturas das consultas já cobradas hoje: repetir a mesma consulta não gasta cota
    looks_signatures_today: Mapped[List[str]] = mapped_column(
        JSONB,
        default=list,
        nullable=False
    )
    items_count: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    # Relacionamento 1:N com as peças do guarda-roupa
    clothing_items: Mapped[List["ClothingItem"]] = relationship(
        "ClothingItem",
        back_populates="user",
        cascade="all, delete-orphan"
    )


class ClothingItem(Base):
    """
    Entidade de Peça de Vestuário do Acervo Virtual.
    Armazena as coordenadas cromáticas CIE L*a*b*, formalidade, corte e embedding de estilo (512d).
    Garante o isolamento Multi-Tenant estrito via indexação de user_id (RN01).
    """
    __tablename__ = "clothing_items"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True  # Indexação para isolamento estrito de consultas Multi-Tenant (RN01)
    )
    category: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True
    )
    subcategory: Mapped[Optional[str]] = mapped_column(
        String(100),
        nullable=True
    )
    image_url: Mapped[str] = mapped_column(
        String(500),
        nullable=False
    )
    dominant_l: Mapped[float] = mapped_column(
        Float,
        nullable=False
    )
    dominant_a: Mapped[float] = mapped_column(
        Float,
        nullable=False
    )
    dominant_b: Mapped[float] = mapped_column(
        Float,
        nullable=False
    )
    formality_score: Mapped[float] = mapped_column(
        Float,
        nullable=False
    )
    cut_type: Mapped[Optional[str]] = mapped_column(
        String(100),
        nullable=True
    )
    style_embedding: Mapped[Optional[List[float]]] = mapped_column(
        Vector(512),
        nullable=True
    )
    is_archived: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    # Relacionamento de volta com o Usuário
    user: Mapped["User"] = relationship(
        "User",
        back_populates="clothing_items"
    )


class LookFeedback(Base):
    """
    Retorno do usuário sobre um look sugerido (RF13).
    Aprovações registram o uso do look no dia; descartes tiram a combinação das próximas sugestões.
    """
    __tablename__ = "look_feedback"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True  # Isolamento Multi-Tenant (RN01)
    )
    # IDs das peças do look (texto), na ordem em que foi sugerido
    item_ids: Mapped[List[str]] = mapped_column(
        JSONB,
        nullable=False
    )
    action: Mapped[str] = mapped_column(
        String(20),
        nullable=False
    )
    occasion: Mapped[str] = mapped_column(
        String(50),
        nullable=False
    )
    ihe_percentage: Mapped[float] = mapped_column(
        Float,
        nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )
