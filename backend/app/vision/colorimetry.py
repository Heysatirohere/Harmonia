"""
Teste Assistido de Colorimetria por Selfie (RF02, Seção 3.1.1)

A selfie é enquadrada com o rosto no oval do app. Do centro do rosto saem os pixels de
pele (regra YCbCr), e deles a cor média em CIE L*a*b*: o ângulo de matiz h*ab dá o subtom
(quente ou frio) e o croma C*ab a saturação. A profundidade é a da coloração inteira, não só
da pele: pele clara com cabelo preto é profunda. O contraste é a distância de luminosidade
entre a pele e os tons mais escuros do rosto (cabelo, sobrancelhas, olhos).

A cartela segue o sistema de 12 estações pela característica dominante: o subtom e a
profundidade escolhem a estação, e o traço mais marcado escolhe a variante (quente/fria,
clara/escura, brilhante/suave). Os pontos neutros abaixo são heurísticos, calibrados para
pele sob luz natural; luz amarela ou filtros de câmera deslocam o resultado. Por isso a
cartela é sugestão: a pessoa confirma ou troca, e a selfie nunca é guardada.
"""

import math
from dataclasses import dataclass
from typing import Optional

import numpy as np
from PIL import Image

from app.vision.color_extraction import lab_to_hex, srgb_to_lab

# Pontos neutros (pele sob luz natural) e quanto de desvio vale "um passo"
NEUTRAL_HUE, HUE_STEP = 50.0, 8.0          # graus de h*ab; acima é quente
NEUTRAL_LIGHTNESS, LIGHTNESS_STEP = 60.0, 10.0
NEUTRAL_CHROMA, CHROMA_STEP = 22.0, 6.0
NEUTRAL_CONTRAST, CONTRAST_STEP = 35.0, 15.0

# Regiões da foto, em frações da largura e da altura (rosto no oval central do app)
CHEEK_BOX = (0.32, 0.30, 0.68, 0.62)   # pele: bochechas, nariz e testa baixa
FACE_BOX = (0.22, 0.08, 0.78, 0.72)    # rosto com cabelo e sobrancelhas, para o contraste
MIN_SKIN_SHARE = 0.15                   # menos que isso na região central: não é um rosto
MAX_SIDE = 512                          # a análise não precisa de mais resolução
HAIR_WEIGHT = 0.4                       # peso dos tons escuros do rosto na profundidade


class FaceNotFoundError(ValueError):
    """Pouca pele no centro da foto: o rosto não estava no oval."""


@dataclass(frozen=True)
class SkinAnalysis:
    L: float
    a: float
    b: float
    hex: str
    hue: float
    chroma: float
    contrast: float
    undertone: str   # QUENTE, NEUTRO ou FRIO
    depth: str       # CLARA, MEDIA ou PROFUNDA (da coloração inteira, pele e cabelo)
    intensity: str   # BRILHANTE ou SUAVE
    palette: str     # chave da cartela no motor (color_science.SEASONAL_PALETTES)


def _crop(pixels: np.ndarray, box) -> np.ndarray:
    h, w = pixels.shape[:2]
    x0, y0, x1, y1 = box
    return pixels[int(y0 * h): int(y1 * h), int(x0 * w): int(x1 * w)]


def skin_mask(rgb: np.ndarray) -> np.ndarray:
    """Pixels com cor de pele pela regra clássica em YCbCr (vale para tons claros e escuros)."""
    r, g, b = (rgb[..., i].astype(np.float64) for i in range(3))
    cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b
    cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b
    y = 0.299 * r + 0.587 * g + 0.114 * b
    return (cr >= 133) & (cr <= 173) & (cb >= 77) & (cb <= 127) & (y >= 25)


