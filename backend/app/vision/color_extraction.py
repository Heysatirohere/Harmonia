"""
Extração de Centróides Cromáticos no Espaço CIE L*a*b* (RF05, Seção 3.1.3)

Converte os pixels opacos da peça recortada (sRGB, iluminante D65) para L*a*b*
e agrupa-os por k-means, retornando as cores dominantes com sua área relativa.
"""

from dataclasses import dataclass
from typing import List

import numpy as np

# Branco de referência D65 (observador 2°)
_WHITE_D65 = np.array([0.95047, 1.00000, 1.08883])

_SRGB_TO_XYZ = np.array([
    [0.4124564, 0.3575761, 0.1804375],
    [0.2126729, 0.7151522, 0.0721750],
    [0.0193339, 0.1191920, 0.9503041],
])
_XYZ_TO_SRGB = np.linalg.inv(_SRGB_TO_XYZ)

_EPSILON = 216 / 24389
_KAPPA = 24389 / 27

ALPHA_THRESHOLD = 128        # Bordas semitransparentes do recorte não entram na análise
MAX_SAMPLE_PIXELS = 20_000   # Amostragem para manter a extração bem abaixo de 3,5 s (RNF03)
MERGE_DELTA_E = 10.0         # Centróides mais próximos que isso são o mesmo tom percebido
MIN_SHARE = 0.03             # Tons com menos de 3% da área são ruído de borda/sombra


@dataclass(frozen=True)
class ColorCentroid:
    L: float
    a: float
    b: float
    hex: str
    percentage: int
    name: str


def srgb_to_lab(rgb: np.ndarray) -> np.ndarray:
    """Converte uma matriz (N, 3) de sRGB 0-255 para CIE L*a*b* (D65)."""
    c = rgb.astype(np.float64) / 255.0
    linear = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    xyz = linear @ _SRGB_TO_XYZ.T / _WHITE_D65
    f = np.where(xyz > _EPSILON, np.cbrt(xyz), (_KAPPA * xyz + 16) / 116)
    L = 116 * f[:, 1] - 16
    a = 500 * (f[:, 0] - f[:, 1])
    b = 200 * (f[:, 1] - f[:, 2])
    return np.stack([L, a, b], axis=1)


def lab_to_hex(L: float, a: float, b: float) -> str:
    """Converte uma cor L*a*b* (D65) para hexadecimal sRGB, saturando fora do gamut."""
    fy = (L + 16) / 116
    f = np.array([fy + a / 500, fy, fy - b / 200])
    xyz = np.where(f ** 3 > _EPSILON, f ** 3, (116 * f - 16) / _KAPPA) * _WHITE_D65
    linear = np.clip(_XYZ_TO_SRGB @ xyz, 0.0, 1.0)
    srgb = np.where(linear <= 0.0031308, 12.92 * linear, 1.055 * linear ** (1 / 2.4) - 0.055)
    r, g, bl = np.round(np.clip(srgb, 0.0, 1.0) * 255).astype(int)
    return f"#{r:02X}{g:02X}{bl:02X}"


def describe_lab(L: float, a: float, b: float) -> str:
    """Nome curatorial aproximado a partir do matiz, croma e luminosidade."""
    chroma = float(np.hypot(a, b))

    if chroma < 8:
        if L >= 88:
            return "Branco"
        if L >= 70:
            return "Cinza Claro"
        if L >= 40:
            return "Cinza"
        if L >= 20:
            return "Grafite"
        return "Preto"

    hue = float(np.degrees(np.arctan2(b, a))) % 360
    if hue < 20 or hue >= 340:
        family = "Rosa" if L >= 65 else "Vermelho"
    elif hue < 70:
        if L >= 75:
            family = "Nude" if chroma < 30 else "Pêssego"
        elif chroma < 30:
            family = "Caramelo" if L >= 45 else "Marrom"
        else:
            family = "Terracota" if L < 60 else "Laranja"
    elif hue < 100:
        if chroma < 25:
            family = "Areia" if L >= 60 else "Cáqui"
        else:
            family = "Mostarda" if L < 75 else "Amarelo"
    elif hue < 160:
        family = "Oliva" if chroma < 35 and L < 60 else "Verde"
    elif hue < 230:
        family = "Petróleo" if L < 50 else "Turquesa"
    elif hue < 290:
        family = "Marinho" if L < 35 else "Azul"
    else:
        family = "Vinho" if L < 40 else ("Lilás" if L >= 60 else "Violeta")

    if L >= 80 and family not in ("Nude", "Pêssego", "Areia", "Amarelo", "Rosa", "Lilás"):
        return f"{family} Claro"
    if L < 25 and family not in ("Marinho", "Vinho", "Marrom", "Petróleo"):
        return f"{family} Profundo"
    return family


