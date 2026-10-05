"""
Saúde do Acervo: rotação, ociosidade e proporção cromática (Seção 3.2.2 da Documentação)

O uso de uma peça vem das aprovações de looks (RF13): cada look aprovado conta um uso
para cada peça dele, na data da aprovação. Peças nunca usadas contam a ociosidade a
partir do cadastro, para que uma peça recém-chegada não apareça como esquecida.
"""

import math
from dataclasses import dataclass
from datetime import datetime
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

# Janelas de ociosidade da documentação (30, 60 e 90 dias)
ACTIVE_WINDOW_DAYS = 30
IDLE_60_DAYS = 60
DORMANT_DAYS = 90

# Abaixo deste croma (C*ab) a cor é lida como neutra
NEUTRAL_CHROMA = 10.0

# Famílias cromáticas por ângulo de matiz h*ab (graus), na ordem do círculo
HUE_FAMILIES: Sequence[Tuple[float, float, str]] = (
    (15.0, 40.0, "Vermelhos e vinhos"),
    (40.0, 75.0, "Laranjas e terracotas"),
    (75.0, 110.0, "Amarelos e ocres"),
    (110.0, 200.0, "Verdes"),
    # No L*a*b* o azul vai longe: marinho e azul puro ficam perto de 306°
    (200.0, 315.0, "Azuis"),
    (315.0, 345.0, "Roxos e ameixas"),
)
PINK_FAMILY = "Rosas"


@dataclass(frozen=True)
class GarmentUsage:
    """Uso de uma peça: quantas vezes foi aprovada num look e quando foi a última."""
    wear_count: int
    last_worn_at: Optional[datetime]
    days_idle: int


@dataclass(frozen=True)
class ColorShare:
    family: str
    count: int
    percentage: float
    mean_lab: Tuple[float, float, float]


def color_family(l: float, a: float, b: float) -> str:
    """Nome da família cromática de uma cor L*a*b*, pela luminosidade, croma e matiz."""
    chroma = math.hypot(a, b)
    if chroma < NEUTRAL_CHROMA:
        if l < 30.0:
            return "Pretos e carvão"
        if l < 70.0:
            return "Cinzas"
        return "Brancos e off-white"

    hue = math.degrees(math.atan2(b, a)) % 360.0
    # Tons quentes pouco saturados são os neutros de tecido: bege claro e marrom escuro
    if 30.0 <= hue < 110.0 and chroma < 35.0:
        return "Bege e areia" if l >= 60.0 else "Terrosos e marrons"
    for start, end, name in HUE_FAMILIES:
        if start <= hue < end:
            return name
    return PINK_FAMILY


def garment_usage(
    created_at: datetime,
    approvals: Iterable[datetime],
    now: datetime,
) -> GarmentUsage:
    """Uso de uma peça a partir das datas em que looks com ela foram aprovados."""
    dates = list(approvals)
    last_worn = max(dates) if dates else None
    reference = last_worn or created_at
    return GarmentUsage(
        wear_count=len(dates),
        last_worn_at=last_worn,
        days_idle=max(0, (now - reference).days),
    )


def rotation_bucket(days_idle: int) -> str:
    """'active' (<30d), 'idle_30' (30–60d), 'idle_60' (60–90d) ou 'dormant' (>=90d)."""
    if days_idle < ACTIVE_WINDOW_DAYS:
        return "active"
    if days_idle < IDLE_60_DAYS:
        return "idle_30"
    if days_idle < DORMANT_DAYS:
        return "idle_60"
    return "dormant"


def color_distribution(colors: Sequence[Tuple[float, float, float]]) -> List[ColorShare]:
    """Proporção de peças por família cromática, da mais frequente para a menos, com a cor média de cada uma."""
    if not colors:
        return []
    groups: Dict[str, List[Tuple[float, float, float]]] = {}
    for lab in colors:
        groups.setdefault(color_family(*lab), []).append(lab)

    total = len(colors)
    shares = [
        ColorShare(
            family=family,
            count=len(members),
            percentage=round(len(members) / total * 100.0, 1),
            mean_lab=tuple(round(sum(c[i] for c in members) / len(members), 1) for i in range(3)),
        )
        for family, members in groups.items()
    ]
    return sorted(shares, key=lambda s: (-s.count, s.family))
