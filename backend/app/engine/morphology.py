"""
Módulo de Compensação Morfológica (S_bio)
Conforme Seção 5.3 da Documentação do HarmonIA.
Avalia a matriz de compatibilidade entre os 5 biótipos corporais
(Ampulheta, Retângulo, Triângulo, Triângulo Invertido e Oval)
e os cortes/modelagens de vestuário para promover equilíbrio de silhueta.
"""

import unicodedata
from typing import List, Dict, Set


def _strip_accents(text: str) -> str:
    return unicodedata.normalize('NFD', text).encode('ascii', 'ignore').decode('utf-8')


BIOTYPES: Set[str] = {
    "AMPULHETA",
    "RETANGULO",
    "TRIANGULO",
    "TRIANGULO_INVERTIDO",
    "OVAL",
}

# Matriz de Compatibilidade Morfológica: Biótipo x Modelagem/Corte
# Valores calibrados entre 0.0 (desfavorável/desequilibrado) e 1.0 (alta harmonização)
MORPHOLOGY_COMPATIBILITY_MATRIX: Dict[str, Dict[str, float]] = {
    "AMPULHETA": {
        "ACINTURADO": 1.00,
        "VESTIDO_ENVELOPE": 1.00,
        "CINTURA_ALTA": 0.95,
        "DECOTE_V": 0.90,
        "PANTALONA": 0.88,
        "EVASE": 0.85,
        "RETO": 0.80,
        "SKINNY": 0.75,
        "FLUIDO_AMPLO": 0.70,
        "CROPPED": 0.85,
        "ALFAIATARIA_ESTRUTURADA": 0.90,
        "ESTRUTURADO_OMBRO": 0.75,
        "OVERSIZED": 0.60,
    },
    "RETANGULO": {
        "ACINTURADO": 0.95,
        "EVASE": 0.92,
        "CINTURA_ALTA": 0.90,
        "ESTRUTURADO_OMBRO": 0.88,
        "PANTALONA": 0.85,
        "CROPPED": 0.82,
        "DECOTE_V": 0.80,
        "VESTIDO_ENVELOPE": 0.85,
        "ALFAIATARIA_ESTRUTURADA": 0.88,
        "RETO": 0.75,
        "FLUIDO_AMPLO": 0.70,
        "SKINNY": 0.70,
        "OVERSIZED": 0.65,
    },
    "TRIANGULO": {
        # Foco: valorizar tronco e ombros, suavizar quadril
        "ESTRUTURADO_OMBRO": 1.00,
        "DECOTE_V": 0.95,
        "PANTALONA": 0.90,
        "EVASE": 0.92,
        "ALFAIATARIA_ESTRUTURADA": 0.90,
        "CROPPED": 0.80,
        "ACINTURADO": 0.85,
        "CINTURA_ALTA": 0.85,
        "RETO": 0.75,
        "VESTIDO_ENVELOPE": 0.88,
        "FLUIDO_AMPLO": 0.75,
        "SKINNY": 0.50,
        "OVERSIZED": 0.55,
    },
    "TRIANGULO_INVERTIDO": {
        # Foco: dar volume a partes de baixo, suavizar ombros
        "PANTALONA": 1.00,
        "EVASE": 0.95,
        "FLUIDO_AMPLO": 0.90,
        "DECOTE_V": 0.90,
        "VESTIDO_ENVELOPE": 0.88,
        "RETO": 0.80,
        "CINTURA_ALTA": 0.82,
        "SKINNY": 0.70,
        "ACINTURADO": 0.75,
        "CROPPED": 0.70,
        "ALFAIATARIA_ESTRUTURADA": 0.70,
        "ESTRUTURADO_OMBRO": 0.50,
        "OVERSIZED": 0.60,
    },
    "OVAL": {
        # Foco: alongar silhueta verticalmente
        "VESTIDO_ENVELOPE": 1.00,
        "DECOTE_V": 0.95,
        "RETO": 0.90,
        "ALFAIATARIA_ESTRUTURADA": 0.88,
        "FLUIDO_AMPLO": 0.85,
        "PANTALONA": 0.85,
        "EVASE": 0.80,
        "ACINTURADO": 0.75,
        "CINTURA_ALTA": 0.70,
        "ESTRUTURADO_OMBRO": 0.75,
        "CROPPED": 0.50,
        "SKINNY": 0.45,
        "OVERSIZED": 0.60,
    },
}


def normalize_biotype(biotype: str) -> str:
    """Normaliza a string do biótipo."""
    clean_str = _strip_accents(biotype.strip().upper())
    key = clean_str.replace(" ", "_").replace("-", "_")
    if key not in BIOTYPES:
        raise ValueError(f"Biótipo '{biotype}' inválido. Opções válidas: {sorted(list(BIOTYPES))}")
    return key


def calculate_s_bio(biotype: str, garment_cuts: List[str]) -> float:
    """
    Calcula a pontuação de compensação morfológica S_bio.

    Parâmetros:
    - biotype: Um dos 5 biótipos válidos.
    - garment_cuts: Lista de cortes/modelagens das peças que compõem o look.

    Retorna:
    - Valor float entre [0.0, 1.0].
    """
    norm_biotype = normalize_biotype(biotype)
    matrix = MORPHOLOGY_COMPATIBILITY_MATRIX[norm_biotype]

    if not garment_cuts:
        # Se nenhuma modelagem for especificada, assume baseline neutro seguro de 0.75
        return 0.75

    scores = []
    for cut in garment_cuts:
        clean_cut = _strip_accents(cut.strip().upper())
        cut_key = clean_cut.replace(" ", "_").replace("-", "_")
        # Se a modelagem for conhecida na matriz, usa o score; senão assume padrão 0.75
        cut_score = matrix.get(cut_key, 0.75)
        scores.append(cut_score)

    avg_score = sum(scores) / len(scores)
    return max(0.0, min(1.0, avg_score))
