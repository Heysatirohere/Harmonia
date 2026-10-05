"""
Vetor de Estilo da Peça (S_cos, Seção 5.3)

Codifica a peça recortada num vetor de 512 dimensões com o codificador visual do CLIP
ViT-B/32 (OpenAI, licença MIT), exportado em ONNX e executado no onnxruntime que o
rembg já usa, sem PyTorch. A versão completa (fp32) é usada de propósito: a quantizada
desviava até 0,17 de cosseno e só economizava ~12 ms por imagem.

O modelo é baixado uma vez (no build do Docker ou no primeiro uso), conferido pelo
SHA-256 e carregado uma única vez por processo.
"""

import hashlib
import logging
import os
import threading
from typing import List, Optional

import numpy as np
from PIL import Image

from app.core.config import settings

logger = logging.getLogger(__name__)

EMBEDDING_DIMENSION = 512
INPUT_SIDE = 224
# Pré-processamento do CLIP (preprocessor_config.json do modelo)
CLIP_MEAN = np.array([0.48145466, 0.4578275, 0.40821073], dtype=np.float32)
CLIP_STD = np.array([0.26862954, 0.26130258, 0.27577711], dtype=np.float32)
# Fundo de catálogo: a peça de casa e a da loja são vistas sobre o mesmo branco
BACKGROUND = (255, 255, 255)

_session = None
_session_lock = threading.Lock()


class StyleModelUnavailable(RuntimeError):
    """O modelo não pôde ser baixado ou carregado; a peça segue sem vetor de estilo."""


def _download_model(path: str) -> None:
    import httpx  # Só no primeiro uso, fora do Docker

    os.makedirs(os.path.dirname(path), exist_ok=True)
    partial = f"{path}.part"
    digest = hashlib.sha256()
    try:
        with httpx.stream("GET", settings.STYLE_MODEL_URL, follow_redirects=True, timeout=120.0) as response:
            response.raise_for_status()
            with open(partial, "wb") as out:
                for chunk in response.iter_bytes(1 << 20):
                    out.write(chunk)
                    digest.update(chunk)
    except (httpx.HTTPError, OSError) as exc:
        raise StyleModelUnavailable(f"Falha ao baixar o modelo de estilo: {exc}") from exc
    if digest.hexdigest() != settings.STYLE_MODEL_SHA256:
        os.remove(partial)
        raise StyleModelUnavailable("O modelo de estilo baixado não confere com o SHA-256 esperado.")
    os.replace(partial, path)


def _get_session():
    global _session
    if _session is None:
        with _session_lock:
            if _session is None:
                path = os.path.expanduser(settings.STYLE_MODEL_PATH)
                if not os.path.exists(path):
                    logger.info("Baixando o modelo de estilo para %s", path)
                    _download_model(path)
                import onnxruntime as ort  # Import tardio: onnxruntime é pesado

                try:
                    _session = ort.InferenceSession(path, providers=["CPUExecutionProvider"])
                except Exception as exc:
                    raise StyleModelUnavailable(f"Falha ao carregar o modelo de estilo: {exc}") from exc
    return _session


def preprocess(cutout: Image.Image) -> np.ndarray:
    """
    Peça recortada (RGBA) -> tensor 1x3x224x224 do CLIP.
    A peça é centralizada num quadrado branco antes de reduzir, em vez do corte central
    do CLIP, que cortaria a barra de um vestido ou a ponta de uma calça.
    """
    rgba = cutout.convert("RGBA")
    side = max(rgba.width, rgba.height)
    canvas = Image.new("RGB", (side, side), BACKGROUND)
    canvas.paste(rgba, ((side - rgba.width) // 2, (side - rgba.height) // 2), rgba)
    canvas = canvas.resize((INPUT_SIDE, INPUT_SIDE), Image.Resampling.BICUBIC)

    pixels = np.asarray(canvas, dtype=np.float32) / 255.0
    return ((pixels - CLIP_MEAN) / CLIP_STD).transpose(2, 0, 1)[np.newaxis]


def embed_garment(cutout: Image.Image) -> List[float]:
    """Vetor de estilo da peça, com norma 1 (512d). Lança StyleModelUnavailable se o modelo faltar."""
    session = _get_session()
    vector = session.run(["image_embeds"], {"pixel_values": preprocess(cutout)})[0][0]
    norm = float(np.linalg.norm(vector))
    if norm < 1e-9:
        raise StyleModelUnavailable("O modelo de estilo devolveu um vetor nulo.")
    return [round(float(v), 6) for v in vector / norm]


def try_embed_garment(cutout: Image.Image) -> Optional[List[float]]:
    """Como embed_garment, mas sem derrubar o cadastro: sem modelo, a peça fica sem vetor (S_cos neutro)."""
    try:
        return embed_garment(cutout)
    except StyleModelUnavailable as exc:
        logger.warning("Peça sem vetor de estilo: %s", exc)
        return None
