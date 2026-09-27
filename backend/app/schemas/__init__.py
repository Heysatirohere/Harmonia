"""
Módulo de Contratos de Dados e DTOs (Pydantic v2)
"""

from .dtos import (
    UserCreate,
    UserResponse,
    UserUsageSummary,
    ClothingItemCreate,
    ClothingItemResponse,
    ClothingItemFilter,
    OutfitCalculateRequest,
)

__all__ = [
    "UserCreate",
    "UserResponse",
    "UserUsageSummary",
    "ClothingItemCreate",
    "ClothingItemResponse",
    "ClothingItemFilter",
    "OutfitCalculateRequest",
]
