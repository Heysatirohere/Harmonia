"""
Contratos de Dados e Data Transfer Objects (DTOs) com Pydantic v2
Conforme Seção 4 (Regras de Negócio e Requisitos) da Documentação do HarmonIA.
"""

from uuid import UUID
from datetime import datetime
from typing import List, Optional, Literal
from pydantic import BaseModel, Field, EmailStr, field_validator, model_validator, ConfigDict

from app.engine.color_science import LabColor
from app.core.config import settings


# Dimensionamento Fixo do Vetor de Estilo (pgvector 512d)
EMBEDDING_VECTOR_DIMENSION = 512


def validate_vector_512(v: Optional[List[float]]) -> Optional[List[float]]:
    """Valida se o vetor de estilo possui exatamente 512 dimensões floats."""
    if v is not None:
        if len(v) != EMBEDDING_VECTOR_DIMENSION:
            raise ValueError(
                f"O vetor vetorial de estilo deve ter exatamente {EMBEDDING_VECTOR_DIMENSION} dimensões. "
                f"Tamanho recebido: {len(v)}"
            )
    return v


# -----------------------------------------------------------------------------
# Schemas de Usuário (User)
# -----------------------------------------------------------------------------

class UserCreate(BaseModel):
    """Schema para criação/registro de usuário."""
    email: str = Field(..., description="E-mail único do usuário")
    password: str = Field(..., min_length=6, description="Senha plana (mínimo 6 caracteres)")
    body_shape: Optional[str] = Field(default=None, description="Biótipo corporal (ex: AMPULHETA, RETANGULO)")
    seasonal_palette: Optional[str] = Field(default=None, description="Cartela de cor sazonal (ex: OUTONO_QUENTE)")
    style_vector: Optional[List[float]] = Field(default=None, description="Vetor latente de estilo (512d)")

    @field_validator("style_vector")
    @classmethod
    def check_vector_dim(cls, v: Optional[List[float]]) -> Optional[List[float]]:
        return validate_vector_512(v)


class UserResponse(BaseModel):
    """Schema de resposta pública do usuário."""
    id: UUID
    email: str
    body_shape: Optional[str] = None
    seasonal_palette: Optional[str] = None
    is_premium: bool = False
    looks_generated_today: int = 0
    items_count: int = 0
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class UserUsageSummary(BaseModel):
    """
    Resumo de Uso e Controle da Cota Freemium (RN02).
    Limites padrão: 30 peças no acervo e 5 combinações diárias por IA.
    """
    user_id: UUID
    is_premium: bool
    items_count: int = Field(..., ge=0)
    looks_generated_today: int = Field(..., ge=0)
    max_items_allowed: int = Field(default=settings.FREEMIUM_MAX_CLOTHING_ITEMS)
    max_daily_looks_allowed: int = Field(default=settings.FREEMIUM_MAX_DAILY_LOOKS)

    @property
    def has_reached_item_limit(self) -> bool:
        """Verifica se o usuário atingiu o teto de cadastro de peças."""
        if self.is_premium:
            return False
        return self.items_count >= self.max_items_allowed

    @property
    def has_reached_look_limit(self) -> bool:
        """Verifica se o usuário atingiu o teto diário de geração de looks."""
        if self.is_premium:
            return False
        return self.looks_generated_today >= self.max_daily_looks_allowed

    def validate_item_quota(self) -> None:
        """Dispara erro de validação caso a cota de peças tenha sido excedida."""
        if self.has_reached_item_limit:
            raise ValueError(
                f"Limite da Cota Freemium atingido ({self.items_count}/{self.max_items_allowed} peças). "
                "Faça upgrade para o plano Premium para cadastrar peças ilimitadas."
            )

    def validate_look_quota(self) -> None:
        """Dispara erro de validação caso a cota diária de combinações tenha sido excedida."""
        if self.has_reached_look_limit:
            raise ValueError(
                f"Limite diário de combinações por IA atingido ({self.looks_generated_today}/{self.max_daily_looks_allowed} hoje). "
                "Faça upgrade para o plano Premium para gerar combinações ilimitadas."
            )


