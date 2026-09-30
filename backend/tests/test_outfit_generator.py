"""
Testes Unitários do Motor Combinatório de Looks (RF07)
Valida a separação taxonômica das peças, geração de candidatos e ranqueamento pelo IHE.
"""

import uuid
from app.models.entities import ClothingItem, User
from app.engine.outfit_generator import generate_outfit_recommendations


def test_generate_outfit_recommendations_ranks_and_filters():
    user = User(
        id=uuid.uuid4(),
        email="fashion.tester@harmonia.app",
        hashed_password="hash",
        body_shape="AMPULHETA",
        seasonal_palette="OUTONO_QUENTE",
        style_vector=[0.1] * 512,
        is_premium=False,
    )

    # Criando peças mock
    top1 = ClothingItem(
        id=uuid.uuid4(),
        user_id=user.id,
        category="top",
        subcategory="Camisa Linho",
        image_url="https://example.com/top1.png",
        dominant_l=58.0,
        dominant_a=28.0,
        dominant_b=24.0,
        formality_score=0.70,
        cut_type="acinturado",
        style_embedding=[0.1] * 512,
    )

    bottom1 = ClothingItem(
        id=uuid.uuid4(),
        user_id=user.id,
        category="bottom",
        subcategory="Calça Alfaiataria",
        image_url="https://example.com/bottom1.png",
        dominant_l=30.0,
        dominant_a=5.0,
        dominant_b=10.0,
        formality_score=0.75,
        cut_type="reta",
        style_embedding=[0.1] * 512,
    )

    shoes1 = ClothingItem(
        id=uuid.uuid4(),
        user_id=user.id,
        category="shoes",
        subcategory="Mule de Couro",
        image_url="https://example.com/shoes1.png",
        dominant_l=35.0,
        dominant_a=10.0,
        dominant_b=15.0,
        formality_score=0.70,
        cut_type=None,
        style_embedding=[0.1] * 512,
    )

    items = [top1, bottom1, shoes1]

    recommendations = generate_outfit_recommendations(
        items=items,
        user=user,
        occasion="CASUAL",
        temperature_celsius=22.0,
        is_raining=False,
        limit=3,
    )

    assert len(recommendations) >= 1
    best = recommendations[0]
    assert len(best.items) == 3
    assert best.ihe_result.ihe_score > 0.0
    assert best.ihe_result.ihe_percentage > 0.0
    assert best.styling_advice != ""


def _app_item(category, name):
    """Peça exatamente como o app Flutter cadastra (categoria em português, nome na subcategoria)."""
    return ClothingItem(
        id=uuid.uuid4(),
        user_id=uuid.uuid4(),
        category=category,
        subcategory=name,
        image_url="https://example.supabase.co/storage/v1/object/public/wardrobe-items/garments/x.png",
        dominant_l=50.0,
        dominant_a=10.0,
        dominant_b=10.0,
        formality_score=0.5,
        is_archived=False,
    )


def test_app_categories_map_to_outfit_slots():
    """As categorias exibidas no app caem nas famílias certas do motor combinatório."""
    from app.engine.outfit_generator import _categorize_item

    assert _categorize_item(_app_item("Partes de cima", "Nova Peça do Acervo")) == "top"
    assert _categorize_item(_app_item("Partes de baixo", "Nova Peça do Acervo")) == "bottom"
    assert _categorize_item(_app_item("Calçados", "Nova Peça do Acervo")) == "shoes"
    assert _categorize_item(_app_item("Peças únicas", "Nova Peça do Acervo")) == "one_piece"


def test_app_wardrobe_generates_complete_looks():
    """Um acervo cadastrado pelo app gera looks superior + inferior + calçado e peça única + calçado."""
    user = User(id=uuid.uuid4(), email="app@harmonia.app", hashed_password="x", is_premium=True)
    top = _app_item("Partes de cima", "Camisa de Linho")
    bottom = _app_item("Partes de baixo", "Calça Pantalona")
    shoes = _app_item("Calçados", "Mule")
    dress = _app_item("Peças únicas", "Vestido Midi")

    looks = generate_outfit_recommendations([top, bottom, shoes, dress], user, limit=10)
    compositions = {frozenset(item.id for item in look.items) for look in looks}

    assert compositions == {
        frozenset({top.id, bottom.id, shoes.id}),
        frozenset({dress.id, shoes.id}),
    }


# -----------------------------------------------------------------------------
# Paridade de peça em loja (RF08, RF09)
# -----------------------------------------------------------------------------

from app.engine.outfit_generator import rank_store_parity


def _parity_user():
    return User(
        id=uuid.uuid4(),
        email="parity@harmonia.app",
        hashed_password="hash",
        body_shape="AMPULHETA",
        seasonal_palette="OUTONO_QUENTE",
    )


def _piece(user, category, l_value, a_value=20.0, b_value=20.0):
    return ClothingItem(
        id=uuid.uuid4(),
        user_id=user.id,
        category=category,
        image_url=f"https://example.com/{category}.png",
        dominant_l=l_value,
        dominant_a=a_value,
        dominant_b=b_value,
        formality_score=0.3,
    )


def test_store_top_is_ranked_against_home_bottoms():
    user = _parity_user()
    warm_bottom = _piece(user, "Partes de baixo", 45.0, 30.0, 30.0)
    cold_bottom = _piece(user, "Partes de baixo", 85.0, -30.0, -40.0)
    shoes = _piece(user, "Calçados", 30.0)
    other_top = _piece(user, "Partes de cima", 50.0)
    store_top = ClothingItem(category="Partes de cima", dominant_l=48.0, dominant_a=30.0, dominant_b=28.0, formality_score=0.3)

    parity = rank_store_parity(store_top, [warm_bottom, cold_bottom, shoes, other_top], user)

    ranked_ids = [m.item.id for m in parity.matches]
    # Outra parte de cima não combina com uma parte de cima da loja
    assert other_top.id not in ranked_ids
    assert set(ranked_ids) == {warm_bottom.id, cold_bottom.id, shoes.id}
    assert ranked_ids.index(warm_bottom.id) < ranked_ids.index(cold_bottom.id)
    # Todo look avaliado contém a peça da loja e só peças do acervo além dela
    assert parity.looks_evaluated == 2
    assert parity.best_look is not None and store_top in parity.best_look.items
    scores = [m.best_look.ihe_result.ihe_score for m in parity.matches]
    assert scores == sorted(scores, reverse=True)


def test_store_shoes_pair_with_complete_outfits():
    user = _parity_user()
    top = _piece(user, "Partes de cima", 55.0)
    bottom = _piece(user, "Partes de baixo", 40.0)
    dress = _piece(user, "Peças únicas", 50.0)
    store_shoes = ClothingItem(category="Calçados", dominant_l=35.0, dominant_a=15.0, dominant_b=20.0, formality_score=0.3)

    parity = rank_store_parity(store_shoes, [top, bottom, dress], user)

    assert parity.looks_evaluated == 2  # parte de cima + parte de baixo, e o vestido
    assert {m.item.id for m in parity.matches} == {top.id, bottom.id, dress.id}


def test_store_parity_without_matching_pieces_is_empty():
    user = _parity_user()
    store_top = ClothingItem(category="Partes de cima", dominant_l=50.0, dominant_a=0.0, dominant_b=0.0, formality_score=0.5)

    parity = rank_store_parity(store_top, [_piece(user, "Partes de cima", 50.0)], user)

    assert parity.best_look is None
    assert parity.matches == []
    assert parity.looks_evaluated == 0
