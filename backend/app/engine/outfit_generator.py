"""
Motor de Geração e Combinação Automática de Looks por IHE (RF07)
Conforme Seção 3.3 e 5.3 da Documentação do HarmonIA (FECAP - Ciência da Computação).

Varre o acervo de peças ativas do usuário, compõe combinações candidatas
(Superior + Inferior + Calçado ou Peça Única + Calçado) e ranqueia as opções
em tempo real pela fórmula determinística multivariada do IHE.
"""

from typing import List, Dict, Any, FrozenSet, Optional, Set
import itertools
from dataclasses import dataclass

from app.models.entities import ClothingItem, User
from app.engine.color_science import LabColor
from app.engine.ihe_calculator import calculate_ihe, IHERequest, IHEResponse
from app.engine.style_vector import StyleSpace, NEUTRAL_VECTOR


TOP_CATEGORIES = {
    "top", "tops", "shirt", "camisa", "sobrecamisa", "blusa",
    "camiseta", "regata", "partes de cima", "parte de cima"
}

BOTTOM_CATEGORIES = {
    "bottom", "bottoms", "pants", "calca", "calça", "saia",
    "bermuda", "shorts", "short", "partes de baixo", "parte de baixo"
}

SHOES_CATEGORIES = {
    "shoes", "shoe", "calcado", "calçado", "sapato", "tenis",
    "tênis", "mule", "sandalia", "sandália", "bota", "calçados"
}

ONE_PIECE_CATEGORIES = {
    "one_piece", "vestido", "macacao", "macacão", "vestidos", "macacões",
    "peças únicas", "peça única", "pecas unicas", "peca unica"
}


@dataclass
class CandidateOutfit:
    items: List[ClothingItem]
    ihe_result: IHEResponse
    styling_advice: str


def _categorize_item(item: ClothingItem) -> str:
    """Classifica o item em uma família canônica para combinação."""
    cat = (item.category or "").strip().lower()
    sub = (item.subcategory or "").strip().lower()

    if cat in TOP_CATEGORIES or sub in TOP_CATEGORIES:
        return "top"
    if cat in BOTTOM_CATEGORIES or sub in BOTTOM_CATEGORIES:
        return "bottom"
    if cat in SHOES_CATEGORIES or sub in SHOES_CATEGORIES:
        return "shoes"
    if cat in ONE_PIECE_CATEGORIES or sub in ONE_PIECE_CATEGORIES:
        return "one_piece"
    
    # Fallback por inferência
    if "camis" in cat or "top" in cat or "blus" in cat:
        return "top"
    if "calc" in cat or "calç" in cat or "sai" in cat or "short" in cat:
        return "bottom"
    if "sapat" in cat or "tenis" in cat or "tênis" in cat or "mule" in cat or "bota" in cat:
        return "shoes"
    if "vestid" in cat or "macac" in cat:
        return "one_piece"

    return "top"


def _generate_styling_advice(ihe: IHEResponse, occasion: str) -> str:
    """Gera uma recomendação editorial personalizada com base nos pilares do IHE."""
    highlights = []
    if ihe.s_cor >= 0.80:
        highlights.append("harmonia cromática de alto contraste favorável à sua cartela")
    elif ihe.s_cor >= 0.65:
        highlights.append("sintonia tonal suave")

    if ihe.s_bio >= 0.80:
        highlights.append("compensação de silhueta perfeitamente alinhada ao seu biótipo")

    if ihe.s_ocasion >= 0.85:
        highlights.append(f"adequação precisa para evento {occasion.lower()}")

    if ihe.is_strongly_recommended:
        base = "✦ Look Fortemente Recomendado: "
    else:
        base = "Coordenação Equilibrada: "

    if highlights:
        return base + "Destaque para " + " e ".join(highlights) + "."
    return base + "Composição versátil e confortável para o clima do dia."


def temperature_band(temperature_celsius: float) -> str:
    """
    Faixa de temperatura que o motor distingue: o IHE só muda ao cruzar 15°C
    (context_rules), 16°C ou 25°C (categoria térmica abaixo). Temperaturas na
    mesma faixa geram exatamente os mesmos looks.
    """
    if temperature_celsius < 15:
        return "FRIO"
    if temperature_celsius < 16:
        return "FRESCO"
    if temperature_celsius <= 25:
        return "AMENO"
    return "QUENTE"


