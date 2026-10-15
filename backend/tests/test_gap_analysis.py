"""
Testes do Mapeamento de Lacunas do Acervo (RF11) e dos links de afiliação (RF12, RN03)
"""

import uuid
from urllib.parse import parse_qs, urlparse

import pytest

from app.engine.gap_analysis import analyze_gaps
from app.engine.partner_catalog import GapArchetype, PartnerProduct, StaticPartnerCatalog, partner_search_url
from app.models.entities import ClothingItem, User


def _user():
    return User(
        id=uuid.uuid4(),
        email="gaps@harmonia.app",
        hashed_password="hash",
        body_shape="AMPULHETA",
        seasonal_palette="OUTONO_QUENTE",
        is_premium=False,
    )


def _item(category, L, a, b, formality=0.4):
    return ClothingItem(
        id=uuid.uuid4(),
        category=category,
        image_url=f"https://example.com/{category}.png",
        dominant_l=L,
        dominant_a=a,
        dominant_b=b,
        formality_score=formality,
    )


def _archetype(id, category, L=48.0, a=34.0, b=36.0, products=None):
    return GapArchetype(
        id=id, title=id, category=category, L=L, a=a, b=b, formality=0.3, cut_type="ACINTURADO",
        products=products or [PartnerProduct(f"{id}-p", "RENNER", id, id, L, a, b)],
    )


CATALOG = StaticPartnerCatalog().archetypes()


def test_only_pieces_that_combine_with_the_wardrobe_are_gaps():
    """Só partes de cima no acervo: só uma parte de baixo forma looks com elas."""
    items = [_item("top", 60.0, 15.0, 18.0), _item("top", 90.0, 1.0, 6.0)]

    analysis = analyze_gaps(items, _user(), CATALOG, limit=10)

    assert analysis.gaps
    assert {gap.archetype.category for gap in analysis.gaps} == {"bottom"}
    assert analysis.baseline_ihe_percentage is not None  # pares parciais ainda pontuam


def test_archetype_already_in_the_wardrobe_is_not_a_gap():
    jeans = next(a for a in CATALOG if a.id == "jeans-reto-medio")
    items = [_item("top", 60.0, 15.0, 18.0), _item("bottom", jeans.L + 2, jeans.a, jeans.b + 3)]

    analysis = analyze_gaps(items, _user(), CATALOG, limit=10)

    assert "jeans-reto-medio" not in {gap.archetype.id for gap in analysis.gaps}


def test_same_color_in_another_family_does_not_cover_the_gap():
    """Uma camisa caramelo não substitui a pantalona caramelo."""
    target = _archetype("pantalona", "bottom", L=55.0, a=14.0, b=34.0)
    items = [_item("top", 55.0, 14.0, 34.0)]

    analysis = analyze_gaps(items, _user(), [target], limit=10)

    assert [gap.archetype.id for gap in analysis.gaps] == ["pantalona"]


def test_out_of_stock_products_never_reach_the_gap_rn03():
    target = _archetype("blusa", "top", products=[
        PartnerProduct("em-estoque", "CEA", "Blusa", "blusa", 48.0, 34.0, 36.0),
        PartnerProduct("esgotado", "RENNER", "Blusa", "blusa", 48.0, 34.0, 36.0, in_stock=False),
    ])
    items = [_item("bottom", 35.0, 15.0, 18.0)]

    [gap] = analyze_gaps(items, _user(), [target]).gaps

    assert [p.id for p in gap.products] == ["em-estoque"]


def test_empty_wardrobe_has_no_gaps():
    analysis = analyze_gaps([], _user(), CATALOG)

    assert analysis.gaps == []
    assert analysis.baseline_ihe_percentage is None


def test_gaps_are_ranked_by_strong_then_above_average_looks():
    items = [
        _item("top", 60.0, 15.0, 18.0),
        _item("top", 45.0, 38.0, 42.0),
        _item("bottom", 42.0, -18.0, 28.0),
        _item("shoes", 40.0, 12.0, 20.0),
    ]

    gaps = analyze_gaps(items, _user(), CATALOG, limit=10).gaps

    assert gaps
    keys = [(g.strong_looks, g.good_looks, g.best_ihe_percentage) for g in gaps]
    assert keys == sorted(keys, reverse=True)
    for gap in gaps:
        assert gap.strong_looks > 0 or gap.good_looks > 0
        assert gap.rationale
        assert 0 < gap.best_ihe_percentage <= 100


def test_gap_value_is_measured_against_the_wardrobe_average():
    """Looks contam quando ficam na média dos looks de hoje ou acima; o delta parte dessa média."""
    items = [_item("top", 60.0, 15.0, 18.0), _item("top", 45.0, 38.0, 42.0), _item("bottom", 42.0, -18.0, 28.0)]

    analysis = analyze_gaps(items, _user(), CATALOG, limit=10)

    assert analysis.baseline_ihe_percentage is not None
    for gap in analysis.gaps:
        assert gap.good_looks <= gap.looks_evaluated
        assert gap.delta_ihe == round(gap.best_ihe_percentage - analysis.baseline_ihe_percentage, 1)
        assert gap.delta_ihe >= 0


def test_limit_caps_the_number_of_gaps():
    items = [_item("top", 60.0, 15.0, 18.0), _item("bottom", 35.0, 15.0, 18.0)]

    assert len(analyze_gaps(items, _user(), CATALOG, limit=2).gaps) <= 2


@pytest.mark.parametrize("store, host", [("RENNER", "www.lojasrenner.com.br"), ("CEA", "www.cea.com.br")])
def test_partner_link_searches_the_store_with_affiliate_utm(store, host):
    url = urlparse(partner_search_url(store, "calça jeans reta", "jeans-reto-medio"))
    query = parse_qs(url.query)

    assert url.scheme == "https" and url.netloc == host
    assert query["utm_source"] == ["harmonia"]
    assert query["utm_campaign"] == ["lacunas_acervo"]
    assert query["utm_content"] == ["jeans-reto-medio"]
    assert "calça jeans reta" in (query.get("Ntt") or query.get("_q"))


def test_unknown_partner_is_rejected():
    with pytest.raises(ValueError):
        partner_search_url("AMAZON", "camisa", "gap")


def test_every_catalog_archetype_has_a_valid_family_and_partner():
    for archetype in CATALOG:
        assert archetype.category in {"top", "bottom", "shoes", "one_piece"}
        assert archetype.products
        for product in archetype.products:
            partner_search_url(product.store, product.search_query, archetype.id)
