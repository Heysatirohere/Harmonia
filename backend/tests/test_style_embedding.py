"""
Testes do vetor de estilo da peça (S_cos): pré-processamento do CLIP e normalização.
O modelo real só roda se já estiver em cache (ver STYLE_MODEL_PATH); a suíte nunca baixa nada.
"""

import os

import numpy as np
import pytest
from PIL import Image, ImageDraw

from app.core.config import settings
from app.vision import style_embedding
from app.vision.style_embedding import CLIP_MEAN, CLIP_STD, preprocess


def garment(color, size=(120, 300)):
    """Peça recortada: um retângulo opaco sobre fundo transparente."""
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(image).rectangle((10, 10, size[0] - 10, size[1] - 10), fill=(*color, 255))
    return image


def unnormalize(tensor):
    return (tensor[0].transpose(1, 2, 0) * CLIP_STD + CLIP_MEAN) * 255.0


def test_preprocess_produces_the_clip_input_shape():
    tensor = preprocess(garment((30, 60, 160)))
    assert tensor.shape == (1, 3, 224, 224)
    assert tensor.dtype == np.float32


def test_tall_garment_is_padded_not_cropped():
    """Um vestido longo cabe inteiro: as bordas laterais viram fundo branco, a barra continua lá."""
    pixels = unnormalize(preprocess(garment((30, 60, 160), size=(100, 400))))
    assert pixels[112, 2] == pytest.approx((255, 255, 255), abs=2)      # lateral: fundo
    assert pixels[210, 112] == pytest.approx((30, 60, 160), abs=3)      # perto da barra: ainda é a peça


def test_transparent_background_becomes_catalog_white():
    pixels = unnormalize(preprocess(garment((180, 30, 30))))
    assert pixels[0, 0] == pytest.approx((255, 255, 255), abs=2)


def test_embedding_has_unit_norm(monkeypatch):
    class Session:
        def run(self, outputs, feeds):
            return [np.arange(1, 513, dtype=np.float32)[np.newaxis]]

    monkeypatch.setattr(style_embedding, "_get_session", lambda: Session())
    vector = style_embedding.embed_garment(garment((30, 60, 160)))
    assert len(vector) == 512
    assert float(np.linalg.norm(vector)) == pytest.approx(1.0, abs=1e-4)


def test_missing_model_leaves_the_piece_without_a_vector(monkeypatch):
    def unavailable():
        raise style_embedding.StyleModelUnavailable("sem rede")

    monkeypatch.setattr(style_embedding, "_get_session", unavailable)
    assert style_embedding.try_embed_garment(garment((30, 60, 160))) is None


@pytest.mark.skipif(
    not os.path.exists(os.path.expanduser(settings.STYLE_MODEL_PATH)),
    reason="Modelo de estilo não está em cache; rode a API uma vez ou o build do Docker para baixá-lo",
)
def test_real_model_tells_garments_apart():
    """Com o modelo real: a mesma peça espelhada fica mais perto de si do que de outra cor."""
    blue, red = garment((30, 60, 160)), garment((180, 30, 30))
    v_blue = np.array(style_embedding.embed_garment(blue))
    v_mirror = np.array(style_embedding.embed_garment(blue.transpose(Image.Transpose.FLIP_LEFT_RIGHT)))
    v_red = np.array(style_embedding.embed_garment(red))
    assert len(v_blue) == 512
    assert v_blue @ v_mirror > v_blue @ v_red
