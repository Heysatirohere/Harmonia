"""
Atributos Sugeridos da Peça: categoria, nome com estampa e formalidade (RF05, Seção 3.1.3)

Classificação zero-shot com o próprio CLIP do vetor de estilo: o vetor da peça (já calculado
no recorte) é comparado com vetores de texto de rótulos fixos. Os vetores de texto vêm do
codificador de texto da MESMA revisão do CLIP e ficam em `garment_labels.npz`, gerado uma vez
por `scripts/build_garment_labels.py`; a API não baixa nem roda o modelo de texto.

O resultado é sugestão: o app preenche o formulário e a pessoa confirma ou corrige.
Sem confiança suficiente, o atributo volta nulo e o campo fica para a pessoa escolher.
"""

import os
from dataclasses import dataclass
from functools import lru_cache
from typing import Dict, List, Optional, Sequence, Tuple

import numpy as np

LABELS_PATH = os.path.join(os.path.dirname(__file__), "garment_labels.npz")

# Escala de logit do CLIP: transforma cossenos próximos em probabilidades separadas
LOGIT_SCALE = 100.0

# Abaixo destes limites, a sugestão erraria demais para valer o preenchimento
MIN_CATEGORY_CONFIDENCE = 0.6
MIN_NAME_CONFIDENCE = 0.35
MIN_PATTERN_CONFIDENCE = 0.5

# Família do motor -> categoria exibida no app
APP_CATEGORIES = {
    "top": "Partes de cima",
    "bottom": "Partes de baixo",
    "shoes": "Calçados",
    "one_piece": "Peças únicas",
}

# Frases em que cada peça é descrita para o CLIP
PROMPT_TEMPLATES = ("a photo of {}.", "a product photo of {} on a white background.")


@dataclass(frozen=True)
class GarmentLabel:
    key: str
    name: str  # nome sugerido em português
    family: str  # top, bottom, shoes, one_piece
    formality: float  # formalidade típica (0 casual, 1 formal)
    prompts: Tuple[str, ...]


@dataclass(frozen=True)
class PatternLabel:
    key: str
    suffix: str  # complemento do nome, invariável em gênero; vazio para peça lisa
    prompts: Tuple[str, ...]


GARMENT_LABELS: Tuple[GarmentLabel, ...] = (
    GarmentLabel("tshirt", "Camiseta", "top", 0.15, ("a t-shirt",)),
    GarmentLabel("shirt", "Camisa", "top", 0.6, ("a button-up shirt",)),
    GarmentLabel("blouse", "Blusa", "top", 0.45, ("a blouse",)),
    GarmentLabel("sweater", "Suéter", "top", 0.35, ("a sweater", "a knit pullover")),
    GarmentLabel("tanktop", "Regata", "top", 0.15, ("a tank top",)),
    GarmentLabel("blazer", "Blazer", "top", 0.85, ("a blazer", "a suit jacket")),
    GarmentLabel("jacket", "Jaqueta", "top", 0.35, ("a jacket", "a coat")),
    GarmentLabel("hoodie", "Moletom", "top", 0.1, ("a hoodie", "a sweatshirt")),
    GarmentLabel("jersey", "Camisa de time", "top", 0.1, ("a sports jersey", "a football shirt")),
    GarmentLabel("jeans", "Calça jeans", "bottom", 0.3, ("a pair of jeans",)),
    GarmentLabel("trousers", "Calça de alfaiataria", "bottom", 0.75, ("a pair of tailored trousers", "dress pants")),
    GarmentLabel("pants", "Calça", "bottom", 0.4, ("a pair of pants",)),
    GarmentLabel("shorts", "Shorts", "bottom", 0.1, ("a pair of shorts",)),
    GarmentLabel("skirt", "Saia", "bottom", 0.5, ("a skirt",)),
    GarmentLabel("sneakers", "Tênis", "shoes", 0.15, ("a pair of sneakers",)),
    GarmentLabel("dress_shoes", "Sapato social", "shoes", 0.85, ("a pair of leather dress shoes", "a pair of loafers")),
    GarmentLabel("boots", "Bota", "shoes", 0.5, ("a pair of boots",)),
    GarmentLabel("sandals", "Sandália", "shoes", 0.3, ("a pair of sandals",)),
    GarmentLabel("heels", "Salto alto", "shoes", 0.8, ("a pair of high heels",)),
    GarmentLabel("dress", "Vestido", "one_piece", 0.6, ("a dress", "a long flowing dress", "a midi dress")),
    # "jumpsuit" sozinho atrai qualquer foto de corpo inteiro; as pernas de calça desfazem a confusão
    GarmentLabel("jumpsuit", "Macacão", "one_piece", 0.45, ("a one-piece jumpsuit with trouser legs",)),
)

