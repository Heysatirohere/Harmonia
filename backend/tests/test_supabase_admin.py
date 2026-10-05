"""
Testes do cliente administrativo do Supabase (RN04) com transporte HTTP simulado.
"""

import json
import uuid

import httpx
import pytest

from app.core.config import settings
from app.core.supabase_admin import SupabaseAdmin, SupabaseAdminError

BASE = "https://harmonia-test.supabase.co"


@pytest.fixture(autouse=True)
def configured(monkeypatch):
    monkeypatch.setattr(settings, "SUPABASE_URL", BASE)
    monkeypatch.setattr(settings, "SUPABASE_SERVICE_ROLE_KEY", "service-role-test")
    monkeypatch.setattr(settings, "SUPABASE_STORAGE_BUCKET", "wardrobe-items")


def _admin(handler):
    return SupabaseAdmin(client=httpx.AsyncClient(transport=httpx.MockTransport(handler)))


def test_object_path_only_accepts_this_projects_bucket():
    admin = _admin(lambda r: httpx.Response(200))

    assert admin.object_path(f"{BASE}/storage/v1/object/public/wardrobe-items/abc/peça%201.png") == "abc/peça 1.png"
    assert admin.object_path(f"{BASE}/storage/v1/object/public/outro-bucket/x.png") is None
    assert admin.object_path("https://images.unsplash.com/photo.png") is None
    assert admin.object_path("https://evil.example/storage/v1/object/public/wardrobe-items/x.png") is None


@pytest.mark.anyio
async def test_lists_user_folder_with_pagination_and_service_key():
    user_id = uuid.uuid4()
    calls = []

    def handler(request):
        calls.append(request)
        body = json.loads(request.content)
        count = 1000 if body["offset"] == 0 else 2
        return httpx.Response(200, json=[{"id": "x", "name": f"{body['offset'] + i}.png"} for i in range(count)])

    paths = await _admin(handler).list_user_objects(user_id)

    assert len(paths) == 1002
    assert paths[0] == f"{user_id}/0.png"
    assert calls[0].url.path == "/storage/v1/object/list/wardrobe-items"
    assert json.loads(calls[0].content)["prefix"] == f"{user_id}/"
    assert calls[0].headers["authorization"] == "Bearer service-role-test"


@pytest.mark.anyio
async def test_delete_objects_sends_unique_prefixes():
    seen = []

    def handler(request):
        seen.append((request.method, request.url.path, json.loads(request.content)))
        return httpx.Response(200, json=[])

    await _admin(handler).delete_objects(["a.png", "b.png", "a.png"])

    assert seen == [("DELETE", "/storage/v1/object/wardrobe-items", {"prefixes": ["a.png", "b.png"]})]


@pytest.mark.anyio
async def test_auth_user_already_gone_is_not_an_error():
    await _admin(lambda r: httpx.Response(404)).delete_auth_user(uuid.uuid4())


@pytest.mark.anyio
async def test_server_errors_raise():
    with pytest.raises(SupabaseAdminError):
        await _admin(lambda r: httpx.Response(500)).delete_objects(["a.png"])


def test_missing_service_key_is_reported(monkeypatch):
    monkeypatch.setattr(settings, "SUPABASE_SERVICE_ROLE_KEY", None)
    with pytest.raises(SupabaseAdminError):
        SupabaseAdmin()
