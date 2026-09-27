"""
Orquestrador da Fórmula Mestra do Índice de Harmonia Estética (IHE)
Conforme Seção 5.3 da Documentação do HarmonIA (FECAP - Ciência da Computação).

Fórmula Mestra do IHE:
IHE = w_c · S_cor + w_m · S_bio + w_o · S_ocasion + w_v · S_cos

Onde os pesos obedecem à condição de normalização:
w_c + w_m + w_o + w_v = 1.0
(sendo w_c = 0.35, w_m = 0.25, w_o = 0.20 e w_v = 0.20 na calibração padrão de produção).
"""

import math
from typing import List, Optional, Dict
import numpy as np
from pydantic import BaseModel, Field, field_validator

from .color_science import LabColor, calculate_garment_s_cor
from .morphology import calculate_s_bio
from .context_rules import calculate_s_ocasion


# Pesos Padrão de Produção (Seção 5.3)
DEFAULT_WEIGHT_COR = 0.35
DEFAULT_WEIGHT_BIO = 0.25
DEFAULT_WEIGHT_OCASION = 0.20
DEFAULT_WEIGHT_COS = 0.20


def calculate_s_cos(u: List[float], v: List[float]) -> float:
    """
    Calcula a similaridade vetorial de cosseno entre o vetor latente do perfil do usuário (u)
    e o vetor representativo das roupas do look (v):

    S_cos = (u · v) / (||u|| · ||v||)

    Trata adequadamente vetores com norma nula e ajusta o intervalo final para [0.0, 1.0].
    """
    if len(u) != len(v):
        raise ValueError(f"Dimensões incompatíveis para cálculo de cosseno: len(u)={len(u)} != len(v)={len(v)}.")

    arr_u = np.array(u, dtype=np.float64)
    arr_v = np.array(v, dtype=np.float64)

    norm_u = np.linalg.norm(arr_u)
    norm_v = np.linalg.norm(arr_v)

    # Tratamento de norma nula para evitar divisão por zero
    if norm_u < 1e-9 or norm_v < 1e-9:
        return 0.5  # Retorna baseline neutro

    raw_cos = float(np.dot(arr_u, arr_v) / (norm_u * norm_v))

    # Mapeia intervalo [-1.0, 1.0] do cosseno bruto para [0.0, 1.0] caso haja valores negativos
    if raw_cos < 0.0:
        normalized_cos = (raw_cos + 1.0) / 2.0
    else:
        normalized_cos = raw_cos

    return max(0.0, min(1.0, normalized_cos))


class IHERequest(BaseModel):
    """Modelo de Entrada para o Cálculo do IHE."""
    garment_color: LabColor = Field(..., description="Cor representativa no espaço CIE L*a*b*")
    user_palette: str = Field(..., description="Nome da cartela sazonal do usuário (ex: OUTONO_QUENTE)")
    user_biotype: str = Field(..., description="Biótipo corporal (ex: AMPULHETA)")
    garment_cuts: List[str] = Field(default_factory=list, description="Lista de modelagens/cortes do look")
    garment_formality: float = Field(..., ge=0.0, le=1.0, description="Formalidade intrínseca da peça (0.0 a 1.0)")
    occasion: str = Field(..., description="Ocasião de destino (ex: CORPORATIVO, CASUAL, GALA)")
    temperature_celsius: float = Field(..., description="Temperatura local em graus Celsius")
    is_raining: bool = Field(default=False, description="Flag de chuva no local")
    garment_thermal_category: str = Field(default="MEDIO", description="Categoria térmica (LEVE, MEDIO, PESADO, IMPERMEAVEL)")
    user_style_vector: List[float] = Field(..., description="Vetor latente de estilo do usuário")
    look_style_vector: List[float] = Field(..., description="Vetor latente de estilo do look")

    custom_weights: Optional[Dict[str, float]] = Field(
        default=None,
        description="Pesos customizados opcionais para testes de sensibilidade"
    )

    @field_validator("user_style_vector", "look_style_vector")
    @classmethod
    def validate_vectors_not_empty(cls, v: List[float]) -> List[float]:
        if not v:
            raise ValueError("Os vetores de estilo não podem ser vazios.")
        return v


