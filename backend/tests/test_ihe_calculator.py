"""
Testes Unitários do Orquestrador Mestre do IHE e Requisitos RNF03 e RNF05
Conforme Seção 5.3 e Seção 4 da Documentação do HarmonIA (FECAP).
"""

import time
import pytest
import math
from app.engine.color_science import LabColor
from app.engine.context_rules import calculate_s_ocasion, calculate_formality_score, calculate_weather_score
from app.engine.ihe_calculator import (
    calculate_s_cos,
    calculate_ihe,
    IHERequest,
    IHEResponse,
    DEFAULT_WEIGHT_COR,
    DEFAULT_WEIGHT_BIO,
    DEFAULT_WEIGHT_OCASION,
    DEFAULT_WEIGHT_COS,
)


def test_calculate_s_cos_parallel_vectors():
    """Vetores paralelos idênticos devem retornar similaridade de cosseno de 1.0."""
    u = [1.0, 2.0, 3.0, 4.0]
    v = [2.0, 4.0, 6.0, 8.0]
    assert math.isclose(calculate_s_cos(u, v), 1.0, abs_tol=1e-6)


def test_calculate_s_cos_zero_vector_handles_without_exception():
    """Vetor com norma nula não deve gerar ZeroDivisionError e deve retornar 0.5."""
    u = [0.0, 0.0, 0.0]
    v = [1.0, 2.0, 3.0]
    assert calculate_s_cos(u, v) == 0.5


def test_calculate_s_cos_mismatched_dimensions_raises_error():
    """Garante erro de dimensão quando vetores têm tamanhos diferentes."""
    u = [1.0, 2.0]
    v = [1.0, 2.0, 3.0]
    with pytest.raises(ValueError):
        calculate_s_cos(u, v)


def test_context_rules_formality_and_weather():
    """Valida calculo de formalidade e temperatura para s_ocasion."""
    # Gala com formalidade 0.95 -> s_formality ~ 1.0
    f_score = calculate_formality_score(0.95, "GALA")
    assert f_score >= 0.95

    # Clima Frio (< 15°C) com jaqueta PESADO -> s_weather = 1.0
    w_score = calculate_weather_score(12.0, is_raining=False, thermal_category="PESADO")
    assert w_score == 1.00

    s_ocasion = calculate_s_ocasion(
        garment_formality=0.95,
        occasion="GALA",
        temperature_celsius=12.0,
        is_raining=False,
        thermal_category="PESADO",
    )
    assert 0.0 <= s_ocasion <= 1.0


def test_ihe_strongly_recommended_true_when_score_ge_075():
    """
    Looks com IHE >= 0.75 (75%) DEVEM ser marcados obrigatoriamente como
    is_strongly_recommended = True ("Look Fortemente Recomendado").
    """
    # Configuração de um look altamente harmonioso
    request = IHERequest(
        garment_color=LabColor(L=45.0, a=38.0, b=42.0),  # Terracota exato do Outono Quente
        user_palette="OUTONO_QUENTE",
        user_biotype="AMPULHETA",
        garment_cuts=["ACINTURADO", "VESTIDO_ENVELOPE"],
        garment_formality=0.70,
        occasion="CORPORATIVO",
        temperature_celsius=20.0,
        is_raining=False,
        garment_thermal_category="MEDIO",
        user_style_vector=[0.5, 0.8, 0.3, 0.9],
        look_style_vector=[0.5, 0.8, 0.3, 0.9],  # Cosseno = 1.0
    )

    response = calculate_ihe(request)

    assert isinstance(response, IHEResponse)
    assert response.ihe_score >= 0.75
    assert response.is_strongly_recommended is True
    assert response.ihe_percentage >= 75.0


def test_ihe_strongly_recommended_false_when_score_lt_075():
    """
    Looks com IHE < 0.75 DEVEM ter is_strongly_recommended = False.
    """
    # Configuração desarmônica (cor contrastante de cartela fria vs outono, biotipo incompativel, clima incompativel)
    request = IHERequest(
        garment_color=LabColor(L=95.0, a=0.0, b=0.0),  # Branco puro (Inverno Frio)
        user_palette="OUTONO_ESCURO",
        user_biotype="OVAL",
        garment_cuts=["CROPPED", "SKINNY"],
        garment_formality=0.10,                         # Casual em festa de gala
        occasion="GALA",
        temperature_celsius=5.0,                        # 5°C vestindo roupa leve de verão
        is_raining=True,
        garment_thermal_category="LEVE",
        user_style_vector=[1.0, 0.0, 0.0],
        look_style_vector=[0.0, 1.0, 0.0],              # Cosseno baixo/ortogonal
    )

    response = calculate_ihe(request)

    assert response.ihe_score < 0.75
    assert response.is_strongly_recommended is False


def test_ihe_custom_weights_invalid_sum_raises_error():
    """Garante erro quando a soma dos pesos customizados é diferente de 1.0."""
    request = IHERequest(
        garment_color=LabColor(L=50.0, a=0.0, b=0.0),
        user_palette="OUTONO_QUENTE",
        user_biotype="AMPULHETA",
        garment_cuts=["RETO"],
        garment_formality=0.5,
        occasion="CASUAL",
        temperature_celsius=20.0,
        user_style_vector=[1.0, 0.0],
        look_style_vector=[1.0, 0.0],
        custom_weights={"w_c": 0.5, "w_m": 0.5, "w_o": 0.5, "w_v": 0.5},  # Soma = 2.0
    )

    with pytest.raises(ValueError):
        calculate_ihe(request)


def test_rnf03_performance_execution_time_under_10ms():
    """
    Requisito Não Funcional RNF03:
    O processamento do algoritmo de IA e cálculo do IHE deve ocorrer em menos de 10 milissegundos
    (muito abaixo do limite de 1.5s exigido para redes móveis).
    """
    request = IHERequest(
        garment_color=LabColor(L=45.0, a=38.0, b=42.0),
        user_palette="OUTONO_QUENTE",
        user_biotype="AMPULHETA",
        garment_cuts=["ACINTURADO", "VESTIDO_ENVELOPE"],
        garment_formality=0.70,
        occasion="CORPORATIVO",
        temperature_celsius=22.0,
        is_raining=False,
        garment_thermal_category="MEDIO",
        user_style_vector=[0.2, 0.5, 0.8, 0.1, 0.9, 0.4],
        look_style_vector=[0.2, 0.5, 0.8, 0.1, 0.9, 0.4],
    )

    # Warmup
    calculate_ihe(request)

    # Medição de tempo para 100 execuções
    iterations = 100
    start_time = time.perf_counter()
    for _ in range(iterations):
        calculate_ihe(request)
    end_time = time.perf_counter()

    avg_time_ms = ((end_time - start_time) / iterations) * 1000.0

    print(f"\nTempo medio de execucao do IHE: {avg_time_ms:.4f} ms")
    assert avg_time_ms < 10.0, f"Tempo de execucao ({avg_time_ms:.4f} ms) excedeu o limite de 10ms!"
