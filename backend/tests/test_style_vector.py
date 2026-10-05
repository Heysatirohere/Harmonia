"""
Testes do espaço de estilo (S_cos, Seção 5.3) e da retroalimentação pelo feedback (RF13).
Vetores sintéticos: um eixo comum forte ("é uma roupa") mais um eixo de estilo por peça.
"""

import uuid

import numpy as np
import pytest

from app.engine.ihe_calculator import calculate_s_cos
from app.engine.style_vector import DISCARD_WEIGHT, NEUTRAL_VECTOR, build_style_space
from app.models.entities import ClothingItem


def vec(style_axis, strength=0.3):
    """Vetor de norma 1 dominado pelo eixo comum 0, como os vetores reais do CLIP."""
    v = np.zeros(512)
    v[0] = 1.0
    v[style_axis] = strength
    return (v / np.linalg.norm(v)).tolist()


def item(style_axis=None):
    return ClothingItem(
        id=uuid.uuid4(),
        category="top",
        dominant_l=50.0,
        dominant_a=0.0,
        dominant_b=0.0,
        formality_score=0.5,
        style_embedding=vec(style_axis) if style_axis is not None else None,
    )


def look(*pieces):
    return frozenset(str(p.id) for p in pieces)


def s_cos(space, *pieces):
    return calculate_s_cos(space.user_vector(), space.look_vector(pieces))


def test_raw_clip_like_vectors_are_all_similar():
    """O problema que a centralização resolve: peças diferentes já têm cosseno bruto alto."""
    assert float(np.dot(vec(1), vec(2))) > 0.9


def test_without_history_s_cos_is_neutral():
    a, b = item(1), item(2)
    space = build_style_space([a, b], approved_looks=[], discarded_looks=[])
    assert space.user_vector() == NEUTRAL_VECTOR
    assert s_cos(space, a) == 0.5


def test_needs_two_embedded_pieces_for_a_meaningful_center():
    assert build_style_space([item(1), item()], [], []) is None


def test_pieces_without_vector_do_not_move_the_look():
    a, b, plain = item(1), item(2), item()
    space = build_style_space([a, b, plain], [look(a)], [])
    assert space.look_vector([plain]) == NEUTRAL_VECTOR
    assert space.look_vector([a, plain]) == space.look_vector([a])


def test_approving_pulls_similar_looks_up_and_others_down():
    minimal, minimal_2, boho, boho_2 = item(1), item(1), item(2), item(2)
    space = build_style_space([minimal, minimal_2, boho, boho_2], approved_looks=[look(minimal)], discarded_looks=[])

    assert s_cos(space, minimal_2) > 0.9      # mesmo estilo do que foi aprovado
    assert s_cos(space, boho_2) < 0.1         # estilo oposto, relativo ao centro do acervo


def test_discarding_pushes_similar_looks_down():
    minimal, minimal_2, boho, boho_2 = item(1), item(1), item(2), item(2)
    space = build_style_space([minimal, minimal_2, boho, boho_2], approved_looks=[], discarded_looks=[look(boho)])

    assert s_cos(space, boho_2) < 0.1
    assert s_cos(space, minimal_2) > 0.9


def test_approvals_weigh_more_than_discards():
    a, b, c = item(1), item(2), item(3)
    space = build_style_space([a, b, c], approved_looks=[look(a)], discarded_looks=[look(b)])
    center = space.center
    liked = np.asarray(vec(1)) - center
    disliked = np.asarray(vec(2)) - center
    assert space.user_vector() == pytest.approx((liked - DISCARD_WEIGHT * disliked).tolist())


def test_deleted_pieces_in_old_feedback_are_ignored():
    a, b = item(1), item(2)
    ghost = str(uuid.uuid4())
    space = build_style_space([a, b], approved_looks=[frozenset({ghost})], discarded_looks=[])
    assert space.user_vector() == NEUTRAL_VECTOR


@pytest.mark.parametrize("cos, expected", [(1.0, 1.0), (0.1, 0.55), (0.0, 0.5), (-0.1, 0.45), (-1.0, 0.0)])
def test_s_cos_mapping_preserves_order(cos, expected):
    """(cos + 1) / 2: um look levemente oposto nunca pontua acima de um levemente alinhado."""
    u = [1.0, 0.0]
    v = [cos, float(np.sqrt(max(0.0, 1 - cos * cos)))]
    assert calculate_s_cos(u, v) == pytest.approx(expected, abs=1e-6)
