"""
Módulo de Conexão Assíncrona com o Banco de Dados (SQLAlchemy 2.0 + asyncpg)
"""

from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase

from .config import settings


# Criar engine assíncrono para PostgreSQL
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    future=True,
    pool_pre_ping=True,
)

# Fábrica de sessões assíncronas do SQLAlchemy 2.0
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


class Base(DeclarativeBase):
    """Classe Base Declarativa para todas as entidades ORM."""
    pass


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Gerador assíncrono de sessão do banco de dados para injeção de dependência no FastAPI.
    Garante o fechamento seguro e rollback em caso de falha.
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
