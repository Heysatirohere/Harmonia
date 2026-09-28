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
