"""
Contratos de Dados e Data Transfer Objects (DTOs) com Pydantic v2
Conforme Seção 4 (Regras de Negócio e Requisitos) da Documentação do HarmonIA.
"""

from uuid import UUID
from datetime import datetime
from typing import List, Optional, Literal
from pydantic import BaseModel, Field, EmailStr, field_validator, model_validator, ConfigDict, computed_field

from app.engine.color_science import LabColor, normalize_palette
from app.engine.morphology import normalize_biotype
from app.engine.context_rules import normalize_occasion
from app.engine.wardrobe_analytics import color_family
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


class StyleProfileUpdate(BaseModel):
    """
    Atualização parcial do perfil morfocromático (RF02, RF18, RN05).
    Os valores são normalizados para as chaves do motor do IHE (ex: 'Triângulo Invertido' -> 'TRIANGULO_INVERTIDO').
    """
    body_shape: Optional[str] = Field(default=None, description="Biótipo corporal (ex: AMPULHETA)")
    seasonal_palette: Optional[str] = Field(default=None, description="Cartela sazonal (ex: OUTONO_QUENTE)")
    is_public: Optional[bool] = Field(default=None, description="Visibilidade do perfil e publicações no feed (RN05)")

    @field_validator("body_shape")
    @classmethod
    def check_body_shape(cls, v: Optional[str]) -> Optional[str]:
        return normalize_biotype(v) if v is not None else None

    @field_validator("seasonal_palette")
    @classmethod
    def check_palette(cls, v: Optional[str]) -> Optional[str]:
        return normalize_palette(v) if v is not None else None


class StyleProfileResponse(BaseModel):
    """Perfil de estilo do usuário autenticado com o uso da cota Freemium (RF02, RF18, RN02, RN05)."""
    id: UUID
    email: str
    body_shape: Optional[str] = None
    seasonal_palette: Optional[str] = None
    is_premium: bool = False
    is_public: bool = True
    items_count: int = 0
    looks_generated_today: int = 0
    max_items_allowed: int = settings.FREEMIUM_MAX_CLOTHING_ITEMS
    max_daily_looks_allowed: int = settings.FREEMIUM_MAX_DAILY_LOOKS

    model_config = ConfigDict(from_attributes=True)

    @field_validator("is_public", mode="before")
    @classmethod
    def default_is_public(cls, v: Optional[bool]) -> bool:
        return True if v is None else bool(v)

    @computed_field
    @property
    def onboarding_completed(self) -> bool:
        """O onboarding está completo quando biótipo e cartela foram definidos."""
        return self.body_shape is not None and self.seasonal_palette is not None


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


class ExtractedColorResponse(BaseModel):
    """Centróide cromático extraído da peça recortada (RF05)."""
    L: float = Field(..., description="Luminosidade CIE L*")
    a: float = Field(..., description="Coordenada a* CIE L*a*b*")
    b: float = Field(..., description="Coordenada b* CIE L*a*b*")
    hex: str = Field(..., description="Aproximação sRGB em hexadecimal (#RRGGBB)")
    percentage: int = Field(..., ge=0, le=100, description="Área relativa ocupada na peça (%)")
    name: str = Field(..., description="Nome curatorial aproximado do tom")


class SegmentationResponse(BaseModel):
    """Resultado do pipeline de recorte de fundo e extração cromática (RF04, RF05)."""
    image_png_base64: str = Field(..., description="Peça recortada em PNG com canal alfa (base64)")
    width: int
    height: int
    colors: List[ExtractedColorResponse] = Field(..., description="Cores dominantes, da maior para a menor área")
    style_embedding: Optional[List[float]] = Field(
        default=None, description="Vetor de estilo da peça (512d, norma 1); nulo se o modelo estiver indisponível"
    )
    processing_ms: int = Field(..., description="Tempo de processamento no servidor (RNF03: ≤ 3500 ms)")


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

    @computed_field
    @property
    def color_family(self) -> str:
        """Família cromática da cor dominante, a mesma do dashboard (filtro por cor, RF06)."""
        return color_family(self.dominant_l, self.dominant_a, self.dominant_b)


class WardrobeItemResponse(ClothingItemResponse):
    """Peça na listagem do acervo, com o uso vindo dos looks aprovados (filtro por frequência, RF06)."""
    usage_rate: int = Field(default=0, description="Looks aprovados com a peça")
    last_worn_at: Optional[datetime] = None
    days_idle: int = Field(default=0, description="Dias desde o último uso, ou desde o cadastro se nunca usada")


class GarmentUsageResponse(BaseModel):
    """Peça com o uso registrado pelas aprovações de looks (RF13, Seção 3.2.2)."""
    item: ClothingItemResponse
    wear_count: int = Field(..., ge=0, description="Looks aprovados com esta peça")
    last_worn_at: Optional[datetime] = Field(default=None, description="Data da aprovação mais recente; nula se nunca usada")
    days_idle: int = Field(..., ge=0, description="Dias desde o último uso (ou desde o cadastro, se nunca usada)")