def _kmeans(points: np.ndarray, k: int, rng: np.random.Generator, iterations: int = 25):
    """K-means com inicialização k-means++; retorna (centróides, rótulos)."""
    centers = [points[rng.integers(len(points))]]
    for _ in range(1, k):
        dist = np.min(((points[:, None, :] - np.array(centers)[None]) ** 2).sum(-1), axis=1)
        if dist.sum() == 0:
            break
        centers.append(points[rng.choice(len(points), p=dist / dist.sum())])
    centers = np.array(centers)

    for _ in range(iterations):
        labels = ((points[:, None, :] - centers[None]) ** 2).sum(-1).argmin(axis=1)
        updated = np.array([
            points[labels == i].mean(axis=0) if np.any(labels == i) else centers[i]
            for i in range(len(centers))
        ])
        if np.allclose(updated, centers, atol=1e-3):
            break
        centers = updated

    labels = ((points[:, None, :] - centers[None]) ** 2).sum(-1).argmin(axis=1)
    return centers, labels


def extract_color_centroids(rgba: np.ndarray, max_colors: int = 4, seed: int = 0) -> List[ColorCentroid]:
    """
    Extrai até `max_colors` cores dominantes dos pixels opacos de uma imagem RGBA (H, W, 4).
    Retorna lista ordenada pela área ocupada; vazia se não houver pixels opacos.
    """
    pixels = rgba.reshape(-1, 4)
    opaque = pixels[pixels[:, 3] >= ALPHA_THRESHOLD, :3]
    if len(opaque) == 0:
        return []

    rng = np.random.default_rng(seed)
    if len(opaque) > MAX_SAMPLE_PIXELS:
        opaque = opaque[rng.choice(len(opaque), MAX_SAMPLE_PIXELS, replace=False)]

    lab = srgb_to_lab(opaque)
    k = min(max_colors, len(np.unique(opaque, axis=0)))
    centers, labels = _kmeans(lab, k, rng)
    shares = np.bincount(labels, minlength=len(centers)) / len(labels)

    # Funde centróides perceptualmente indistintos, do maior para o menor
    clusters: List[list] = []
    for i in np.argsort(-shares):
        for cluster in clusters:
            if np.linalg.norm(cluster[0] - centers[i]) < MERGE_DELTA_E:
                total = cluster[1] + shares[i]
                cluster[0] = (cluster[0] * cluster[1] + centers[i] * shares[i]) / total
                cluster[1] = total
                break
        else:
            clusters.append([centers[i].copy(), shares[i]])

    kept = [c for c in clusters if c[1] >= MIN_SHARE] or clusters[:1]
    total_share = sum(c[1] for c in kept)
    kept.sort(key=lambda c: -c[1])

    result = []
    for center, share in kept:
        L, a, b = (float(np.clip(center[0], 0, 100)), float(center[1]), float(center[2]))
        result.append(ColorCentroid(
            L=round(L, 1),
            a=round(a, 1),
            b=round(b, 1),
            hex=lab_to_hex(L, a, b),
            percentage=int(round(100 * share / total_share)),
            name=describe_lab(L, a, b),
        ))
    return result
