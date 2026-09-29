"""
Testes do pipeline de visão: extração cromática CIE L*a*b* (RF05) e endpoint de segmentação (RF04).
O modelo de recorte é substituído por um fake para manter os testes rápidos e offline.
"""

import base64
import io
import uuid

import httpx
import numpy as np
import pytest
from httpx import ASGITransport
from PIL import Image

from app.main import app
from app.vision import segmentation
from app.vision.color_extraction import describe_lab, extract_color_centroids, lab_to_hex, srgb_to_lab
from tests.test_api_endpoints import auth_headers, setup_test_environment  # noqa: F401 (fixture autouse)


def rgba_image(regions, size=(40, 40)):
    """Monta uma imagem RGBA (H, W, 4) a partir de faixas horizontais [(altura, (r, g, b, a)), ...]."""
    rows = [np.tile(np.array(color, dtype=np.uint8), (height, size[1], 1)) for height, color in regions]
    return np.concatenate(rows, axis=0)


# -----------------------------------------------------------------------------
# Conversão de espaço de cor
# -----------------------------------------------------------------------------

@pytest.mark.parametrize(
    "rgb, expected_lab",
    [
        ((255, 255, 255), (100.0, 0.0, 0.0)),
        ((0, 0, 0), (0.0, 0.0, 0.0)),
        ((255, 0, 0), (53.24, 80.09, 67.20)),
        ((0, 0, 255), (32.30, 79.19, -107.86)),
        ((163, 72, 54), (42.29, 36.35, 28.95)),  # conferido com colour-science
    ],
)
def test_srgb_to_lab_matches_reference_values(rgb, expected_lab):
    lab = srgb_to_lab(np.array([rgb]))[0]
    assert lab == pytest.approx(expected_lab, abs=0.05)


@pytest.mark.parametrize("hex_code", ["#A34836", "#FBF9F5", "#1A1817", "#4B5842"])
def test_lab_to_hex_round_trip(hex_code):
    rgb = tuple(int(hex_code[i:i + 2], 16) for i in (1, 3, 5))
    L, a, b = srgb_to_lab(np.array([rgb]))[0]
    assert lab_to_hex(L, a, b) == hex_code


@pytest.mark.parametrize(
    "lab, name",
    [
        ((97.0, 0.5, 1.0), "Branco"),
        ((8.0, 0.2, -0.5), "Preto"),
        ((42.3, 36.4, 29.0), "Terracota"),
        ((25.0, 5.0, -30.0), "Marinho"),
        ((38.6, -12.4, 14.8), "Oliva"),
    ],
)
def test_describe_lab_names_common_garment_tones(lab, name):
    assert describe_lab(*lab) == name


# -----------------------------------------------------------------------------
# Extração de centróides
# -----------------------------------------------------------------------------

def test_single_color_garment_yields_one_centroid():
    colors = extract_color_centroids(rgba_image([(40, (163, 72, 54, 255))]))

    assert len(colors) == 1
    assert colors[0].hex == "#A34836"
    assert colors[0].percentage == 100
    assert (colors[0].L, colors[0].a, colors[0].b) == pytest.approx((42.3, 36.3, 29.0), abs=0.05)


def test_two_tone_garment_reports_area_share():
    image = rgba_image([(30, (163, 72, 54, 255)), (10, (26, 24, 23, 255))])
    colors = extract_color_centroids(image)

    assert [c.hex for c in colors] == ["#A34836", "#1A1817"]
    assert [c.percentage for c in colors] == [75, 25]


def test_transparent_background_is_ignored():
    """O fundo removido (alfa 0) e as bordas semitransparentes não contam como cor da peça."""
    image = rgba_image([
        (20, (255, 255, 255, 0)),
        (5, (0, 0, 255, 60)),
        (15, (75, 88, 66, 255)),
    ])
    colors = extract_color_centroids(image)

    assert len(colors) == 1
    assert colors[0].hex == "#4B5842"


def test_near_identical_tones_are_merged_and_noise_dropped():
    """Variações de iluminação viram um tom só; manchas < 3% da área são descartadas."""
    image = rgba_image([
        (20, (163, 72, 54, 255)),
        (19, (168, 76, 58, 255)),
        (1, (0, 120, 255, 255)),
    ], size=(40, 60))
    colors = extract_color_centroids(image)

    assert len(colors) == 1
    assert colors[0].percentage == 100
    assert colors[0].name == "Terracota"


def test_fully_transparent_image_has_no_colors():
    assert extract_color_centroids(rgba_image([(40, (0, 0, 0, 0))])) == []


