"""
Testes do Teste Assistido de Colorimetria por Selfie (RF02)
"""

import io
import uuid

import httpx
import numpy as np
import pytest
from httpx import ASGITransport
from PIL import Image

from app.engine.color_science import SEASONAL_PALETTES
from app.main import app
from app.vision.colorimetry import FaceNotFoundError, analyze_selfie, choose_palette
from tests.test_api_endpoints import auth_headers, setup_test_environment  # noqa: F401 (fixture autouse)


def selfie(skin, hair, wall=(200, 200, 205)):
    """Rosto chapado no oval central do app, com uma faixa de cabelo em cima."""
    pixels = np.zeros((400, 300, 3), np.uint8)
    pixels[:] = wall
    pixels[40:300, 60:240] = skin
    pixels[30:90, 60:240] = hair
    return Image.fromarray(pixels)


def png(image):
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    return buffer.getvalue()


@pytest.mark.parametrize("skin, hair, palette", [
    ((236, 200, 196), (200, 170, 120), "VERAO_FRIO"),        # clara rosada, cabelo loiro
    ((242, 204, 170), (160, 80, 40), "PRIMAVERA_QUENTE"),     # clara pêssego, cabelo ruivo
    ((236, 205, 200), (25, 20, 20), "INVERNO_FRIO"),          # clara rosada, cabelo preto: coloração profunda
    ((205, 150, 105), (70, 45, 30), "OUTONO_QUENTE"),         # média dourada, cabelo castanho
    ((105, 72, 68), (12, 12, 14), "INVERNO_ESCURO"),          # escura fria, cabelo preto
])
def test_selfie_lands_on_the_expected_season(skin, hair, palette):
    assert analyze_selfie(selfie(skin, hair)).palette == palette


def test_analysis_reports_undertone_depth_and_intensity():
    result = analyze_selfie(selfie((242, 204, 170), (160, 80, 40)))

    assert (result.undertone, result.depth) == ("QUENTE", "CLARA")
    assert result.hue > 50
    assert result.hex.startswith("#")
    assert result.contrast > 0


def test_fair_skin_with_black_hair_is_deep_coloring():
    """A profundidade é da coloração inteira: o cabelo preto puxa a pele clara para o Inverno."""
    result = analyze_selfie(selfie((236, 205, 200), (25, 20, 20)))

    assert result.depth == "PROFUNDA"
    assert result.palette.startswith("INVERNO")


def test_photo_without_a_face_in_the_oval_is_refused():
    with pytest.raises(FaceNotFoundError):
        analyze_selfie(Image.new("RGB", (300, 400), (40, 90, 160)))


@pytest.mark.parametrize("hue, lightness, chroma, contrast, palette", [
    (70, 75, 22, 35, "PRIMAVERA_QUENTE"),   # o calor domina
    (52, 80, 22, 35, "PRIMAVERA_CLARA"),    # a claridade domina
    (55, 62, 40, 60, "PRIMAVERA_BRILHANTE"),
    (55, 58, 10, 10, "OUTONO_SUAVE"),       # a suavidade domina
    (52, 35, 22, 35, "OUTONO_ESCURO"),
    (30, 66, 22, 35, "VERAO_FRIO"),
    (46, 66, 8, 5, "VERAO_SUAVE"),
    (46, 82, 22, 35, "VERAO_CLARO"),
    (46, 52, 40, 70, "INVERNO_BRILHANTE"),
    (46, 30, 22, 35, "INVERNO_ESCURO"),
])
def test_dominant_trait_picks_the_variant(hue, lightness, chroma, contrast, palette):
    assert choose_palette(hue, lightness, chroma, contrast) == palette


def test_spring_never_gets_a_soft_variant():
    """Primavera não tem variante suave: com a suavidade dominante, vale o próximo traço."""
    assert choose_palette(52, 62, 8, 5) in {"PRIMAVERA_QUENTE", "PRIMAVERA_CLARA"}


def test_every_suggested_palette_exists_in_the_engine():
    for hue in range(0, 90, 6):
        for lightness in range(20, 95, 10):
            for chroma in (8, 22, 40):
                assert choose_palette(hue, lightness, chroma, 35) in SEASONAL_PALETTES


async def post_selfie(content, content_type="image/png", headers=None):
    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        return await client.post(
            "/api/v1/users/me/colorimetry",
            files={"file": ("selfie.png", content, content_type)},
            headers=headers if headers is not None else auth_headers(uuid.uuid4()),
        )


@pytest.mark.anyio
async def test_endpoint_suggests_a_palette_without_saving_anything():
    response = await post_selfie(png(selfie((242, 204, 170), (160, 80, 40))))

    assert response.status_code == 200
    data = response.json()
    assert data["palette"] == "PRIMAVERA_QUENTE"
    assert (data["undertone"], data["depth"]) == ("QUENTE", "CLARA")
    assert data["skin_hex"].startswith("#")


@pytest.mark.anyio
async def test_endpoint_explains_when_the_face_is_not_in_the_oval():
    response = await post_selfie(png(Image.new("RGB", (300, 400), (40, 90, 160))))

    assert response.status_code == 422
    assert "oval" in response.json()["detail"]


@pytest.mark.anyio
async def test_endpoint_rejects_other_file_types_and_anonymous_calls():
    assert (await post_selfie(b"%PDF", "application/pdf")).status_code == 415
    assert (await post_selfie(png(selfie((242, 204, 170), (160, 80, 40))), headers={})).status_code == 401