PATTERN_LABELS: Tuple[PatternLabel, ...] = (
    PatternLabel("solid", "", ("a plain solid color garment",)),
    PatternLabel("striped", "com listras", ("a striped garment",)),
    PatternLabel("plaid", "xadrez", ("a plaid garment", "a checkered garment")),
    PatternLabel("floral", "floral", ("a garment with a floral print",)),
    PatternLabel("polka", "de poá", ("a polka dot garment",)),
    PatternLabel("animal", "animal print", ("a garment with a leopard print",)),
    PatternLabel("graphic", "estampada", ("a garment with a graphic print", "a printed shirt with a logo")),
)


@dataclass(frozen=True)
class GarmentAttributes:
    category: Optional[str]  # categoria do app; nula sem confiança
    category_confidence: float
    name: Optional[str]  # ex: "Camisa com listras"; nulo sem confiança
    pattern: Optional[str]  # chave da estampa; nula sem confiança
    formality: float  # média das formalidades típicas, pesada pela probabilidade


@lru_cache(maxsize=1)
def _label_vectors() -> Optional[Dict[str, np.ndarray]]:
    """Vetores de texto dos rótulos; None se o arquivo não existir ou estiver fora de sincronia."""
    if not os.path.exists(LABELS_PATH):
        return None
    data = np.load(LABELS_PATH)
    if list(data["garment_keys"]) != [g.key for g in GARMENT_LABELS] or list(data["pattern_keys"]) != [
        p.key for p in PATTERN_LABELS
    ]:
        # Rótulo novo sem regenerar o arquivo: melhor não sugerir do que sugerir trocado
        return None
    return {"garment": data["garment_vectors"], "pattern": data["pattern_vectors"]}


def _softmax(vectors: np.ndarray, embedding: np.ndarray) -> np.ndarray:
    logits = LOGIT_SCALE * (vectors @ embedding)
    weights = np.exp(logits - logits.max())
    return weights / weights.sum()


def classify(embedding: Sequence[float], vectors: Optional[Dict[str, np.ndarray]] = None) -> Optional[GarmentAttributes]:
    """Atributos sugeridos para o vetor de estilo da peça (512d); None sem os vetores de rótulo."""
    vectors = vectors if vectors is not None else _label_vectors()
    if vectors is None:
        return None
    image = np.asarray(embedding, dtype=np.float64)
    norm = np.linalg.norm(image)
    if norm < 1e-9:
        return None
    image = image / norm

    garment_probs = _softmax(vectors["garment"], image)
    family_probs: Dict[str, float] = {}
    for label, prob in zip(GARMENT_LABELS, garment_probs):
        family_probs[label.family] = family_probs.get(label.family, 0.0) + float(prob)
    family, family_conf = max(family_probs.items(), key=lambda kv: kv[1])

    best = int(np.argmax(garment_probs))
    pattern_probs = _softmax(vectors["pattern"], image)
    best_pattern = int(np.argmax(pattern_probs))
    pattern = PATTERN_LABELS[best_pattern] if pattern_probs[best_pattern] >= MIN_PATTERN_CONFIDENCE else None

    name = None
    if garment_probs[best] >= MIN_NAME_CONFIDENCE and GARMENT_LABELS[best].family == family:
        name = GARMENT_LABELS[best].name
        if pattern and pattern.suffix:
            name = f"{name} {pattern.suffix}"

    formality = float(sum(p * g.formality for p, g in zip(garment_probs, GARMENT_LABELS)))
    confident = family_conf >= MIN_CATEGORY_CONFIDENCE
    return GarmentAttributes(
        category=APP_CATEGORIES[family] if confident else None,
        category_confidence=round(family_conf, 3),
        name=name if confident else None,
        pattern=pattern.key if pattern else None,
        formality=round(formality, 2),
    )


def all_prompts() -> Tuple[List[List[str]], List[List[str]]]:
    """Frases de cada rótulo, na ordem do arquivo de vetores (usado pelo script de geração)."""
    expand = lambda prompts: [t.format(p) for p in prompts for t in PROMPT_TEMPLATES]
    return [expand(g.prompts) for g in GARMENT_LABELS], [expand(p.prompts) for p in PATTERN_LABELS]
