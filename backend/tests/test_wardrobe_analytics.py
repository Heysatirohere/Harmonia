"""
Testes do motor de Saúde do Acervo (Seção 3.2.2): uso, janelas de ociosidade e famílias cromáticas.
"""

from datetime import datetime, timedelta, timezone

import pytest

from app.engine.wardrobe_analytics import (
    color_distribution,
    color_family,
    garment_usage,
    rotation_bucket,
)

NOW = datetime(2026, 10, 5, 12, 0, tzinfo=timezone.utc)


def days_ago(n):
    return NOW - timedelta(days=n)


def test_usage_counts_approvals_and_keeps_the_latest():
    usage = garment_usage(days_ago(200), [days_ago(40), days_ago(3), days_ago(90)], NOW)
    assert usage.wear_count == 3
    assert usage.last_worn_at == days_ago(3)
    assert usage.days_idle == 3


def test_never_worn_piece_counts_idleness_from_registration():
    """Uma peça recém-cadastrada não é uma peça esquecida."""
    usage = garment_usage(days_ago(12), [], NOW)
    assert usage.wear_count == 0
    assert usage.last_worn_at is None
    assert usage.days_idle == 12


@pytest.mark.parametrize(
    "days, bucket",
    [(0, "active"), (29, "active"), (30, "idle_30"), (59, "idle_30"), (60, "idle_60"), (89, "idle_60"), (90, "dormant"), (400, "dormant")],
)
def test_rotation_windows_follow_30_60_90_days(days, bucket):
    assert rotation_bucket(days) == bucket


@pytest.mark.parametrize(
    "lab, family",
    [
        ((2.7, 0.0, 0.0), "Pretos e carvão"),
        ((53.6, 0.0, 0.0), "Cinzas"),
        ((98.2, -0.3, 1.0), "Brancos e off-white"),
        ((13.0, 47.5, -64.7), "Azuis"),  # marinho: h ≈ 306° no L*a*b*
        ((41.5, 14.0, -54.9), "Azuis"),  # jeans
        ((46.7, 70.1, 49.8), "Vermelhos e vinhos"),
        ((25.8, 48.9, 21.3), "Vermelhos e vinhos"),  # vinho
        ((50.2, 38.0, 35.9), "Laranjas e terracotas"),  # terracota
        ((73.5, 6.9, 76.3), "Amarelos e ocres"),  # mostarda
        ((46.2, -51.7, 49.9), "Verdes"),
        ((29.8, 58.9, -36.5), "Roxos e ameixas"),
        ((65.5, 64.2, -10.6), "Rosas"),
        ((81.1, 3.0, 26.1), "Bege e areia"),
        ((94.7, -1.7, 10.3), "Bege e areia"),  # creme
        ((31.6, 10.9, 26.2), "Terrosos e marrons"),
    ],
)
def test_color_family_names_common_garment_colors(lab, family):
    assert color_family(*lab) == family


def test_color_distribution_orders_by_share_and_averages_each_family():
    navy, denim, black = (13.0, 47.5, -64.7), (41.5, 14.0, -54.9), (2.7, 0.0, 0.0)
    shares = color_distribution([navy, denim, black, denim])
    assert [s.family for s in shares] == ["Azuis", "Pretos e carvão"]
    blues = shares[0]
    assert blues.count == 3
    assert blues.percentage == 75.0
    assert blues.mean_lab == (32.0, 25.2, -58.2)
    assert sum(s.percentage for s in shares) == 100.0


def test_empty_wardrobe_has_no_colors():
    assert color_distribution([]) == []
