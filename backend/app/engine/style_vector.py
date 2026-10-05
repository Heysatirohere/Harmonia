"""
Espaço de Estilo do Usuário para o pilar S_cos (Seção 5.3) e a retroalimentação (RF13)

Os vetores do CLIP de quaisquer duas roupas já são parecidos (cosseno bruto de 0,8 a 0,9),
porque todos compartilham o componente "peça de roupa". Comparar vetores crus deixaria o
S_cos sempre alto e sem poder de decisão. Por isso tudo é medido em relação ao centro do
acervo do usuário (a média dos vetores das peças dele):

    look  = média dos vetores das peças do look − centro
    u     = média(looks aprovados) − DISCARD_WEIGHT · média(looks descartados)
    S_cos = cos(u, look), levado de [−1, 1] para [0, 1]

Assim um look que vai na direção do que o usuário aprova sobe, um que lembra o que ele
descarta desce, e sem histórico (u nulo) o S_cos fica neutro em 0,5.
"""

from dataclasses import dataclass
from typing import Iterable, List, Optional, Sequence

import numpy as np

from app.models.entities import ClothingItem

EMBEDDING_DIMENSION = 512
# Descartes pesam menos que aprovações: descartar diz "hoje não", aprovar diz "isso sou eu"
DISCARD_WEIGHT = 0.5
NEUTRAL_VECTOR: List[float] = [0.0] * EMBEDDING_DIMENSION


def _has_embedding(item: ClothingItem) -> bool:
    return item.style_embedding is not None and len(item.style_embedding) == EMBEDDING_DIMENSION


@dataclass(frozen=True)
class StyleSpace:
    center: np.ndarray
    user_direction: Optional[np.ndarray]

    def look_vector(self, items: Iterable[ClothingItem]) -> List[float]:
        """Direção do look em relação ao centro do acervo; nula se nenhuma peça tem vetor."""
        vectors = [np.asarray(i.style_embedding, dtype=np.float64) for i in items if _has_embedding(i)]
        if not vectors:
            return NEUTRAL_VECTOR
        return (np.mean(vectors, axis=0) - self.center).tolist()

    def user_vector(self) -> List[float]:
        return NEUTRAL_VECTOR if self.user_direction is None else self.user_direction.tolist()


def build_style_space(
    items: Sequence[ClothingItem],
    approved_looks: Iterable[Iterable[str]],
    discarded_looks: Iterable[Iterable[str]],
) -> Optional[StyleSpace]:
    """
    Monta o espaço de estilo a partir do acervo e do feedback (listas de IDs de peças por look).
    Peças apagadas ou sem vetor são ignoradas. Retorna None com menos de 2 peças com vetor:
    sem um centro com significado, o S_cos fica neutro.
    """
    embedded = {str(i.id): i for i in items if _has_embedding(i)}
    if len(embedded) < 2:
        return None
    center = np.mean([np.asarray(i.style_embedding, dtype=np.float64) for i in embedded.values()], axis=0)
    space = StyleSpace(center=center, user_direction=None)

    def mean_direction(looks: Iterable[Iterable[str]]) -> Optional[np.ndarray]:
        directions = []
        for look in looks:
            pieces = [embedded[str(item_id)] for item_id in look if str(item_id) in embedded]
            if pieces:
                directions.append(np.asarray(space.look_vector(pieces)))
        return np.mean(directions, axis=0) if directions else None

    liked = mean_direction(approved_looks)
    disliked = mean_direction(discarded_looks)
    if liked is None and disliked is None:
        return space

    direction = np.zeros(EMBEDDING_DIMENSION)
    if liked is not None:
        direction += liked
    if disliked is not None:
        direction -= DISCARD_WEIGHT * disliked
    if np.linalg.norm(direction) < 1e-9:
        return space
    return StyleSpace(center=center, user_direction=direction)