class ColorShareResponse(BaseModel):
    """Família cromática do acervo e a sua cor média em CIE L*a*b*."""
    family: str
    count: int
    percentage: float = Field(..., ge=0.0, le=100.0)
    L: float
    a: float
    b: float


class WardrobeAnalyticsResponse(BaseModel):
    """Saúde do acervo: rotação em janelas de 30/60/90 dias e proporção cromática (Seção 3.2.2)."""
    total_pieces: int
    active_count: int = Field(..., description="Usadas (ou cadastradas) há menos de 30 dias")
    idle_30_count: int = Field(..., description="Sem uso de 30 a 60 dias")
    idle_60_count: int = Field(..., description="Sem uso de 60 a 90 dias")
    dormant_count: int = Field(..., description="Sem uso há 90 dias ou mais")
    never_worn_count: int
    total_wears: int
    color_distribution: List[ColorShareResponse]
    dormant_items: List[GarmentUsageResponse] = Field(..., description="Peças adormecidas, da mais esquecida para a menos")


class ClothingItemUpdate(BaseModel):
    """Schema para atualização parcial de atributos da peça de vestuário (RF05, Seção 3.2.3)."""
    category: Optional[str] = Field(default=None, description="Categoria principal (top, bottom, shoes, one_piece, outerwear)")
    subcategory: Optional[str] = Field(default=None, description="Subcategoria descritiva ou nome")
    formality_score: Optional[float] = Field(default=None, ge=0.0, le=1.0, description="Grau de formalidade (0.0 a 1.0)")
    cut_type: Optional[str] = Field(default=None, description="Corte/modelagem")


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


class OutfitGenerateRequest(BaseModel):
    """Schema para solicitação de geração combinatória de looks do acervo (RF07)."""
    occasion: str = Field(default="CASUAL", description="Ocasião de destino (CASUAL, CORPORATIVO, GALA, etc.)")
    temperature_celsius: float = Field(default=22.0, description="Temperatura local em °C")
    is_raining: bool = Field(default=False, description="Flag de chuva")
    limit: int = Field(default=5, ge=1, le=20, description="Limite máximo de looks recomendados")

    @field_validator("occasion")
    @classmethod
    def check_occasion(cls, v: str) -> str:
        return normalize_occasion(v)


class RecommendedOutfitResponse(BaseModel):
    """Schema para resposta de look recomendado com decomposição do IHE."""
    items: List[ClothingItemResponse]
    ihe_score: float
    ihe_percentage: float
    s_cor: float
    s_bio: float
    s_ocasion: float
    s_cos: float
    is_strongly_recommended: bool
    styling_advice: str
    occasion: str



# -----------------------------------------------------------------------------
# Paridade de Provador (RF08, RF09)
# -----------------------------------------------------------------------------

class StoreParityRequest(BaseModel):
    """Peça fotografada na loja: categoria escolhida pelo usuário e cor extraída do recorte."""
    category: str = Field(..., min_length=1, description="Categoria da peça (ex: Partes de cima)")
    dominant_l: float = Field(..., ge=0.0, le=100.0)
    dominant_a: float = Field(..., ge=-128.0, le=127.0)
    dominant_b: float = Field(..., ge=-128.0, le=127.0)
    formality_score: float = Field(default=0.5, ge=0.0, le=1.0)
    occasion: str = Field(default="CASUAL")
    temperature_celsius: float = Field(default=22.0)
    is_raining: bool = Field(default=False)
    limit: int = Field(default=5, ge=1, le=10, description="Máximo de peças do acervo no ranking")
    style_embedding: Optional[List[float]] = Field(
        default=None, description="Vetor de estilo da peça da loja (512d), vindo do /wardrobe/segment"
    )

    @field_validator("occasion")
    @classmethod
    def check_occasion(cls, v: str) -> str:
        return normalize_occasion(v)

    @field_validator("style_embedding")
    @classmethod
    def check_embedding_dim(cls, v: Optional[List[float]]) -> Optional[List[float]]:
        return validate_vector_512(v)


class ParityMatchResponse(BaseModel):
    """Peça do acervo e o IHE do melhor look que ela forma com a peça da loja."""
    item: ClothingItemResponse
    ihe_percentage: float
    s_cor: float
    s_bio: float
    is_strongly_recommended: bool
    rationale: str


class StoreParityResponse(BaseModel):
    """Resultado da paridade: melhor look possível e ranking das peças de casa (RF09)."""
    ihe_percentage: float = Field(..., description="IHE do melhor look com a peça da loja (0 sem looks)")
    is_strongly_recommended: bool
    palette_harmony: Optional[float] = Field(
        default=None, description="S_cor da cor da peça contra a cartela do usuário (sem cartela: nulo)"
    )
    styling_advice: Optional[str] = None
    looks_evaluated: int
    strong_looks: int = Field(..., description="Looks com IHE >= 75% que a peça destravaria")
    matches: List[ParityMatchResponse]


# -----------------------------------------------------------------------------
# Lacunas do Acervo e Afiliação (RF11, RF12, RN03)
# -----------------------------------------------------------------------------

