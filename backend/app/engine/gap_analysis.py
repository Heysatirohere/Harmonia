"""
Mapeamento Analítico de Lacunas do Acervo (RF11, Seção 3.6.1)

Uma lacuna é uma peça-chave que o usuário não tem e que destravaria looks bons com as
peças que ele já tem. Para cada arquétipo do catálogo de parceiros, o motor monta os
looks que a peça formaria com o acervo (o mesmo caminho da paridade em loja, RF09),
pontua cada um pelo IHE e conta quantos chegam a "Fortemente Recomendado" e quantos
ficam acima da média dos looks possíveis hoje. A régua é relativa ao acervo porque um
guarda-roupa pequeno raramente tem looks de 75%; o que importa é melhorar o que ele tem.
Arquétipos que o acervo já cobre (mesma família e cor perceptualmente próxima) não são lacuna.
"""

from dataclasses import dataclass
from typing import List, Optional

from app.engine.color_science import LabColor, calculate_delta_e
from app.engine.outfit_generator import (
    _categorize_item,
    _looks_with_store_piece,
    _score_combo,
    generate_outfit_recommendations,
)
from app.engine.partner_catalog import GapArchetype, PartnerProduct
from app.engine.style_vector import StyleSpace
from app.models.entities import ClothingItem, User

# Abaixo dessa distância ΔE*ab, uma peça da mesma família já cumpre o papel do arquétipo
OWNED_DELTA_E = 12.0

_PARTNERS_IN_FAMILY = {
    "top": "suas partes de baixo",
    "bottom": "suas partes de cima",
    "shoes": "as peças que você já tem",
    "one_piece": "seus calçados",
}


@dataclass
class WardrobeGap:
    archetype: GapArchetype
    products: List[PartnerProduct]  # só os com estoque (RN03)
    looks_evaluated: int
    strong_looks: int
    good_looks: int  # looks novos com IHE na média do acervo ou acima
    best_ihe_percentage: float
    delta_ihe: float  # pontos percentuais do melhor look novo sobre a média de hoje
    rationale: str


@dataclass
class GapAnalysis:
    baseline_ihe_percentage: Optional[float]  # média dos looks possíveis hoje
    gaps: List[WardrobeGap]


def _archetype_piece(archetype: GapArchetype) -> ClothingItem:
    """Peça transitória do arquétipo: existe só durante o cálculo, nunca entra na sessão."""
    return ClothingItem(
        category=archetype.category,
        subcategory=archetype.title,
        dominant_l=archetype.L,
        dominant_a=archetype.a,
        dominant_b=archetype.b,
        formality_score=archetype.formality,
        cut_type=archetype.cut_type,
    )


def _already_owned(archetype: GapArchetype, items: List[ClothingItem]) -> bool:
    target = LabColor(L=archetype.L, a=archetype.a, b=archetype.b)
    return any(
        _categorize_item(item) == archetype.category
        and calculate_delta_e(LabColor(L=item.dominant_l, a=item.dominant_a, b=item.dominant_b), target) < OWNED_DELTA_E
        for item in items
    )


def _rationale(archetype: GapArchetype, strong_looks: int, good_looks: int, best: float) -> str:
    partners = _PARTNERS_IN_FAMILY.get(archetype.category, "o seu acervo")
    if strong_looks == 1:
        return f"Destrava 1 look fortemente recomendado com {partners}."
    if strong_looks > 1:
        return f"Destrava {strong_looks} looks fortemente recomendados com {partners}."
    looks = "1 look" if good_looks == 1 else f"{good_looks} looks"
    return f"Cria {looks} acima da média do seu acervo com {partners}; o melhor chega a {best:.0f}%."


def analyze_gaps(
    items: List[ClothingItem],
    user: User,
    archetypes: List[GapArchetype],
    occasion: str = "CASUAL",
    temperature_celsius: float = 22.0,
    is_raining: bool = False,
    limit: int = 3,
    style: Optional[StyleSpace] = None,
) -> GapAnalysis:
    """
    Ranqueia as lacunas pelos looks fortemente recomendados que destravam, depois pelos
    looks acima da média do acervo e, no empate, pelo melhor IHE. Uma lacuna só entra
    se cria ao menos um look forte ou um look na média do acervo ou acima.
    """
    if not items:
        return GapAnalysis(baseline_ihe_percentage=None, gaps=[])
    current = generate_outfit_recommendations(
        items, user, occasion, temperature_celsius, is_raining, limit=None, style=style
    )
    baseline = (
        round(sum(look.ihe_result.ihe_percentage for look in current) / len(current), 2) if current else None
    )

    gaps: List[WardrobeGap] = []
    for archetype in archetypes:
        if _already_owned(archetype, items):
            continue
        piece = _archetype_piece(archetype)
        scored = [
            _score_combo(look, user, occasion, temperature_celsius, is_raining, style)
            for look in _looks_with_store_piece(piece, items)
        ]
        if not scored:
            continue
        best = max(look.ihe_result.ihe_percentage for look in scored)
        strong = sum(1 for look in scored if look.ihe_result.is_strongly_recommended)
        good = sum(1 for look in scored if baseline is None or look.ihe_result.ihe_percentage >= baseline)
        if strong == 0 and good == 0:
            continue
        gaps.append(WardrobeGap(
            archetype=archetype,
            products=[p for p in archetype.products if p.in_stock],
            looks_evaluated=len(scored),
            strong_looks=strong,
            good_looks=good,
            best_ihe_percentage=best,
            delta_ihe=round(best - baseline, 1) if baseline is not None else 0.0,
            rationale=_rationale(archetype, strong, good, best),
        ))

    gaps.sort(key=lambda g: (g.strong_looks, g.good_looks, g.best_ihe_percentage), reverse=True)
    return GapAnalysis(baseline_ihe_percentage=baseline, gaps=gaps[:limit])