class IHEResponse(BaseModel):
    """Modelo de Saída do Processamento do IHE."""
    ihe_score: float = Field(..., ge=0.0, le=1.0, description="Índice de Harmonia Estética final (0.0 a 1.0)")
    ihe_percentage: float = Field(..., ge=0.0, le=100.0, description="IHE formatado em porcentagem (0% a 100%)")
    s_cor: float = Field(..., ge=0.0, le=1.0, description="Score de Harmonia Cromática (35%)")
    s_bio: float = Field(..., ge=0.0, le=1.0, description="Score de Compensação Morfológica (25%)")
    s_ocasion: float = Field(..., ge=0.0, le=1.0, description="Score de Contexto e Clima (20%)")
    s_cos: float = Field(..., ge=0.0, le=1.0, description="Score de Similaridade Vetorial (20%)")
    is_strongly_recommended: bool = Field(
        ...,
        description="True se IHE >= 0.75 (Selo 'Look Fortemente Recomendado')"
    )


def calculate_ihe(request: IHERequest) -> IHEResponse:
    """
    Função Principal / Orquestradora que compila o Índice de Harmonia Estética (IHE).
    Executa em tempo real em alta performance (< 10ms).
    """
    # 1. Variável S_cor (Harmonia Cromática CIE L*a*b*)
    s_cor = calculate_garment_s_cor(
        garment_color=request.garment_color,
        palette_name=request.user_palette,
    )

    # 2. Variável S_bio (Compensação Morfológica)
    s_bio = calculate_s_bio(
        biotype=request.user_biotype,
        garment_cuts=request.garment_cuts,
    )

    # 3. Variável S_ocasion (Contexto e Clima)
    s_ocasion = calculate_s_ocasion(
        garment_formality=request.garment_formality,
        occasion=request.occasion,
        temperature_celsius=request.temperature_celsius,
        is_raining=request.is_raining,
        thermal_category=request.garment_thermal_category,
    )

    # 4. Variável S_cos (Similaridade Vetorial de Estilo)
    s_cos = calculate_s_cos(
        u=request.user_style_vector,
        v=request.look_style_vector,
    )

    # Definir pesos (padrão de produção ou customizado)
    w_c = DEFAULT_WEIGHT_COR
    w_m = DEFAULT_WEIGHT_BIO
    w_o = DEFAULT_WEIGHT_OCASION
    w_v = DEFAULT_WEIGHT_COS

    if request.custom_weights:
        w_c = request.custom_weights.get("w_c", w_c)
        w_m = request.custom_weights.get("w_m", w_m)
        w_o = request.custom_weights.get("w_o", w_o)
        w_v = request.custom_weights.get("w_v", w_v)

    # Validação de soma de pesos
    weight_sum = w_c + w_m + w_o + w_v
    if not math.isclose(weight_sum, 1.0, abs_tol=1e-5):
        raise ValueError(f"A soma dos pesos deve ser exatamente 1.0. Soma atual: {weight_sum}")

    # Cálculo da Fórmula Mestra do IHE
    raw_ihe = (w_c * s_cor) + (w_m * s_bio) + (w_o * s_ocasion) + (w_v * s_cos)
    ihe_score = max(0.0, min(1.0, raw_ihe))
    ihe_percentage = round(ihe_score * 100.0, 2)

    # Regra de recomendação forte: IHE >= 75% (0.75)
    is_strongly_recommended = (ihe_score >= 0.75)

    return IHEResponse(
        ihe_score=round(ihe_score, 4),
        ihe_percentage=ihe_percentage,
        s_cor=round(s_cor, 4),
        s_bio=round(s_bio, 4),
        s_ocasion=round(s_ocasion, 4),
        s_cos=round(s_cos, 4),
        is_strongly_recommended=is_strongly_recommended,
    )
