"""
Cota Freemium diária de combinações por IA (RN02)

O contador vale para um dia no fuso QUOTA_TIMEZONE e volta a zero no dia seguinte.
Só consultas novas gastam cota: a geração é determinística, então repetir a mesma
consulta (mesma ocasião, clima, acervo e perfil) devolve os mesmos looks sem custo.
"""

import hashlib
from datetime import date, datetime
from typing import Iterable
from zoneinfo import ZoneInfo

from app.core.config import settings
from app.models.entities import User


def quota_today() -> date:
    return datetime.now(ZoneInfo(settings.QUOTA_TIMEZONE)).date()


def sync_daily_counter(user: User, today: date | None = None) -> None:
    """Zera o contador quando ele pertence a outro dia."""
    today = today or quota_today()
    if user.looks_counter_date != today:
        user.looks_generated_today = 0
        user.looks_signatures_today = []
        user.looks_counter_date = today


def has_reached_look_limit(user: User) -> bool:
    return not user.is_premium and user.looks_generated_today >= settings.FREEMIUM_MAX_DAILY_LOOKS


def look_request_signature(user: User, item_ids: Iterable[object], *parts: object) -> str:
    """Identifica uma consulta pelo perfil, pelas peças ativas e pelos parâmetros pedidos."""
    raw = "|".join(
        [str(user.body_shape), str(user.seasonal_palette), ",".join(sorted(str(i) for i in item_ids))]
        + [str(p) for p in parts]
    )
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()[:16]


def was_charged_today(user: User, signature: str) -> bool:
    return signature in (user.looks_signatures_today or [])


def charge_look(user: User, signature: str | None = None) -> None:
    """Gasta uma combinação da cota do dia, registrando a consulta quando houver assinatura."""
    user.looks_generated_today += 1
    if signature is not None:
        # Nova lista para o SQLAlchemy detectar a mudança na coluna JSONB
        user.looks_signatures_today = [*(user.looks_signatures_today or []), signature]
