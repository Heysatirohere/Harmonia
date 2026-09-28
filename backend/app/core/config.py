"""
Módulo de Configuração e Gerenciamento de Variáveis de Ambiente
Utiliza pydantic-settings v2 com fallbacks seguros de desenvolvimento.
"""

from typing import Optional
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configurações globais da API Backend do HarmonIA."""
    PROJECT_NAME: str = "HarmonIA Backend API"
    VERSION: str = "1.0.0"
    ENVIRONMENT: str = "development"

    # Porta da aplicação (Google Cloud Run injeta a variável PORT, padrão 8080)
    PORT: int = 8000

    # Configurações do Supabase (Auth, Storage e PostgreSQL gerenciado)
    SUPABASE_URL: Optional[str] = Field(
        default=None,
        description="URL do projeto Supabase (ex: https://xyz.supabase.co)"
    )
    SUPABASE_KEY: Optional[str] = Field(
        default=None,
        description="Chave anônima / pública do Supabase (anon key)"
    )
    SUPABASE_SERVICE_ROLE_KEY: Optional[str] = Field(
        default=None,
        description="Chave administrativa segura do Supabase (service role key)"
    )
    SUPABASE_STORAGE_BUCKET: str = Field(
        default="wardrobe-items",
        description="Bucket do Supabase Storage para peças com canal alfa"
    )

    # Configurações do PostgreSQL (Local Docker ou Supabase Postgres com pgvector)
    POSTGRES_USER: str = "harmonia_user"
    POSTGRES_PASSWORD: str = "harmonia_secret"
    POSTGRES_SERVER: str = "localhost"
    POSTGRES_PORT: int = 5432
    POSTGRES_DB: str = "harmonia_db"

    # URL de Conexão Assíncrona via asyncpg
    DATABASE_URL: str = Field(
        default="postgresql+asyncpg://harmonia_user:harmonia_secret@localhost:5432/harmonia_db",
        description="URL de conexão assíncrona com PostgreSQL via asyncpg"
    )

    # Segurança e Autenticação JWT
    SECRET_KEY: str = "harmonia_super_secret_key_change_in_production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # Limites das Cotas Freemium (RN02)
    FREEMIUM_MAX_CLOTHING_ITEMS: int = 30
    FREEMIUM_MAX_DAILY_LOOKS: int = 5

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )


settings = Settings()
