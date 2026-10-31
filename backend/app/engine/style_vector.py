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

from dataclasses import dataclass, field
from typing import Any, Dict, Iterable, List, Optional, Sequence

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
    _item_vecs: Dict[Any, np.ndarray] = field(default_factory=dict, repr=False, compare=False)
    _cached_user_vector: Optional[List[float]] = field(default=None, repr=False, compare=False)

    def look_vector(self, items: Iterable[ClothingItem]) -> List[float]:
        """Direção do look em relação ao centro do acervo; nula se nenhuma peça tem vetor."""
        vectors = []
        for i in items:
            vec = self._item_vecs.get(getattr(i, "id", None))
            if vec is not None:
                vectors.append(vec)
            elif _has_embedding(i):
                vectors.append(np.asarray(i.style_embedding, dtype=np.float64))
        if not vectors:
            return NEUTRAL_VECTOR
        return (np.mean(vectors, axis=0) - self.center).tolist()

    def user_vector(self) -> List[float]:
        if self._cached_user_vector is not None:
            return self._cached_user_vector
        return NEUTRAL_VECTOR if self.user_direction is None else self.user_direction.tolist()


def build_style_space(
    items: Sequence[ClothingItem],
    approved_looks: Iterable[Iterable[str]] = (),
    discarded_looks: Iterable[Iterable[str]] = (),
    fallback_user_vector: Optional[Sequence[float]] = None,
) -> Optional[StyleSpace]:
    """
    Monta o espaço de estilo a partir do acervo e do feedback (listas de IDs de peças por look).
    Peças apagadas ou sem vetor são ignoradas. Retorna None com menos de 2 peças com vetor:
    sem um centro com significado, o S_cos fica neutro.
    """
    embedded = {str(i.id): i for i in items if _has_embedding(i)}
    if len(embedded) < 2:
        return None
    item_vecs = {i.id: np.asarray(i.style_embedding, dtype=np.float64) for i in embedded.values()}
    center = np.mean(list(item_vecs.values()), axis=0)
    space = StyleSpace(center=center, user_direction=None, _item_vecs=item_vecs)

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
        if fallback_user_vector is not None and len(fallback_user_vector) == EMBEDDING_DIMENSION:
            fb = np.asarray(fallback_user_vector, dtype=np.float64)
            if np.linalg.norm(fb) >= 1e-9:
                return StyleSpace(
                    center=center,
                    user_direction=fb,
                    _item_vecs=item_vecs,
                    _cached_user_vector=fb.tolist(),
                )
        return space

    direction = np.zeros(EMBEDDING_DIMENSION)
    if liked is not None:
        direction += liked
    if disliked is not None:
        direction -= DISCARD_WEIGHT * disliked
    if np.linalg.norm(direction) < 1e-9:
        return space
    return StyleSpace(
        center=center,
        user_direction=direction,
        _item_vecs=item_vecs,
        _cached_user_vector=direction.tolist(),
    )
