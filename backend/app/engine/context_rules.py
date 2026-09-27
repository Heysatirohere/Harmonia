"""
Módulo de Regras de Contexto, Clima e Ocasião (S_ocasion)
Conforme Seção 5.3 da Documentação do HarmonIA.
Avalia a adequação formal do traje ao evento selecionado combinada
com a restrição meteorológica do momento capturada via telemetria climática.
"""

from typing import Dict, Set


OCCASION_TARGET_FORMALITY: Dict[str, float] = {
    "CASUAL": 0.25,
    "ESPORTE": 0.10,
    "TRABALHO": 0.65,
    "CORPORATIVO": 0.70,
    "NOITE": 0.75,
    "FESTA": 0.80,
    "GALA": 0.95,
}

THERMAL_CATEGORIES: Set[str] = {
    "LEVE",         # Roupas de verão (regatas, linho leve, shorts)
    "MEDIO",        # Meia-estação (camisas, jeans, cardigans)
    "PESADO",       # Inverno (sobretudos, blazers grossos, lã)
    "IMPERMEAVEL",  # Anoraks, capas de chuva
}


def normalize_occasion(occasion: str) -> str:
    """Normaliza o nome da ocasião."""
    key = occasion.strip().upper().replace(" ", "_")
    if key not in OCCASION_TARGET_FORMALITY:
        raise ValueError(
            f"Ocasião '{occasion}' não reconhecida. Opções: {sorted(list(OCCASION_TARGET_FORMALITY.keys()))}"
        )
    return key


def calculate_formality_score(garment_formality: float, occasion: str) -> float:
    """
    Calcula a adequação de formalidade da peça (0.0 a 1.0) com relação à ocasião.
    S_formality = 1.0 - min(1.0, |garment_formality - target| * 1.5)
    """
    norm_occ = normalize_occasion(occasion)
    target = OCCASION_TARGET_FORMALITY[norm_occ]

    if not (0.0 <= garment_formality <= 1.0):
        raise ValueError("garment_formality deve estar entre 0.0 e 1.0.")

    diff = abs(garment_formality - target)
    score = 1.0 - min(1.0, diff * 1.5)
    return max(0.0, min(1.0, score))


def calculate_weather_score(
    temperature_celsius: float,
    is_raining: bool = False,
    thermal_category: str = "MEDIO",
) -> float:
    """
    Calcula a adequação da peça às condições meteorológicas (temperatura e chuva).
    """
    cat = thermal_category.strip().upper()
    if cat not in THERMAL_CATEGORIES:
        cat = "MEDIO"

    # 1. Avaliação por faixa de temperatura
    if temperature_celsius < 15.0:
        # Clima Frio
        thermal_scores = {"PESADO": 1.00, "MEDIO": 0.75, "LEVE": 0.30, "IMPERMEAVEL": 0.80}
    elif 15.0 <= temperature_celsius <= 25.0:
        # Clima Ameno / Meia-Estação
        thermal_scores = {"MEDIO": 1.00, "LEVE": 0.90, "PESADO": 0.60, "IMPERMEAVEL": 0.75}
    else:
        # Clima Quente (> 25°C)
        thermal_scores = {"LEVE": 1.00, "MEDIO": 0.65, "PESADO": 0.15, "IMPERMEAVEL": 0.50}

    temp_score = thermal_scores.get(cat, 0.70)

    # 2. Avaliação de Chuva
    if is_raining:
        if cat == "IMPERMEAVEL":
            temp_score = min(1.0, temp_score + 0.15)
        elif cat == "LEVE":
            temp_score = max(0.0, temp_score - 0.20)

    return max(0.0, min(1.0, temp_score))


def calculate_s_ocasion(
    garment_formality: float,
    occasion: str,
    temperature_celsius: float,
    is_raining: bool = False,
    thermal_category: str = "MEDIO",
) -> float:
    """
    Calcula o score de Contexto e Clima S_ocasion.
    Ponderação: 60% Formalidade da Ocasião + 40% Restrição Meteorológica.

    Retorna float obrigatoriamente delimitado em [0.0, 1.0].
    """
    s_formality = calculate_formality_score(garment_formality, occasion)
    s_weather = calculate_weather_score(temperature_celsius, is_raining, thermal_category)

    score = (0.60 * s_formality) + (0.40 * s_weather)
    return max(0.0, min(1.0, score))