def choose_palette(hue: float, lightness: float, chroma: float, contrast: float) -> str:
    """Cartela pela característica dominante do sistema de 12 estações."""
    warmth = (hue - NEUTRAL_HUE) / HUE_STEP
    light = (lightness - NEUTRAL_LIGHTNESS) / LIGHTNESS_STEP
    bright = ((chroma - NEUTRAL_CHROMA) / CHROMA_STEP + (contrast - NEUTRAL_CONTRAST) / CONTRAST_STEP) / 2

    season = ("PRIMAVERA" if light >= 0 else "OUTONO") if warmth >= 0 else ("VERAO" if light >= 0 else "INVERNO")
    variants = {
        "PRIMAVERA": {"warmth": "PRIMAVERA_QUENTE", "light": "PRIMAVERA_CLARA", "bright+": "PRIMAVERA_BRILHANTE"},
        "OUTONO": {"warmth": "OUTONO_QUENTE", "light": "OUTONO_ESCURO", "bright-": "OUTONO_SUAVE"},
        "VERAO": {"warmth": "VERAO_FRIO", "light": "VERAO_CLARO", "bright-": "VERAO_SUAVE"},
        "INVERNO": {"warmth": "INVERNO_FRIO", "light": "INVERNO_ESCURO", "bright+": "INVERNO_BRILHANTE"},
    }[season]
    traits = sorted(
        [("warmth", abs(warmth)), ("light", abs(light)), ("bright+" if bright >= 0 else "bright-", abs(bright))],
        key=lambda t: t[1],
        reverse=True,
    )
    # A variante de intensidade só existe num sentido por estação (não há Primavera Suave)
    return next(variants[trait] for trait, _ in traits if trait in variants)


def analyze_selfie(image: Image.Image) -> SkinAnalysis:
    """Subtom, profundidade, saturação, contraste e cartela sugerida a partir da selfie."""
    rgb = image.convert("RGB")
    rgb.thumbnail((MAX_SIDE, MAX_SIDE))
    pixels = np.asarray(rgb)

    cheeks = _crop(pixels, CHEEK_BOX)
    mask = skin_mask(cheeks)
    if mask.mean() < MIN_SKIN_SHARE:
        raise FaceNotFoundError("Não encontramos o rosto no centro da foto. Enquadre o rosto no oval, sob luz natural.")

    skin_lab = srgb_to_lab(cheeks[mask].reshape(-1, 3))
    L, a, b = (float(v) for v in np.median(skin_lab, axis=0))
    hue = math.degrees(math.atan2(b, a)) % 360.0
    chroma = math.hypot(a, b)

    face = _crop(pixels, FACE_BOX).reshape(-1, 3)
    face_l = srgb_to_lab(face)[:, 0]
    darkest = float(np.percentile(face_l, 5))
    contrast = max(0.0, L - darkest)
    # Profundidade da coloração: pele e cabelo juntos
    value = (1 - HAIR_WEIGHT) * L + HAIR_WEIGHT * min(darkest, L)

    undertone = "QUENTE" if hue >= NEUTRAL_HUE + HUE_STEP / 2 else "FRIO" if hue <= NEUTRAL_HUE - HUE_STEP / 2 else "NEUTRO"
    depth = "CLARA" if value >= NEUTRAL_LIGHTNESS + LIGHTNESS_STEP / 2 else "PROFUNDA" if value <= NEUTRAL_LIGHTNESS - LIGHTNESS_STEP / 2 else "MEDIA"
    intensity = "BRILHANTE" if (chroma - NEUTRAL_CHROMA) / CHROMA_STEP + (contrast - NEUTRAL_CONTRAST) / CONTRAST_STEP >= 0 else "SUAVE"

    return SkinAnalysis(
        L=round(L, 1),
        a=round(a, 1),
        b=round(b, 1),
        hex=lab_to_hex(L, a, b),
        hue=round(hue, 1),
        chroma=round(chroma, 1),
        contrast=round(contrast, 1),
        undertone=undertone,
        depth=depth,
        intensity=intensity,
        palette=choose_palette(hue, value, chroma, contrast),
    )
