"""
Entrypoint Principal da Aplicação FastAPI (HarmonIA Backend)
Configuração do servidor, CORS, ciclo de vida e roteamento RESTful v1.
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.database import engine, Base
from app.api.api_router import api_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Gerenciamento do Ciclo de Vida da Aplicação.
    Cria as tabelas do banco de dados na inicialização se o banco estiver disponível.
    """
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
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
