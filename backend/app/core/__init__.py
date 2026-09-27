"""
Módulo Core da Aplicação Backend HarmonIA
Contém as configurações globais e a gestão da sessão assíncrona do banco de dados.
"""

from .config import settings
from .database import engine, AsyncSessionLocal, Base, get_db

__all__ = ["settings", "engine", "AsyncSessionLocal", "Base", "get_db"]
