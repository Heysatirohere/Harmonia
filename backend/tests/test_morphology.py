"""
Testes Unitários do Módulo de Compensação Morfológica (S_bio)
Conforme Seção 5.3 da Documentação do HarmonIA.
"""

import pytest
from app.engine.morphology import (
    calculate_s_bio,
    normalize_biotype,
    BIOTYPES,
    MORPHOLOGY_COMPATIBILITY_MATRIX,
)


def test_biotype_normalization():
    """Valida a normalização dos nomes de biótipos."""
    assert normalize_biotype("Ampulheta") == "AMPULHETA"
    assert normalize_biotype("triangulo invertido") == "TRIANGULO_INVERTIDO"
    assert normalize_biotype(" Retângulo ") == "RETANGULO"

    with pytest.raises(ValueError):
        normalize_biotype("BIOTIPO_INVALIDO")


def test_s_bio_bounds_for_all_biotypes():
    """Garante que S_bio retorne obrigatoriamente valores dentro do intervalo [0.0, 1.0]."""
    sample_cuts = ["ACINTURADO", "PANTALONA", "ESTRUTURADO_OMBRO", "DECOTE_V", "OVERSIZED"]

    for biotype in BIOTYPES:
        score = calculate_s_bio(biotype, sample_cuts)
        assert 0.0 <= score <= 1.0, f"Score fora dos limites para biótipo {biotype}: {score}"


def test_s_bio_empty_cuts_returns_default():
    """Garante que lista de cortes vazia retorne o baseline neutro de 0.75."""
    for biotype in BIOTYPES:
        score = calculate_s_bio(biotype, [])
        assert score == 0.75


def test_ampulheta_high_compatibility_cuts():
    """Valida alta compatibilidade para biótipo Ampulheta com corte acinturado e envelope."""
    score = calculate_s_bio("AMPULHETA", ["ACINTURADO", "VESTIDO_ENVELOPE"])
    assert score == 1.00


def test_triangulo_structured_shoulders_high_score():
    """Valida que ombro estruturado favorece o biótipo Triângulo (suaviza proporção do quadril)."""
    score = calculate_s_bio("TRIANGULO", ["ESTRUTURADO_OMBRO", "DECOTE_V"])
    assert score >= 0.95


def test_triangulo_invertido_pant_flared_high_score():
    """Valida que pantalona e corte evasê favorecem o biótipo Triângulo Invertido."""
    score = calculate_s_bio("TRIANGULO_INVERTIDO", ["PANTALONA", "EVASE"])
    assert score >= 0.95
