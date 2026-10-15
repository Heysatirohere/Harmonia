"""
Remoção Automática de Fundo por Segmentação de Imagem (RF04, Seção 3.1.2)

Isola a peça em PNG com canal alfa usando o rembg (modelos ONNX em CPU).
O modelo é carregado uma única vez por processo, na primeira chamada.
"""

import io
import threading

from PIL import Image, ImageOps

from app.core.config import settings

MAX_INPUT_SIDE = 1024   # Reduz a foto antes da inferência para cumprir o RNF03 (≤ 3,5 s)
CROP_PADDING = 12       # Respiro em pixels ao recortar a caixa da peça
CROP_ALPHA_MIN = 16     # O modelo deixa resíduos de alfa quase nulo no fundo; não contam para o corte

_session = None
_session_lock = threading.Lock()


class InvalidImageError(ValueError):
    """Os bytes enviados não são uma imagem decodificável."""


def _get_session():
    global _session
    if _session is None:
        with _session_lock:
            if _session is None:
                from rembg import new_session  # Import tardio: onnxruntime é pesado
                _session = new_session(settings.SEGMENTATION_MODEL)
    return _session


def load_image(data: bytes) -> Image.Image:
    """Decodifica a foto, aplica a orientação EXIF da câmera e limita a resolução."""
    try:
        image = Image.open(io.BytesIO(data))
        image = ImageOps.exif_transpose(image)
        image = image.convert("RGB")
    except Exception as exc:
        raise InvalidImageError("Arquivo enviado não é uma imagem válida.") from exc

    image.thumbnail((MAX_INPUT_SIDE, MAX_INPUT_SIDE), Image.Resampling.LANCZOS)
    return image


def remove_background(image: Image.Image) -> Image.Image:
    """Retorna a peça em RGBA com fundo transparente."""
    from rembg import remove

    return remove(image, session=_get_session()).convert("RGBA")


def crop_to_subject(rgba: Image.Image) -> Image.Image:
    """Recorta a imagem na caixa delimitadora dos pixels visíveis, com um pequeno respiro."""
    bbox = rgba.getchannel("A").point(lambda v: 255 if v >= CROP_ALPHA_MIN else 0).getbbox()
    if bbox is None:
        return rgba
    left, top, right, bottom = bbox
    return rgba.crop((
        max(0, left - CROP_PADDING),
        max(0, top - CROP_PADDING),
        min(rgba.width, right + CROP_PADDING),
        min(rgba.height, bottom + CROP_PADDING),
    ))


def encode_png(rgba: Image.Image) -> bytes:
    buffer = io.BytesIO()
    rgba.save(buffer, format="PNG", optimize=True)
    return buffer.getvalue()
