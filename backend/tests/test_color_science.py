"""
Testes Unitários do Módulo de Ciência de Cores (CIE L*a*b* e S_cor)
Conforme Seção 5.3 da Documentação do HarmonIA.
"""

import math
import pytest
from app.engine.color_science import (
    LabColor,
    calculate_delta_e,
    calculate_s_cor,
    get_seasonal_palette_centroids,
    calculate_garment_s_cor,
    SEASONAL_PALETTES,
)


def test_lab_color_validations():
    """Valida a criação e limites de LabColor."""
    color = LabColor(L=50.0, a=20.0, b=-30.0)
    assert color.L == 50.0
    assert color.a == 20.0
    assert color.b == -30.0
    assert color.to_tuple() == (50.0, 20.0, -30.0)

    # L fora do limite [0, 100]
    with pytest.raises(ValueError):
        LabColor(L=150.0, a=0.0, b=0.0)

    with pytest.raises(ValueError):
        LabColor(L=-10.0, a=0.0, b=0.0)


def test_calculate_delta_e_zero():
    """Valida que duas cores idênticas possuem distância ΔE igual a zero."""
    c1 = LabColor(L=45.0, a=38.0, b=42.0)
    c2 = LabColor(L=45.0, a=38.0, b=42.0)
    assert calculate_delta_e(c1, c2) == 0.0


def test_calculate_delta_e_euclidean_distance():
    """Valida o cálculo 3D da distância euclidiana ΔE*ab."""
    # Vetor (3, 4, 0) -> distância 5
    c1 = LabColor(L=10.0, a=0.0, b=0.0)
    c2 = LabColor(L=13.0, a=4.0, b=0.0)
    assert math.isclose(calculate_delta_e(c1, c2), 5.0, abs_tol=1e-6)


def test_s_cor_zero_delta_e_returns_one():
    """ΔE igual a zero resulta em S_cor exato de 1.0 (Harmonia Perfeita)."""
    assert calculate_s_cor(0.0) == 1.0


def test_s_cor_exponential_decay_sigma_c():
    """
    Valida o decaimento exponencial de S_cor com sigma_c = 18.0.
    Para ΔE = 18.0, S_cor deve ser exp(-18.0/18.0) = 1/e ≈ 0.36787944117.
    """
    sigma_c = 18.0
    delta_e = 18.0
    expected_s_cor = math.exp(-1.0)  # ~ 0.36787944117

    calculated = calculate_s_cor(delta_e, sigma_c=sigma_c)
    assert math.isclose(calculated, expected_s_cor, rel_tol=1e-6)
    assert 0.0 <= calculated <= 1.0


def test_s_cor_negative_delta_e_raises_error():
    """Garante erro ao passar distância negativa."""
    with pytest.raises(ValueError):
        calculate_s_cor(-5.0)


def test_all_12_seasonal_palettes_exist_and_have_centroids():
    """Valida a existência dos centróides das 12 cartelas sazonais expandidas."""
    expected_palettes = [
        "INVERNO_FRIO", "INVERNO_BRILHANTE", "INVERNO_ESCURO",
        "OUTONO_QUENTE", "OUTONO_SUAVE", "OUTONO_ESCURO",
        "PRIMAVERA_QUENTE", "PRIMAVERA_BRILHANTE", "PRIMAVERA_CLARA",
        "VERAO_FRIO", "VERAO_SUAVE", "VERAO_CLARO"
    ]

    assert len(SEASONAL_PALETTES) == 12

    for palette in expected_palettes:
        centroids = get_seasonal_palette_centroids(palette)
        assert len(centroids) > 0
        for color in centroids:
            assert isinstance(color, LabColor)


def test_calculate_garment_s_cor_exact_match():
    """Valida S_cor próximo de 1.0 quando a peça possui a cor idêntica de um centróide da cartela."""
    # Cor terracota do Outono Quente
    terracotta = LabColor(L=45.0, a=38.0, b=42.0)
    score = calculate_garment_s_cor(terracotta, "OUTONO_QUENTE")
    assert math.isclose(score, 1.0, abs_tol=1e-5)


def test_calculate_garment_s_cor_invalid_palette():
    """Garante exceção para cartela inexistente."""
    with pytest.raises(ValueError):
        calculate_garment_s_cor(LabColor(L=50, a=0, b=0), "CARTELA_INEXISTENTE")
