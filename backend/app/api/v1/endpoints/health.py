"""
Endpoint de Healthcheck da API e Validação de Conectividade com o Banco de Dados
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from app.core.database import get_db

router = APIRouter()


@router.get("/health", status_code=status.HTTP_200_OK)
async def check_health(db: AsyncSession = Depends(get_db)):
    """
    Verifica o estado da API e valida a conexão assíncrona executando 'SELECT 1'.
    """
    try:
        result = await db.execute(text("SELECT 1"))
        _ = result.scalar()
        db_status = "connected"
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "status": "unhealthy",
                "service": "HarmonIA API",
                "database": f"disconnected: {str(exc)}"
            }
        )

    return {
        "status": "healthy",
        "service": "HarmonIA API",
        "database": db_status
    }
