"""
Testes Unitários dos Modelos Relacionais/Vetoriais e Schemas DTO (Pydantic v2)
Conforme Requisitos da Etapa 2 do HarmonIA.
"""

import uuid
from datetime import datetime, timezone
import pytest
from pydantic import ValidationError

from app.models.entities import User, ClothingItem
from app.schemas.dtos import (
    UserCreate,
    UserResponse,
    UserUsageSummary,
    ClothingItemCreate,
    ClothingItemResponse,
    ClothingItemFilter,
    OutfitCalculateRequest,
    EMBEDDING_VECTOR_DIMENSION,
)
from app.engine.color_science import LabColor


def test_user_create_and_response_schema_serialization():
    """Valida a criação e serialização dos schemas de usuário."""
    user_data = UserCreate(
        email="usuario.teste@harmonia.com.br",
        password="secret_password_123",
        body_shape="AMPULHETA",
        seasonal_palette="OUTONO_QUENTE",
        style_vector=[0.1] * EMBEDDING_VECTOR_DIMENSION,
    )

    assert user_data.email == "usuario.teste@harmonia.com.br"
    assert len(user_data.style_vector) == 512

    # Simula resposta ORM
    user_id = uuid.uuid4()
    response = UserResponse(
        id=user_id,
        email=user_data.email,
        body_shape=user_data.body_shape,
        seasonal_palette=user_data.seasonal_palette,
        is_premium=False,
        looks_generated_today=2,
        items_count=15,
        created_at=datetime.now(timezone.utc),
    )

    assert response.id == user_id
    assert response.items_count == 15
    assert response.is_premium is False


def test_freemium_quota_limits_validation_rn02():
    """
    Valida as regras da Cota Freemium (RN02):
    - Usuários não-premium: máximo 30 peças e máximo 5 combinações por dia.
    - Usuários premium: ilimitado.
    """
    user_id = uuid.uuid4()

    # 1. Usuário Freemium dentro da cota
    safe_summary = UserUsageSummary(
        user_id=user_id,
        is_premium=False,
        items_count=29,
        looks_generated_today=4,
    )
    assert safe_summary.has_reached_item_limit is False
    assert safe_summary.has_reached_look_limit is False
    safe_summary.validate_item_quota()  # Não deve lançar erro
    safe_summary.validate_look_quota()  # Não deve lançar erro

    # 2. Usuário Freemium que atingiu o limite de peças (30)
    over_item_summary = UserUsageSummary(
        user_id=user_id,
        is_premium=False,
        items_count=30,
        looks_generated_today=2,
    )
    assert over_item_summary.has_reached_item_limit is True
    with pytest.raises(ValueError, match="Limite da Cota Freemium atingido"):
        over_item_summary.validate_item_quota()

    # 3. Usuário Freemium que atingiu o limite de combinações diárias (5)
    over_look_summary = UserUsageSummary(
        user_id=user_id,
        is_premium=False,
        items_count=10,
        looks_generated_today=5,
    )
    assert over_look_summary.has_reached_look_limit is True
    with pytest.raises(ValueError, match="Limite diário de combinações por IA atingido"):
        over_look_summary.validate_look_quota()

    # 4. Usuário Premium ultrapassando a cota sem erro
    premium_summary = UserUsageSummary(
        user_id=user_id,
        is_premium=True,
        items_count=150,
        looks_generated_today=50,
    )
    assert premium_summary.has_reached_item_limit is False
    assert premium_summary.has_reached_look_limit is False
    premium_summary.validate_item_quota()
    premium_summary.validate_look_quota()


def test_vector_dimension_512_validation():
    """Valida que o embedding vetorial exige exatamente 512 dimensões."""
    valid_vector = [0.05] * 512
    invalid_vector = [0.05] * 128

    # Sucesso com 512d
    item_create = ClothingItemCreate(
        category="top",
        image_url="https://s3.amazonaws.com/harmonia/item1.png",
        dominant_l=45.0,
        dominant_a=38.0,
        dominant_b=42.0,
        formality_score=0.7,
        style_embedding=valid_vector,
    )
    assert len(item_create.style_embedding) == 512

    # Falha com 128d
    with pytest.raises(ValidationError):
        ClothingItemCreate(
            category="top",
            image_url="https://s3.amazonaws.com/harmonia/item1.png",
            dominant_l=45.0,
            dominant_a=38.0,
            dominant_b=42.0,
            formality_score=0.7,
            style_embedding=invalid_vector,
        )


def test_outfit_calculate_request_schema():
    """Valida o schema de solicitação de cálculo do IHE integrado."""
    req = OutfitCalculateRequest(
        direct_garment_color=LabColor(L=50.0, a=20.0, b=30.0),
        user_palette="OUTONO_QUENTE",
        user_biotype="AMPULHETA",
        garment_cuts=["ACINTURADO"],
        garment_formality=0.8,
        occasion="CORPORATIVO",
        temperature_celsius=18.5,
        user_style_vector=[0.1] * 512,
        look_style_vector=[0.1] * 512,
    )

    assert req.user_palette == "OUTONO_QUENTE"
    assert len(req.user_style_vector) == 512
    assert len(req.look_style_vector) == 512


def test_orm_entities_instantiation():
    """Valida a instanciação das entidades SQLAlchemy 2.0 User e ClothingItem."""
    user_id = uuid.uuid4()
    item_id = uuid.uuid4()

    user = User(
        id=user_id,
        email="teste.orm@harmonia.com.br",
        hashed_password="hashed_secret",
        body_shape="RETANGULO",
        seasonal_palette="INVERNO_FRIO",
        is_premium=True,
    )

    item = ClothingItem(
        id=item_id,
        user_id=user_id,
        category="top",
        subcategory="blazer",
        image_url="https://s3.amazonaws.com/harmonia/blazer.png",
        dominant_l=40.0,
        dominant_a=20.0,
        dominant_b=-30.0,
        formality_score=0.9,
        cut_type="estruturado ombro",
    )

    assert user.id == user_id
    assert user.email == "teste.orm@harmonia.com.br"
    assert item.user_id == user_id
    assert item.formality_score == 0.9
