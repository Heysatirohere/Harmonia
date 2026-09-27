"""
Pacote Engine de Cálculo do Índice de Harmonia Estética (IHE)
HarmonIA - FECAP Ciência da Computação
"""

from .color_science import (
    LabColor,
    calculate_delta_e,
    calculate_s_cor,
    get_seasonal_palette_centroids,
    calculate_garment_s_cor,
    SEASONAL_PALETTES,
)

from .morphology import (
    calculate_s_bio,
    BIOTYPES,
    MORPHOLOGY_COMPATIBILITY_MATRIX,
)

from .context_rules import (
    calculate_s_ocasion,
    calculate_formality_score,
    calculate_weather_score,
    OCCASION_TARGET_FORMALITY,
)

from .ihe_calculator import (
    IHERequest,
    IHEResponse,
    calculate_ihe,
    calculate_s_cos,
    DEFAULT_WEIGHT_COR,
    DEFAULT_WEIGHT_BIO,
    DEFAULT_WEIGHT_OCASION,
    DEFAULT_WEIGHT_COS,
)

__all__ = [
    "LabColor",
    "calculate_delta_e",
    "calculate_s_cor",
    "get_seasonal_palette_centroids",
    "calculate_garment_s_cor",
    "SEASONAL_PALETTES",
    "calculate_s_bio",
    "BIOTYPES",
    "MORPHOLOGY_COMPATIBILITY_MATRIX",
    "calculate_s_ocasion",
    "calculate_formality_score",
    "calculate_weather_score",
    "OCCASION_TARGET_FORMALITY",
    "IHERequest",
    "IHEResponse",
    "calculate_ihe",
    "calculate_s_cos",
    "DEFAULT_WEIGHT_COR",
    "DEFAULT_WEIGHT_BIO",
    "DEFAULT_WEIGHT_OCASION",
    "DEFAULT_WEIGHT_COS",
]
