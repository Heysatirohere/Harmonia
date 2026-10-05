"""
Operações administrativas no Supabase com a service role key (RN04)

Usadas só pelo backend: apagar fotos do Storage e o login do Auth exige privilégio
que o app não tem (e não deve ter). A chave nunca sai do servidor.
"""

from typing import AsyncIterator, Iterable, List, Optional
from urllib.parse import unquote, urlparse
from uuid import UUID

import httpx
from fastapi import HTTPException, status

from app.core.config import settings


class SupabaseAdminError(Exception):
    """Falha ao falar com o Supabase; a operação deve ser repetida."""


class SupabaseAdmin:
    def __init__(self, client: Optional[httpx.AsyncClient] = None):
        if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
            raise SupabaseAdminError("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórias para excluir dados.")
        self._base = settings.SUPABASE_URL.rstrip("/")
        self._bucket = settings.SUPABASE_STORAGE_BUCKET
        key = settings.SUPABASE_SERVICE_ROLE_KEY
        self._client = client or httpx.AsyncClient(timeout=15.0)
        self._headers = {"apikey": key, "Authorization": f"Bearer {key}"}

    async def aclose(self) -> None:
        await self._client.aclose()

    def object_path(self, public_url: str) -> Optional[str]:
        """Caminho no bucket a partir da URL pública; None se a URL não for deste bucket."""
        marker = f"/storage/v1/object/public/{self._bucket}/"
        parsed = urlparse(public_url)
        if f"{parsed.scheme}://{parsed.netloc}" != self._base or marker not in parsed.path:
            return None
        return unquote(parsed.path.split(marker, 1)[1]) or None

    async def list_user_objects(self, user_id: UUID) -> List[str]:
        """Arquivos na pasta do usuário (`<user_id>/`), onde ficam os uploads atuais."""
        paths: List[str] = []
        offset = 0
        while True:
            response = await self._request(
                "POST",
                f"/storage/v1/object/list/{self._bucket}",
                json={"prefix": f"{user_id}/", "limit": 1000, "offset": offset},
            )
            page = response.json()
            paths.extend(f"{user_id}/{entry['name']}" for entry in page if entry.get("id"))
            if len(page) < 1000:
                return paths
            offset += 1000

    async def delete_objects(self, paths: Iterable[str]) -> None:
        unique = sorted(set(paths))
        for start in range(0, len(unique), 1000):
            await self._request(
                "DELETE",
                f"/storage/v1/object/{self._bucket}",
                json={"prefixes": unique[start:start + 1000]},
            )

    async def delete_auth_user(self, user_id: UUID) -> None:
        """Revoga o login e todas as sessões do usuário no Supabase Auth."""
        await self._request("DELETE", f"/auth/v1/admin/users/{user_id}", allow_not_found=True)

    async def _request(self, method: str, path: str, json=None, allow_not_found: bool = False) -> httpx.Response:
        try:
            response = await self._client.request(method, f"{self._base}{path}", json=json, headers=self._headers)
        except httpx.HTTPError as exc:
            raise SupabaseAdminError(f"Supabase indisponível: {exc}") from exc
        if allow_not_found and response.status_code == 404:
            return response
        if response.status_code >= 400:
            raise SupabaseAdminError(f"Supabase recusou {method} {path}: {response.status_code}")
        return response


async def get_supabase_admin() -> AsyncIterator[SupabaseAdmin]:
    """Dependência do FastAPI; os testes a substituem por um dublê."""
    try:
        admin = SupabaseAdmin()
    except SupabaseAdminError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Exclusão de dados indisponível: o servidor não tem a chave administrativa do Supabase.",
        )
    try:
        yield admin
    finally:
        await admin.aclose()