class PartnerProductResponse(BaseModel):
    """Produto de parceiro com estoque; o link leva à busca na loja com UTM (RF12)."""
    id: str
    store: Literal["CEA", "RENNER"]
    store_name: str
    name: str
    color_hex: str
    url: str


class WardrobeGapResponse(BaseModel):
    id: str
    title: str
    category: str = Field(..., description="Família da peça (top, bottom, shoes, one_piece)")
    rationale: str
    color_hex: str
    looks_evaluated: int = Field(..., description="Looks que a peça forma com o acervo")
    strong_looks: int = Field(..., description="Desses, quantos chegam a IHE >= 75%")
    best_ihe_percentage: float
    delta_ihe: float = Field(..., description="Pontos percentuais sobre o melhor look possível hoje")
    products: List[PartnerProductResponse] = Field(..., description="Só produtos com estoque (RN03)")


class WardrobeGapsResponse(BaseModel):
    occasion: str
    baseline_ihe_percentage: Optional[float] = Field(
        default=None, description="IHE do melhor look com o acervo atual (sem looks: nulo)"
    )
    gaps: List[WardrobeGapResponse]


# -----------------------------------------------------------------------------
# Feedback de Recomendações (RF13)
# -----------------------------------------------------------------------------

class LookFeedbackCreate(BaseModel):
    """Aprovação ou descarte de um look sugerido."""
    item_ids: List[UUID] = Field(..., min_length=1, max_length=6, description="Peças do look sugerido")
    action: Literal["APPROVED", "DISCARDED"]
    occasion: str = Field(default="CASUAL")
    ihe_percentage: float = Field(..., ge=0.0, le=100.0, description="IHE exibido quando o usuário decidiu")

    @field_validator("occasion")
    @classmethod
    def check_occasion(cls, v: str) -> str:
        return normalize_occasion(v)

    @field_validator("item_ids")
    @classmethod
    def check_unique(cls, v: List[UUID]) -> List[UUID]:
        if len(set(v)) != len(v):
            raise ValueError("Um look não pode repetir a mesma peça.")
        return v


class LookFeedbackResponse(BaseModel):
    id: UUID
    item_ids: List[UUID]
    action: str
    occasion: str
    ihe_percentage: float
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


# -----------------------------------------------------------------------------
# Feed Comunitário (RF14, RF15, RN05)
# -----------------------------------------------------------------------------

MAX_STYLE_TAGS = 5
MAX_STYLE_TAG_LENGTH = 24


class CommunityPostCreate(BaseModel):
    """
    Nova publicação: foto já enviada à pasta do usuário no Storage, legenda e tags.
    Com `feedback_id`, as peças, a ocasião e o IHE vêm do look aprovado (RF13), não do app.
    """
    image_url: str = Field(..., max_length=500, description="URL pública da foto na pasta do usuário")
    caption: str = Field(..., min_length=1, max_length=500)
    occasion: str = Field(default="CASUAL")
    style_tags: List[str] = Field(default_factory=list, max_length=MAX_STYLE_TAGS)
    feedback_id: Optional[UUID] = Field(default=None, description="Look aprovado que originou o post")
    is_public: Optional[bool] = Field(default=None, description="Nulo segue a visibilidade do perfil (RN05)")

    @field_validator("caption")
    @classmethod
    def strip_caption(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Escreva uma legenda para o look.")
        return v

    @field_validator("occasion")
    @classmethod
    def check_occasion(cls, v: str) -> str:
        return normalize_occasion(v)

    @field_validator("style_tags")
    @classmethod
    def clean_tags(cls, v: List[str]) -> List[str]:
        tags: List[str] = []
        for raw in v:
            tag = raw.strip().lstrip("#").strip()
            if not tag:
                continue
            if len(tag) > MAX_STYLE_TAG_LENGTH:
                raise ValueError(f"Cada tag pode ter até {MAX_STYLE_TAG_LENGTH} caracteres.")
            if tag.lower() not in {t.lower() for t in tags}:
                tags.append(tag)
        return tags


class PostPieceResponse(BaseModel):
    """Peça do look publicado, para a ficha em papel do post (AGENTS.md 7.4)."""
    id: UUID
    category: str
    subcategory: Optional[str] = None
    image_url: str
    dominant_l: float
    dominant_a: float
    dominant_b: float

    model_config = ConfigDict(from_attributes=True)


class CommunityPostResponse(BaseModel):
    id: UUID
    author_name: str
    author_body_shape: Optional[str] = None
    author_palette: Optional[str] = None
    image_url: str
    caption: str
    occasion: str
    style_tags: List[str]
    ihe_percentage: Optional[float] = None
    pieces: List[PostPieceResponse]
    like_count: int
    liked_by_me: bool
    saved_by_me: bool
    is_public: bool
    is_mine: bool
    created_at: datetime


class CommunityFeedResponse(BaseModel):
    posts: List[CommunityPostResponse]
    next_before: Optional[datetime] = Field(
        default=None, description="Passe como `before` para a próxima página; nulo quando acabou"
    )