def _score_combo(
    combo: List[ClothingItem],
    user: User,
    occasion: str,
    temperature_celsius: float,
    is_raining: bool,
    style: Optional[StyleSpace] = None,
) -> CandidateOutfit:
    """
    Calcula o IHE de um look a partir das peças, do perfil do usuário e do contexto.
    Sem espaço de estilo (acervo sem vetores ou usuário sem histórico), o S_cos fica neutro.
    """
    user_palette = user.seasonal_palette or "OUTONO_QUENTE"
    user_biotype = user.body_shape or "AMPULHETA"

    avg_l = sum(i.dominant_l for i in combo) / len(combo)
    avg_a = sum(i.dominant_a for i in combo) / len(combo)
    avg_b = sum(i.dominant_b for i in combo) / len(combo)
    garment_color = LabColor(L=avg_l, a=avg_a, b=avg_b)

    avg_formality = sum(i.formality_score for i in combo) / len(combo)
    cuts = [i.cut_type for i in combo if i.cut_type]

    # Determinar categoria térmica
    if temperature_celsius < 16:
        thermal = "PESADO"
    elif temperature_celsius > 25:
        thermal = "LEVE"
    else:
        thermal = "MEDIO"

    # Direções de estilo do usuário e do look, relativas ao centro do acervo (S_cos)
    user_vec = style.user_vector() if style else NEUTRAL_VECTOR
    look_vec = style.look_vector(combo) if style else NEUTRAL_VECTOR

    ihe_res = calculate_ihe(IHERequest(
        garment_color=garment_color,
        user_palette=user_palette,
        user_biotype=user_biotype,
        garment_cuts=cuts,
        garment_formality=round(avg_formality, 2),
        occasion=occasion,
        temperature_celsius=temperature_celsius,
        is_raining=is_raining,
        garment_thermal_category=thermal,
        user_style_vector=user_vec,
        look_style_vector=look_vec,
    ))
    return CandidateOutfit(
        items=combo,
        ihe_result=ihe_res,
        styling_advice=_generate_styling_advice(ihe_res, occasion),
    )


def generate_outfit_recommendations(
    items: List[ClothingItem],
    user: User,
    occasion: str = "CASUAL",
    temperature_celsius: float = 22.0,
    is_raining: bool = False,
    limit: Optional[int] = 5,
    excluded_looks: Optional[Set[FrozenSet[str]]] = None,
    style: Optional[StyleSpace] = None,
) -> List[CandidateOutfit]:
    """
    Gera as melhores combinações de looks a partir do acervo do usuário,
    ranqueando as opções pela pontuação do IHE (`limit=None` devolve todas).
    Looks em `excluded_looks` (conjuntos de IDs descartados pelo usuário, RF13) nunca voltam;
    `style` aproxima o ranking do que o usuário aprovou e o afasta do que descartou.
    """
    if not items:
        return []

    # 1. Separar itens por categorias
    buckets: Dict[str, List[ClothingItem]] = {
        "top": [],
        "bottom": [],
        "shoes": [],
        "one_piece": [],
    }

    for item in items:
        cat = _categorize_item(item)
        if cat in buckets:
            buckets[cat].append(item)

    candidates_raw: List[List[ClothingItem]] = []

    # 2. Gerar combinações Top + Bottom + Shoes
    if buckets["top"] and buckets["bottom"]:
        tops_slice = buckets["top"][:15]
        bottoms_slice = buckets["bottom"][:15]
        shoes_slice = buckets["shoes"][:10] if buckets["shoes"] else [None]

        for t, b in itertools.product(tops_slice, bottoms_slice):
            for s in shoes_slice:
                combo = [t, b]
                if s is not None:
                    combo.append(s)
                candidates_raw.append(combo)

    # 3. Gerar combinações One-Piece + Shoes
    if buckets["one_piece"]:
        op_slice = buckets["one_piece"][:10]
        shoes_slice = buckets["shoes"][:10] if buckets["shoes"] else [None]

        for op in op_slice:
            for s in shoes_slice:
                combo = [op]
                if s is not None:
                    combo.append(s)
                candidates_raw.append(combo)

    # Se não houver combinações completas, criar looks parciais com o que estiver disponível
    if not candidates_raw and len(items) >= 2:
        for pair in itertools.combinations(items[:10], 2):
            candidates_raw.append(list(pair))
    elif not candidates_raw and len(items) == 1:
        candidates_raw.append([items[0]])

    # Retroalimentação (RF13): combinações descartadas saem antes do ranking
    if excluded_looks:
        candidates_raw = [
            combo for combo in candidates_raw
            if frozenset(str(i.id) for i in combo) not in excluded_looks
        ]

    # 4. Avaliar cada combinação candidata pelo IHE
    scored_candidates = [
        _score_combo(combo, user, occasion, temperature_celsius, is_raining, style)
        for combo in candidates_raw
    ]

    # 5. Ordenar decrescente pelo score do IHE
    scored_candidates.sort(key=lambda c: c.ihe_result.ihe_score, reverse=True)

    return scored_candidates[:limit]