def test_extraction_is_deterministic():
    rng = np.random.default_rng(7)
    image = np.concatenate([rng.integers(0, 256, (50, 50, 3)), np.full((50, 50, 1), 255)], axis=2).astype(np.uint8)
    assert extract_color_centroids(image) == extract_color_centroids(image)


# -----------------------------------------------------------------------------
# Endpoint POST /api/v1/wardrobe/segment
# -----------------------------------------------------------------------------

def jpeg_bytes(color=(163, 72, 54), size=(80, 60)):
    buffer = io.BytesIO()
    Image.new("RGB", size, color).save(buffer, format="JPEG", quality=95)
    return buffer.getvalue()


@pytest.fixture
def fake_background_removal(monkeypatch):
    """Simula o rembg: mantém o centro da foto opaco e torna a borda transparente."""
    def fake_remove(image):
        rgba = np.array(image.convert("RGBA"))
        rgba[..., 3] = 0
        h, w = rgba.shape[:2]
        rgba[h // 4: 3 * h // 4, w // 4: 3 * w // 4, 3] = 255
        return Image.fromarray(rgba)

    monkeypatch.setattr(segmentation, "remove_background", fake_remove)


async def post_segment(files, headers):
    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        return await client.post("/api/v1/wardrobe/segment", files=files, headers=headers)


@pytest.mark.anyio
async def test_segment_returns_cutout_and_lab_colors(fake_background_removal):
    response = await post_segment(
        {"file": ("peca.jpg", jpeg_bytes(), "image/jpeg")}, auth_headers(uuid.uuid4())
    )

    assert response.status_code == 200
    data = response.json()

    cutout = Image.open(io.BytesIO(base64.b64decode(data["image_png_base64"])))
    assert cutout.format == "PNG" and cutout.mode == "RGBA"
    assert (data["width"], data["height"]) == cutout.size
    # Recortado na caixa da peça (40x30 no centro de uma foto 80x60) + respiro de 12 px por lado
    assert cutout.size == (64, 54)

    assert len(data["colors"]) == 1
    color = data["colors"][0]
    assert color["percentage"] == 100
    assert color["name"] == "Terracota"
    assert (color["L"], color["a"], color["b"]) == pytest.approx((42.3, 36.4, 29.0), abs=1.5)
    assert data["processing_ms"] >= 0


def test_crop_ignores_faint_alpha_residue():
    """Resíduos de alfa quase nulo deixados pelo modelo no fundo não alargam o recorte."""
    rgba = np.zeros((100, 100, 4), dtype=np.uint8)
    rgba[..., 3] = 3                      # névoa residual em todo o fundo
    rgba[40:60, 30:50] = (75, 88, 66, 255)

    cropped = segmentation.crop_to_subject(Image.fromarray(rgba))
    assert cropped.size == (20 + 2 * segmentation.CROP_PADDING, 20 + 2 * segmentation.CROP_PADDING)


@pytest.mark.anyio
async def test_segment_requires_authentication(fake_background_removal):
    response = await post_segment({"file": ("peca.jpg", jpeg_bytes(), "image/jpeg")}, headers={})
    assert response.status_code == 401


@pytest.mark.anyio
async def test_segment_rejects_unsupported_type(fake_background_removal):
    response = await post_segment(
        {"file": ("nota.pdf", b"%PDF-1.7", "application/pdf")}, auth_headers(uuid.uuid4())
    )
    assert response.status_code == 415


@pytest.mark.anyio
async def test_segment_rejects_corrupted_image(fake_background_removal):
    response = await post_segment(
        {"file": ("peca.jpg", b"not really a jpeg", "image/jpeg")}, auth_headers(uuid.uuid4())
    )
    assert response.status_code == 422
    assert response.json()["detail"] == "Arquivo enviado não é uma imagem válida."


@pytest.mark.anyio
async def test_segment_rejects_oversized_upload(fake_background_removal, monkeypatch):
    from app.core.config import settings
    monkeypatch.setattr(settings, "MAX_UPLOAD_BYTES", 100)

    response = await post_segment(
        {"file": ("peca.jpg", jpeg_bytes(), "image/jpeg")}, auth_headers(uuid.uuid4())
    )
    assert response.status_code == 413


@pytest.mark.anyio
async def test_segment_reports_when_no_garment_found(monkeypatch):
    monkeypatch.setattr(
        segmentation, "remove_background", lambda image: Image.new("RGBA", image.size, (0, 0, 0, 0))
    )
    response = await post_segment(
        {"file": ("vazio.jpg", jpeg_bytes(), "image/jpeg")}, auth_headers(uuid.uuid4())
    )
    assert response.status_code == 422
    assert "Nenhuma peça" in response.json()["detail"]
