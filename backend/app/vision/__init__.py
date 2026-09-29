"""
Pipeline de visão computacional do HarmonIA: recorte de fundo (RF04) e extração cromática (RF05).
"""

import time
from dataclasses import dataclass
from typing import List

import numpy as np

from app.vision.color_extraction import ColorCentroid, extract_color_centroids
from app.vision import segmentation
from app.vision.segmentation import InvalidImageError


@dataclass(frozen=True)
class SegmentationResult:
    png_bytes: bytes
    width: int
    height: int
    colors: List[ColorCentroid]
    processing_ms: int


def segment_garment(data: bytes) -> SegmentationResult:
    """Foto bruta -> PNG recortado com canal alfa + cores dominantes em L*a*b*."""
    started = time.perf_counter()

    image = segmentation.load_image(data)
    cutout = segmentation.crop_to_subject(segmentation.remove_background(image))
    colors = extract_color_centroids(np.asarray(cutout))

    return SegmentationResult(
        png_bytes=segmentation.encode_png(cutout),
        width=cutout.width,
        height=cutout.height,
        colors=colors,
        processing_ms=int((time.perf_counter() - started) * 1000),
    )


__all__ = ["SegmentationResult", "segment_garment", "InvalidImageError", "ColorCentroid"]
