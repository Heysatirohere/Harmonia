"""
Módulo de Ciência de Cores e Mapeamento Morfocromático (CIE L*a*b*)
Conforme Seção 5.3 da Documentação do HarmonIA (FECAP - Ciência da Computação).
"""

import math
from typing import List, Dict
from pydantic import BaseModel, Field, field_validator


class LabColor(BaseModel):
    """Representação de cor no espaço perceptualmente uniforme CIE L*a*b*."""
    L: float = Field(..., ge=0.0, le=100.0, description="Luminosidade (0 a 100)")
    a: float = Field(..., ge=-128.0, le=127.0, description="Gradiente verde (-128) a vermelho (+127)")
    b: float = Field(..., ge=-128.0, le=127.0, description="Gradiente azul (-128) a amarelo (+127)")

    def to_tuple(self) -> tuple[float, float, float]:
        return (self.L, self.a, self.b)


def calculate_delta_e(color1: LabColor, color2: LabColor) -> float:
    """
    Calcula a distância euclidiana perceptualmente uniforme no espaço CIE L*a*b*:
    ΔE*ab = √[(L1 - L2)² + (a1 - a2)² + (b1 - b2)²]
    """
    dL = color1.L - color2.L
    da = color1.a - color2.a
    db = color1.b - color2.b
    return math.sqrt(dL * dL + da * da + db * db)


def calculate_s_cor(delta_e: float, sigma_c: float = 18.0) -> float:
    """
    Converte a distância cromática ΔE no escore normalizado S_cor:
    S_cor = exp(-ΔE*ab / σ_c)

    - Para ΔE = 0.0 -> S_cor = 1.0 (Harmonia perfeita)
    - Para ΔE = σ_c (18.0) -> S_cor = 1/e ≈ 0.367879...
    - Retorna obrigatoriamente valor delimitado no intervalo [0.0, 1.0].
    """
    if delta_e < 0.0:
        raise ValueError("A distância delta_e não pode ser negativa.")
    if sigma_c <= 0.0:
        raise ValueError("O parâmetro de calibração sigma_c deve ser estritamente positivo.")

    score = math.exp(-delta_e / sigma_c)
    return max(0.0, min(1.0, score))


