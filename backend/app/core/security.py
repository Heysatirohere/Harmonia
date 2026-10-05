"""
Autenticação da API via JWT emitido pelo Supabase Auth (RF01, RNF02, RN01)

A identidade do usuário vem exclusivamente do claim `sub` de um access token
verificado. Suporta os dois modos de assinatura do Supabase:
- Chaves assimétricas (ES256/RS256), validadas pelo JWKS público do projeto.
- Segredo compartilhado legado (HS256), quando SUPABASE_JWT_SECRET é definido.
"""

from datetime import datetime, timezone
from functools import lru_cache
from typing import Any, Dict
from uuid import UUID

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db
from app.core.quota import sync_daily_counter
from app.models.entities import User

ASYMMETRIC_ALGORITHMS = ["ES256", "RS256"]

bearer_scheme = HTTPBearer(auto_error=False, description="Access token do Supabase Auth")


def _unauthorized(detail: str) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=detail,
        headers={"WWW-Authenticate": "Bearer"},
    )


def _issuer() -> str | None:
    if not settings.SUPABASE_URL:
        return None
    return f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1"


@lru_cache(maxsize=1)
def _jwks_client(jwks_url: str) -> jwt.PyJWKClient:
    # O PyJWKClient mantém as chaves em cache e busca novamente quando surge um `kid` desconhecido.
    return jwt.PyJWKClient(jwks_url, cache_keys=True, lifespan=3600)


def decode_supabase_token(token: str) -> Dict[str, Any]:
    """Valida assinatura, expiração, audiência e emissor do token. Lança 401 em qualquer falha."""
    issuer = _issuer()
    options = {"require": ["exp", "sub", "aud"]}

    try:
        algorithm = jwt.get_unverified_header(token).get("alg")

        if algorithm == "HS256":
            if not settings.SUPABASE_JWT_SECRET:
                raise _unauthorized("Token HS256 recebido, mas SUPABASE_JWT_SECRET não está configurado.")
            key: Any = settings.SUPABASE_JWT_SECRET
            algorithms = ["HS256"]
        elif algorithm in ASYMMETRIC_ALGORITHMS:
            if not issuer:
                raise _unauthorized("SUPABASE_URL não configurada para validar tokens assimétricos.")
            key = _jwks_client(f"{issuer}/.well-known/jwks.json").get_signing_key_from_jwt(token).key
            algorithms = [algorithm]
        else:
            raise _unauthorized("Algoritmo de assinatura não suportado.")

        return jwt.decode(
            token,
            key,
            algorithms=algorithms,
            audience=settings.SUPABASE_JWT_AUDIENCE,
            issuer=issuer,
            options=options,
        )
    except jwt.ExpiredSignatureError:
        raise _unauthorized("Sessão expirada. Faça login novamente.")
    except (jwt.PyJWTError, jwt.PyJWKClientError):
        raise _unauthorized("Token de acesso inválido.")


async def get_token_claims(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> Dict[str, Any]:
    """Extrai e valida o Bearer token do header Authorization."""
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise _unauthorized("Autenticação obrigatória.")
    return decode_supabase_token(credentials.credentials)


async def get_current_user_id(claims: Dict[str, Any] = Depends(get_token_claims)) -> UUID:
    """ID do usuário autenticado, derivado do claim `sub` do token verificado (RN01)."""
    try:
        return UUID(claims["sub"])
    except (KeyError, ValueError):
        raise _unauthorized("Token de acesso sem identificador de usuário válido.")


async def get_current_user(
    claims: Dict[str, Any] = Depends(get_token_claims),
    current_user_id: UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
) -> User:
    """
    Carrega o perfil em public.users do usuário autenticado.
    O trigger on_auth_user_created cria esse registro no cadastro; se ele não existir
    (contas anteriores ao trigger ou banco local), é provisionado a partir do token verificado.
    """
    result = await db.execute(select(User).where(User.id == current_user_id))
    user = result.scalars().first()

    if not user:
        email = claims.get("email")
        if not email:
            raise _unauthorized("Token de acesso sem e-mail para provisionar o perfil.")
        user = User(
            id=current_user_id,
            email=email,
            hashed_password="managed_by_supabase_auth",
            is_premium=False,
            is_public=True,
            items_count=0,
            looks_generated_today=0,
            created_at=datetime.now(timezone.utc),
        )
        db.add(user)
        await db.flush()

    # A cota diária exibida e aplicada em qualquer rota é sempre a de hoje (RN02)
    sync_daily_counter(user)
    return user