# -----------------------------------------------------------------------------
# Paridade de peça em loja com o acervo (RF08, RF09)
# -----------------------------------------------------------------------------

@dataclass
class ParityMatch:
    """Peça do acervo e o melhor look que ela forma com a peça da loja."""
    item: ClothingItem
    best_look: CandidateOutfit


@dataclass
class StoreParity:
    best_look: Optional[CandidateOutfit]
    matches: List[ParityMatch]
    looks_evaluated: int
    strong_looks: int


def _looks_with_store_piece(store_item: ClothingItem, items: List[ClothingItem]) -> List[List[ClothingItem]]:
    """Looks completos que incluem a peça da loja, montados com as peças do acervo."""
    buckets: Dict[str, List[ClothingItem]] = {"top": [], "bottom": [], "shoes": [], "one_piece": []}
    for item in items:
        buckets[_categorize_item(item)].append(item)

    shoes: List[Optional[ClothingItem]] = list(buckets["shoes"][:10]) or [None]

    def with_shoes(base: List[ClothingItem]) -> List[List[ClothingItem]]:
        return [base + [s] if s is not None else base for s in shoes]

    family = _categorize_item(store_item)
    looks: List[List[ClothingItem]] = []
    if family == "top":
        for bottom in buckets["bottom"][:15]:
            looks.extend(with_shoes([store_item, bottom]))
    elif family == "bottom":
        for top in buckets["top"][:15]:
            looks.extend(with_shoes([top, store_item]))
    elif family == "one_piece":
        looks.extend(with_shoes([store_item]))
    else:  # calçado
        for top, bottom in itertools.product(buckets["top"][:10], buckets["bottom"][:10]):
            looks.append([top, bottom, store_item])
        for piece in buckets["one_piece"][:10]:
            looks.append([piece, store_item])
    # Uma peça única sozinha não compara nada com o acervo
    return [look for look in looks if len(look) > 1]


def rank_store_parity(
    store_item: ClothingItem,
    items: List[ClothingItem],
    user: User,
    occasion: str = "CASUAL",
    temperature_celsius: float = 22.0,
    is_raining: bool = False,
    limit: int = 5,
    style: Optional[StyleSpace] = None,
) -> StoreParity:
    """
    Ranqueia as peças do acervo pela paridade com uma peça vista na loja (RF09):
    cada peça vale o IHE do melhor look que forma junto com a peça da loja.
    """
    scored = [
        _score_combo(look, user, occasion, temperature_celsius, is_raining, style)
        for look in _looks_with_store_piece(store_item, items)
    ]
    scored.sort(key=lambda c: c.ihe_result.ihe_score, reverse=True)

    best_by_item: Dict[Any, CandidateOutfit] = {}
    for look in scored:  # em ordem decrescente: o primeiro look de cada peça é o melhor
        for piece in look.items:
            if piece is not store_item and piece.id not in best_by_item:
                best_by_item[piece.id] = look

    by_id = {item.id: item for item in items}
    matches = [ParityMatch(item=by_id[item_id], best_look=look) for item_id, look in best_by_item.items()]
    matches.sort(key=lambda m: m.best_look.ihe_result.ihe_score, reverse=True)

    return StoreParity(
        best_look=scored[0] if scored else None,
        matches=matches[:limit],
        looks_evaluated=len(scored),
        strong_looks=sum(1 for look in scored if look.ihe_result.is_strongly_recommended),
    )