# Tabela de Centróides do Espaço CIE L*a*b* para as 12 Cartelas Sazonais Expandidas
SEASONAL_PALETTES: Dict[str, List[LabColor]] = {
    "INVERNO_FRIO": [
        LabColor(L=32.0, a=48.0, b=-52.0),   # Azul Royal Frio
        LabColor(L=45.0, a=-55.0, b=22.0),   # Verde Esmeralda
        LabColor(L=95.0, a=0.0, b=0.0),       # Branco Puro Ísland
        LabColor(L=35.0, a=58.0, b=30.0),    # Carmim Frio
    ],
    "INVERNO_BRILHANTE": [
        LabColor(L=40.0, a=62.0, b=-40.0),   # Magenta Elétrico
        LabColor(L=50.0, a=20.0, b=-60.0),   # Azul Vívido
        LabColor(L=85.0, a=-10.0, b=70.0),   # Amarelo Gelado Vívido
        LabColor(L=10.0, a=0.0, b=0.0),       # Preto Carvão Puro
    ],
    "INVERNO_ESCURO": [
        LabColor(L=22.0, a=35.0, b=-20.0),   # Ameixa Profundo
        LabColor(L=18.0, a=-12.0, b=-28.0),  # Azul Marinho Escuro
        LabColor(L=25.0, a=40.0, b=15.0),    # Borgonha Fechado
        LabColor(L=20.0, a=-25.0, b=10.0),   # Verde Floresta Escuro
    ],
    "OUTONO_QUENTE": [
        LabColor(L=45.0, a=38.0, b=42.0),    # Terracota Quente (#A34836)
        LabColor(L=60.0, a=15.0, b=58.0),    # Mostarda Solar
        LabColor(L=42.0, a=-18.0, b=28.0),   # Oliva ESG (#4B5842)
        LabColor(L=52.0, a=42.0, b=48.0),    # Cobre Amadeirado
    ],
    "OUTONO_SUAVE": [
        LabColor(L=58.0, a=-10.0, b=18.0),   # Sálvia Suave
        LabColor(L=64.0, a=12.0, b=18.0),    # Taupe Aveludado
        LabColor(L=55.0, a=28.0, b=30.0),    # Terracota Suave
        LabColor(L=82.0, a=4.0, b=16.0),     # Linho Cru (#FBF9F5)
    ],
    "OUTONO_ESCURO": [
        LabColor(L=25.0, a=18.0, b=20.0),    # Chocolate Amargo
        LabColor(L=28.0, a=-15.0, b=18.0),   # Oliva Profundo
        LabColor(L=22.0, a=10.0, b=12.0),    # Café Espresso
        LabColor(L=38.0, a=36.0, b=38.0),    # Laranja Queimado Escuro
    ],
    "PRIMAVERA_QUENTE": [
        LabColor(L=62.0, a=45.0, b=35.0),    # Coral Quente
        LabColor(L=78.0, a=10.0, b=65.0),    # Amarelo Dourado
        LabColor(L=65.0, a=-30.0, b=-15.0),  # Turquesa Solar
        LabColor(L=75.0, a=32.0, b=28.0),    # Pêssego Luminoso
    ],
    "PRIMAVERA_BRILHANTE": [
        LabColor(L=60.0, a=55.0, b=40.0),    # Coral Vívido
        LabColor(L=70.0, a=-45.0, b=50.0),   # Verde Lima Brilhante
        LabColor(L=62.0, a=-20.0, b=-45.0),  # Aqua Brilhante
        LabColor(L=80.0, a=20.0, b=70.0),    # Amarelo Canário
    ],
    "PRIMAVERA_CLARA": [
        LabColor(L=80.0, a=22.0, b=20.0),    # Pêssego Claro
        LabColor(L=82.0, a=24.0, b=8.0),     # Rosa Quente Claro
        LabColor(L=88.0, a=2.0, b=40.0),     # Manteiga Suave
        LabColor(L=80.0, a=-18.0, b=14.0),   # Menta Clara
    ],
    "VERAO_FRIO": [
        LabColor(L=48.0, a=38.0, b=-12.0),   # Framboesa Frio
        LabColor(L=55.0, a=-8.0, b=-32.0),   # Azul Ardosia
        LabColor(L=72.0, a=-12.0, b=-22.0),  # Azul Pastel Frio
        LabColor(L=60.0, a=22.0, b=-18.0),   # Malva Clássico
    ],
    "VERAO_SUAVE": [
        LabColor(L=62.0, a=18.0, b=4.0),     # Rosa Antigo/Poeira
        LabColor(L=65.0, a=-12.0, b=8.0),    # Sálvia Desaturado
        LabColor(L=58.0, a=-5.0, b=-18.0),   # Azul Cinzento Muted
        LabColor(L=66.0, a=16.0, b=-12.0),   # Lavanda Suave
    ],
    "VERAO_CLARO": [
        LabColor(L=78.0, a=-10.0, b=-25.0),  # Azul Céu Claro
        LabColor(L=80.0, a=20.0, b=-4.0),    # Rosa Suave Claro
        LabColor(L=75.0, a=12.0, b=-20.0),   # Lavanda Clara
        LabColor(L=84.0, a=-16.0, b=-8.0),   # Menta Gelada
    ],
}


def get_seasonal_palette_centroids(palette_name: str) -> List[LabColor]:
    """Retorna os centróides CIE L*a*b* da cartela sazonal expandida informada."""
    key = palette_name.strip().upper().replace(" ", "_")
    if key not in SEASONAL_PALETTES:
        raise ValueError(f"Cartela sazonal '{palette_name}' não reconhecida. Opções: {list(SEASONAL_PALETTES.keys())}")
    return SEASONAL_PALETTES[key]


def calculate_garment_s_cor(garment_color: LabColor, palette_name: str, sigma_c: float = 18.0) -> float:
    """
    Calcula a menor distância euclidiana ΔE entre a cor da peça e os centróides da cartela do usuário,
    retornando o score normalizado S_cor.
    """
    centroids = get_seasonal_palette_centroids(palette_name)
    min_delta_e = min(calculate_delta_e(garment_color, centroid) for centroid in centroids)
    return calculate_s_cor(min_delta_e, sigma_c=sigma_c)