# -----------------------------------------------------------------------------
# Schemas de Vestuário (ClothingItem)
# -----------------------------------------------------------------------------

class ClothingItemCreate(BaseModel):
    """Schema para cadastro de peça de vestuário."""
    category: str = Field(..., description="Categoria principal (top, bottom, shoes, one_piece, outerwear)")
    subcategory: Optional[str] = Field(default=None, description="Subcategoria descritiva")
    image_url: str = Field(..., description="URL da imagem PNG segmentada com canal alfa no S3")
    dominant_l: float = Field(..., ge=0.0, le=100.0, description="Luminosidade CIE L*")
    dominant_a: float = Field(..., ge=-128.0, le=127.0, description="Coordenada a* CIE L*a*b*")
    dominant_b: float = Field(..., ge=-128.0, le=127.0, description="Coordenada b* CIE L*a*b*")
    formality_score: float = Field(..., ge=0.0, le=1.0, description="Grau de formalidade (0.0 a 1.0)")
    cut_type: Optional[str] = Field(default=None, description="Corte/modelagem (ex: acinturado, pantalona)")
    style_embedding: Optional[List[float]] = Field(default=None, description="Embedding de estilo (512d)")

    @field_validator("style_embedding")
    @classmethod
    def check_embedding_dim(cls, v: Optional[List[float]]) -> Optional[List[float]]:
        return validate_vector_512(v)


class ClothingItemResponse(BaseModel):
    """Schema de resposta detalhada da peça."""
    id: UUID
    user_id: UUID
    category: str
    subcategory: Optional[str] = None
    image_url: str
    dominant_l: float
    dominant_a: float
    dominant_b: float
    formality_score: float
    cut_type: Optional[str] = None
    is_archived: bool = False
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ClothingItemFilter(BaseModel):
    """Filtros multicritérios para busca de peças no guarda-roupa virtual."""
    category: Optional[str] = None
    min_formality: Optional[float] = Field(default=None, ge=0.0, le=1.0)
    max_formality: Optional[float] = Field(default=None, ge=0.0, le=1.0)
    include_archived: bool = False
    sort_by: Literal["created_at", "formality_score", "category"] = "created_at"
    order: Literal["asc", "desc"] = "desc"


# -----------------------------------------------------------------------------
# Schema de Cálculo do IHE Integrado
# -----------------------------------------------------------------------------

class OutfitCalculateRequest(BaseModel):
    """Schema para solicitação de cálculo do Índice de Harmonia Estética (IHE)."""
    item_ids: Optional[List[UUID]] = Field(default=None, description="Lista de IDs de peças cadastradas")
    direct_garment_color: Optional[LabColor] = Field(default=None, description="Cor direta caso seja peça de loja")
    user_palette: str = Field(..., description="Cartela sazonal do usuário")
    user_biotype: str = Field(..., description="Biótipo corporal")
    garment_cuts: List[str] = Field(default_factory=list, description="Lista de cortes do look")
    garment_formality: float = Field(..., ge=0.0, le=1.0, description="Formalidade média do look (0.0 a 1.0)")
    occasion: str = Field(..., description="Ocasião de destino")
    temperature_celsius: float = Field(..., description="Temperatura ambiente em °C")
    is_raining: bool = Field(default=False, description="Flag de chuva")
    garment_thermal_category: str = Field(default="MEDIO", description="Categoria térmica")
    user_style_vector: List[float] = Field(..., description="Vetor latente de estilo do usuário (512d)")
    look_style_vector: List[float] = Field(..., description="Vetor latente do look (512d)")

    @field_validator("user_style_vector", "look_style_vector")
    @classmethod
    def check_vectors_512(cls, v: List[float]) -> List[float]:
        if len(v) != EMBEDDING_VECTOR_DIMENSION:
            raise ValueError(
                f"O vetor de estilo deve ter exatamente {EMBEDDING_VECTOR_DIMENSION} dimensões. Tamanho recebido: {len(v)}"
            )
        return v
