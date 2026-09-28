"""
Motor de Geração e Combinação Automática de Looks por IHE (RF07)
Conforme Seção 3.3 e 5.3 da Documentação do HarmonIA (FECAP - Ciência da Computação).

Varre o acervo de peças ativas do usuário, compõe combinações candidatas
(Superior + Inferior + Calçado ou Peça Única + Calçado) e ranqueia as opções
em tempo real pela fórmula determinística multivariada do IHE.
"""

from typing import List, Dict, Any, Optional
import itertools
from dataclasses import dataclass

from app.models.entities import ClothingItem, User
from app.engine.color_science import LabColor
from app.engine.ihe_calculator import calculate_ihe, IHERequest, IHEResponse


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
    "one_piece", "vestido", "macacao", "macacão", "vestidos", "macacões"
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


def generate_outfit_recommendations(
    items: List[ClothingItem],
    user: User,
    occasion: str = "CASUAL",
    temperature_celsius: float = 22.0,
    is_raining: bool = False,
    limit: int = 5,
) -> List[CandidateOutfit]:
    """
    Gera as melhores combinações de looks a partir do acervo do usuário,
    ranqueando as opções pela pontuação do IHE.
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

    user_palette = user.seasonal_palette or "OUTONO_QUENTE"
    user_biotype = user.body_shape or "AMPULHETA"
    user_vec = user.style_vector or [0.0] * 512

    scored_candidates: List[CandidateOutfit] = []

    # 4. Avaliar cada combinação candidata pelo IHE
    for combo in candidates_raw:
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

        # Vetor de estilo médio do look
        vectors_with_data = [i.style_embedding for i in combo if i.style_embedding]
        if vectors_with_data:
            look_vec = [
                sum(v[dim] for v in vectors_with_data) / len(vectors_with_data)
                for dim in range(512)
            ]
        else:
            look_vec = [0.0] * 512

        ihe_req = IHERequest(
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
        )

        ihe_res = calculate_ihe(ihe_req)
        advice = _generate_styling_advice(ihe_res, occasion)

        scored_candidates.append(
            CandidateOutfit(
                items=combo,
                ihe_result=ihe_res,
                styling_advice=advice,
            )
        )

    # 5. Ordenar decrescente pelo score do IHE
    scored_candidates.sort(key=lambda c: c.ihe_result.ihe_score, reverse=True)

    return scored_candidates[:limit]
