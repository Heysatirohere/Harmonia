"""
Pipeline de visão computacional do HarmonIA: recorte de fundo (RF04), extração cromática (RF05)
e vetor de estilo da peça (S_cos).
"""

import time
from dataclasses import dataclass
from typing import List, Optional

import numpy as np

from app.vision.color_extraction import ColorCentroid, extract_color_centroids
from app.vision import segmentation, style_embedding
from app.vision.segmentation import InvalidImageError


@dataclass(frozen=True)
class SegmentationResult:
    png_bytes: bytes
    width: int
    height: int
    colors: List[ColorCentroid]
    style_embedding: Optional[List[float]]
    processing_ms: int


def segment_garment(data: bytes) -> SegmentationResult:
    """Foto bruta -> PNG recortado com canal alfa + cores dominantes em L*a*b* + vetor de estilo."""
    started = time.perf_counter()

    image = segmentation.load_image(data)
    cutout = segmentation.crop_to_subject(segmentation.remove_background(image))
    colors = extract_color_centroids(np.asarray(cutout))
    # Peça sem cor visível não é peça: nem vale gastar a inferência do vetor
    embedding = style_embedding.try_embed_garment(cutout) if colors else None

    return SegmentationResult(
        png_bytes=segmentation.encode_png(cutout),
        width=cutout.width,
        height=cutout.height,
        colors=colors,
        style_embedding=embedding,
        processing_ms=int((time.perf_counter() - started) * 1000),
    )


__all__ = ["SegmentationResult", "segment_garment", "InvalidImageError", "ColorCentroid"]
