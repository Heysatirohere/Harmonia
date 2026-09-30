"""
Agregador da API Router v1 do HarmonIA
"""

from fastapi import APIRouter

from app.api.v1.endpoints import health, users, wardrobe, outfits

api_router = APIRouter()

api_router.include_router(health.router, prefix="/v1", tags=["Health"])
api_router.include_router(users.router, prefix="/v1/users", tags=["Users"])
api_router.include_router(wardrobe.router, prefix="/v1/wardrobe", tags=["Wardrobe"])
api_router.include_router(outfits.router, prefix="/v1/outfits", tags=["Outfits"])
