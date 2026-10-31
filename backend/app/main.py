"""
Entrypoint Principal da Aplicação FastAPI (HarmonIA Backend)
Configuração do servidor, CORS, ciclo de vida e roteamento RESTful v1.
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from sqlalchemy import text
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.database import engine, Base
from app.api.api_router import api_router


# create_all não altera tabelas existentes; colunas novas entram aqui de forma idempotente
# (espelham o supabase_schema.sql)
SCHEMA_UPGRADES = [
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_public BOOLEAN NOT NULL DEFAULT TRUE",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS looks_counter_date DATE",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS looks_signatures_today JSONB NOT NULL DEFAULT '[]'::jsonb",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name VARCHAR(100)",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS rotation_alerts_enabled BOOLEAN NOT NULL DEFAULT TRUE",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS lgpd_consent_accepted BOOLEAN NOT NULL DEFAULT TRUE",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS lgpd_consent_at TIMESTAMP WITH TIME ZONE",
    "ALTER TABLE clothing_items ADD COLUMN IF NOT EXISTS pattern VARCHAR(50)",
    "ALTER TABLE clothing_items ADD COLUMN IF NOT EXISTS season VARCHAR(30)",
    "ALTER TABLE clothing_items ADD COLUMN IF NOT EXISTS thermal_category VARCHAR(30)",
    "ALTER TABLE clothing_items ADD COLUMN IF NOT EXISTS purchase_price DOUBLE PRECISION",
    "ALTER TABLE clothing_items ADD COLUMN IF NOT EXISTS brand VARCHAR(100)",
    "ALTER TABLE clothing_items ADD COLUMN IF NOT EXISTS fabric_composition VARCHAR(160)",
    "ALTER TABLE clothing_items ADD COLUMN IF NOT EXISTS is_conscious_fashion BOOLEAN NOT NULL DEFAULT FALSE",
    "ALTER TABLE clothing_items ADD COLUMN IF NOT EXISTS disposal_status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE'",
    "ALTER TABLE clothing_items ADD COLUMN IF NOT EXISTS capsules JSONB NOT NULL DEFAULT '[]'::jsonb",
    "ALTER TABLE clothing_items ADD COLUMN IF NOT EXISTS style_embedding vector(512)",
    "ALTER TABLE saved_posts ADD COLUMN IF NOT EXISTS board_name VARCHAR(80) NOT NULL DEFAULT 'Salvos'",
]


async def ensure_schema() -> None:
    """Cria tabelas faltantes e aplica colunas novas de forma idempotente."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        for statement in SCHEMA_UPGRADES:
            await conn.execute(text(statement))


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Gerenciamento do Ciclo de Vida da Aplicação.
    Cria as tabelas do banco de dados na inicialização se o banco estiver disponível.
    """
    try:
        await ensure_schema()
    except Exception as exc:
        print(f"[WARN] Não foi possível conectar ao banco de dados durante startup: {exc}")
    yield


app = FastAPI(
    title="HarmonIA API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# Configuração do CORSMiddleware liberando requisições para Flutter local e emulador Android (10.0.2.2)
origins = [
    "http://localhost",
    "http://localhost:8000",
    "http://localhost:3000",
    "http://10.0.2.2",
    "http://10.0.2.2:8000",
    "*"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inclusão do Roteador Principal v1 sob o prefixo /api
app.include_router(api_router, prefix="/api")


@app.get("/", include_in_schema=False)
async def root():
    """Rota inicial de boas-vindas."""
    return {
        "service": "HarmonIA API",
        "version": "1.0.0",
        "docs": "/docs"
    }
