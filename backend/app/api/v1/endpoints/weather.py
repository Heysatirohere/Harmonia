"""
Endpoint de Telemetria Climática para o Motor Contextual S_ocasion (RF07, Seção 5.3)
Consome a API pública Open-Meteo com cache em memória (15 min) e fallback resiliente.
"""

import time
from typing import Dict, Optional, Tuple

import httpx
from fastapi import APIRouter, Query, status

from app.schemas.dtos import WeatherResponse

router = APIRouter()

OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"
CACHE_TTL_SECONDS = 900.0  # 15 minutos

_WEATHER_CACHE: Dict[Tuple[float, float], Tuple[float, dict]] = {}

RAIN_WEATHER_CODES = {
    51, 53, 55, 56, 57,
    61, 63, 65, 66, 67,
    80, 81, 82,
    95, 96, 99,
}

CONDITION_LABELS = {
    0: "Céu limpo",
    1: "Predominantemente limpo",
    2: "Parcialmente nublado",
    3: "Nublado",
    45: "Neblina",
    48: "Nevoeiro",
    51: "Garoa leve",
    53: "Garoa moderada",
    55: "Garoa intensa",
    61: "Chuva leve",
    63: "Chuva moderada",
    65: "Chuva forte",
    80: "Pancadas de chuva leves",
    81: "Pancadas de chuva moderadas",
    82: "Pancadas de chuva fortes",
    95: "Tempestade",
}


def _thermal_recommendation(temperature_celsius: float, is_raining: bool) -> str:
    if is_raining and temperature_celsius < 24.0:
        return "IMPERMEAVEL"
    if temperature_celsius < 16.0:
        return "PESADO"
    if temperature_celsius > 25.0:
        return "LEVE"
    return "MEDIO"


async def _fetch_open_meteo(latitude: float, longitude: float) -> Optional[dict]:
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "current": "temperature_2m,precipitation,rain,weather_code",
        "timezone": "auto",
    }
    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            resp = await client.get(OPEN_METEO_URL, params=params)
            resp.raise_for_status()
            data = resp.json()
            current = data.get("current") or {}
            temp = float(current.get("temperature_2m", 22.0))
            precip = float(current.get("precipitation", 0.0) or 0.0)
            rain = float(current.get("rain", 0.0) or 0.0)
            code = int(current.get("weather_code", 0) or 0)
            is_raining = precip > 0.1 or rain > 0.0 or code in RAIN_WEATHER_CODES
            return {
                "temperature_celsius": round(temp, 1),
                "is_raining": is_raining,
                "weather_code": code,
                "condition_label": CONDITION_LABELS.get(code, "Chuva" if is_raining else "Clima ameno"),
                "thermal_recommendation": _thermal_recommendation(temp, is_raining),
            }
    except Exception:
        return None


@router.get("", response_model=WeatherResponse, status_code=status.HTTP_200_OK)
async def get_local_weather(
    latitude: float = Query(default=-23.5505, ge=-90.0, le=90.0, description="Latitude local"),
    longitude: float = Query(default=-46.6333, ge=-180.0, le=180.0, description="Longitude local"),
    location_name: Optional[str] = Query(default=None, max_length=120, description="Nome opcional da localidade"),
):
    """
    Obtém temperatura real e indicativo de chuva para calibrar o pilar S_ocasion do IHE.
    Em caso de indisponibilidade de rede, retorna fallback seguro (22°C, sem chuva).
    """
    key = (round(latitude, 2), round(longitude, 2))
    now = time.monotonic()
    cached = _WEATHER_CACHE.get(key)
    if cached and (now - cached[0]) < CACHE_TTL_SECONDS:
        payload = cached[1]
    else:
        fetched = await _fetch_open_meteo(latitude, longitude)
        if fetched is not None:
            _WEATHER_CACHE[key] = (now, fetched)
            payload = fetched
        else:
            payload = {
                "temperature_celsius": 22.0,
                "is_raining": False,
                "weather_code": 0,
                "condition_label": "Clima ameno",
                "thermal_recommendation": "MEDIO",
            }
    return WeatherResponse(**payload, location_name=location_name)
