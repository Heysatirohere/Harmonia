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

    # Validação dos access tokens do Supabase Auth (RNF02)
    SUPABASE_JWT_SECRET: Optional[str] = Field(
        default=None,
        description="JWT Secret legado (HS256). Sem ele, os tokens são validados pelo JWKS do projeto"
    )
    SUPABASE_JWT_AUDIENCE: str = Field(
        default="authenticated",
        description="Claim `aud` esperado nos access tokens de usuários logados"
    )

    # Pipeline de visão: recorte de fundo (RF04) e extração cromática (RF05)
    SEGMENTATION_MODEL: str = Field(
        default="isnet-general-use",
        description="Modelo do rembg usado na remoção de fundo"
    )
    # Vetor de estilo da peça (S_cos): CLIP ViT-B/32 em ONNX, revisão fixa
    STYLE_MODEL_URL: str = Field(
        default=(
            "https://huggingface.co/Xenova/clip-vit-base-patch32/resolve/"
            "d15189d7028b43f1d3e65039190477f6af591c2a/onnx/vision_model.onnx"
        ),
        description="Codificador visual do CLIP usado no vetor de estilo das peças"
    )
    STYLE_MODEL_SHA256: str = Field(
        default="fd6e1402a588279d1723c7534d4bcba5bc0b14b47dfab0e46f8c47b8270d7d40",
        description="SHA-256 esperado do modelo de estilo"
    )
    STYLE_MODEL_PATH: str = Field(
        default="~/.cache/harmonia/clip-vit-b32-vision.onnx",
        description="Onde o modelo de estilo fica salvo depois de baixado"
    )
    MAX_UPLOAD_BYTES: int = Field(
        default=10 * 1024 * 1024,
        description="Tamanho máximo da foto enviada para segmentação"
    )

    # Limites das Cotas Freemium (RN02)
    FREEMIUM_MAX_CLOTHING_ITEMS: int = 30
    FREEMIUM_MAX_DAILY_LOOKS: int = 5
    QUOTA_TIMEZONE: str = Field(
        default="America/Sao_Paulo",
        description="Fuso em que a cota diária de looks vira o dia"
    )

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )


settings = Settings()
