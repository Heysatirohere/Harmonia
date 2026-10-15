"""
Testes dos Atributos Sugeridos (RF05): categoria, nome com estampa e formalidade pelo CLIP
"""

import numpy as np
import pytest

from app.vision import garment_attributes as ga

DIM = 512
N_GARMENTS, N_PATTERNS = len(ga.GARMENT_LABELS), len(ga.PATTERN_LABELS)


def basis(i):
    v = np.zeros(DIM)
    v[i] = 1.0
    return v


# Rótulos de peça nos eixos 0..20, de estampa nos eixos seguintes: cada rótulo isolado no seu eixo
VECTORS = {
    "garment": np.stack([basis(i) for i in range(N_GARMENTS)]),
    "pattern": np.stack([basis(N_GARMENTS + i) for i in range(N_PATTERNS)]),
}


def index(key, labels):
    return next(i for i, label in enumerate(labels) if label.key == key)


def piece(garment, pattern=None):
    v = basis(index(garment, ga.GARMENT_LABELS))
    if pattern:
        v = v + basis(N_GARMENTS + index(pattern, ga.PATTERN_LABELS))
    return v


def test_clear_piece_gets_category_name_with_pattern_and_formality():
    attrs = ga.classify(piece("shirt", "striped"), VECTORS)

    assert attrs.category == "Partes de cima"
    assert attrs.name == "Camisa com listras"
    assert attrs.pattern == "striped"
    assert attrs.formality == pytest.approx(0.6, abs=0.01)
    assert attrs.category_confidence > 0.99


def test_solid_piece_keeps_the_plain_name():
    attrs = ga.classify(piece("skirt", "solid"), VECTORS)

    assert (attrs.category, attrs.name, attrs.pattern) == ("Partes de baixo", "Saia", "solid")


def test_unclear_pattern_is_left_out_of_the_name():
    attrs = ga.classify(piece("dress"), VECTORS)

    assert attrs.name == "Vestido"
    assert attrs.pattern is None


def test_family_confidence_adds_up_its_labels():
    """Dividida entre camiseta e camisa, a peça ainda é uma parte de cima com certeza."""
    v = basis(index("tshirt", ga.GARMENT_LABELS)) + basis(index("shirt", ga.GARMENT_LABELS))

    attrs = ga.classify(v, VECTORS)

    assert attrs.category == "Partes de cima"
    assert attrs.category_confidence > 0.99


def test_ambiguous_piece_gets_no_category_or_name():
    """Entre parte de cima e calçado na mesma medida, sugerir seria chute."""
    v = basis(index("shirt", ga.GARMENT_LABELS)) + basis(index("sneakers", ga.GARMENT_LABELS))

    attrs = ga.classify(v, VECTORS)

    assert attrs.category is None
    assert attrs.name is None
    assert attrs.category_confidence == pytest.approx(0.5, abs=0.01)


def test_null_vector_gives_no_suggestion():
    assert ga.classify(np.zeros(DIM), VECTORS) is None


def test_without_the_label_file_there_is_no_suggestion(monkeypatch):
    monkeypatch.setattr(ga, "_label_vectors", lambda: None)

    assert ga.classify(piece("shirt")) is None


def test_shipped_label_file_matches_the_label_table():
    """Mudou um rótulo? Rode scripts/build_garment_labels.py: sem isso a API para de sugerir."""
    vectors = ga._label_vectors()

    assert vectors is not None
    assert vectors["garment"].shape == (N_GARMENTS, DIM)
    assert vectors["pattern"].shape == (N_PATTERNS, DIM)
    assert np.allclose(np.linalg.norm(vectors["garment"], axis=1), 1.0, atol=1e-4)


def test_every_family_maps_to_an_app_category():
    assert {label.family for label in ga.GARMENT_LABELS} == set(ga.APP_CATEGORIES)
