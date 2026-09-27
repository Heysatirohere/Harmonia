"""
Testes de Integração Assíncronos da API RESTful do HarmonIA (httpx / AsyncClient)
Testa os Endpoints Health, Auth, Wardrobe (RN01, RN02, RF06) e Outfits/IHE (RN02, RF07, RF13).
"""

import uuid
from datetime import datetime, timezone
import pytest
import httpx
from httpx import ASGITransport

from app.main import app
from app.core.database import get_db
from app.models.entities import User, ClothingItem


# -----------------------------------------------------------------------------
# Repositório em Memória e Fake AsyncSession para Testes Isolados de API
# -----------------------------------------------------------------------------

class InMemoryStore:
    def __init__(self):
        self.users = {}
        self.clothing_items = {}

    def clear(self):
        self.users.clear()
        self.clothing_items.clear()


store = InMemoryStore()


class FakeScalarResult:
    def __init__(self, items):
        if isinstance(items, list):
            self._items = items
        elif items is not None:
            self._items = [items]
        else:
            self._items = []

    def first(self):
        return self._items[0] if self._items else None

    def all(self):
        return list(self._items)


class FakeExecuteResult:
    def __init__(self, data):
        self._data = data

    def scalar(self):
        if isinstance(self._data, list):
            return self._data[0] if self._data else None
        return self._data

    def scalars(self):
        return FakeScalarResult(self._data)


class MockAsyncSession:
    """Mock de AsyncSession do SQLAlchemy para testes isolados sem dependência de BD externo."""

    def __init__(self):
        self.store = store

    async def execute(self, statement):
        sql_text = str(statement).lower()

        # 1. Healthcheck query
        if "select 1" in sql_text:
            return FakeExecuteResult(1)

        # 2. Queries de Usuários
        if "from users" in sql_text or "users." in sql_text:
            users_list = list(self.store.users.values())
            compiled = statement.compile()
            params = compiled.params if hasattr(compiled, "params") else {}

            target_user = None
            for p_val in params.values():
                if isinstance(p_val, uuid.UUID) and p_val in self.store.users:
                    target_user = self.store.users[p_val]
                    break
                if isinstance(p_val, str) and "@" in p_val:
                    for u in users_list:
                        if u.email == p_val:
                            target_user = u
                            break

            if target_user:
                return FakeExecuteResult([target_user])
            return FakeExecuteResult(users_list)

        # 3. Queries de Peças de Vestuário
        if "from clothing_items" in sql_text or "clothing_items." in sql_text:
            items_list = list(self.store.clothing_items.values())
            compiled = statement.compile()
            params = compiled.params if hasattr(compiled, "params") else {}

            user_id_param = None
            item_id_param = None
            category_param = None

            for p_val in params.values():
                if isinstance(p_val, uuid.UUID):
                    if p_val in self.store.users or any(i.user_id == p_val for i in items_list):
                        user_id_param = p_val
                    if p_val in self.store.clothing_items or any(i.id == p_val for i in items_list):
                        item_id_param = p_val
                elif isinstance(p_val, str) and p_val in ["top", "bottom", "shoes", "one_piece", "outerwear"]:
                    category_param = p_val

            filtered = items_list
            if item_id_param:
                filtered = [i for i in filtered if i.id == item_id_param]
            elif user_id_param:
                filtered = [i for i in filtered if i.user_id == user_id_param]

            if category_param:
                filtered = [i for i in filtered if i.category == category_param]

            return FakeExecuteResult(filtered)

        return FakeExecuteResult([])

    def add(self, instance):
        if isinstance(instance, User):
            if instance.created_at is None:
                instance.created_at = datetime.now(timezone.utc)
            self.store.users[instance.id] = instance
        elif isinstance(instance, ClothingItem):
            if instance.created_at is None:
                instance.created_at = datetime.now(timezone.utc)
            if instance.is_archived is None:
                instance.is_archived = False
            self.store.clothing_items[instance.id] = instance

    async def delete(self, instance):
        if isinstance(instance, ClothingItem) and instance.id in self.store.clothing_items:
            del self.store.clothing_items[instance.id]
        elif isinstance(instance, User) and instance.id in self.store.users:
            del self.store.users[instance.id]

    async def commit(self):
        pass

    async def flush(self):
        pass

    async def refresh(self, instance):
        pass

    async def rollback(self):
        pass

    async def close(self):
        pass


async def override_get_db():
    session = MockAsyncSession()
    try:
        yield session
    finally:
        await session.close()


@pytest.fixture(autouse=True)
def setup_test_environment():
    store.clear()
    app.dependency_overrides[get_db] = override_get_db
    yield
    store.clear()
    app.dependency_overrides.clear()


# -----------------------------------------------------------------------------
# Testes de Integração dos Endpoints RESTful
# -----------------------------------------------------------------------------

@pytest.mark.anyio
async def test_health_check_endpoint():
    """Valida o endpoint GET /api/v1/health retornando HTTP 200 e conectividade ok."""
    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/health")

    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "HarmonIA API"
    assert data["database"] == "connected"


@pytest.mark.anyio
async def test_mock_auth_session_endpoint():
    """Valida a criação de sessão mock de desenvolvimento no POST /api/v1/auth/mock-session."""
    payload = {
        "email": "test.designer@harmonia.app",
        "body_shape": "AMPULHETA",
        "seasonal_palette": "OUTONO_QUENTE",
        "is_premium": False
    }

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/auth/mock-session", json=payload)

    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["user"]["email"] == "test.designer@harmonia.app"
    assert data["user"]["body_shape"] == "AMPULHETA"


@pytest.mark.anyio
async def test_calculate_ihe_endpoint_success():
    """Valida o endpoint POST /api/v1/outfits/calculate-ihe retornando os 4 pilares e IHE."""
    payload = {
        "direct_garment_color": {"L": 45.0, "a": 30.0, "b": 25.0},
        "user_palette": "OUTONO_QUENTE",
        "user_biotype": "AMPULHETA",
        "garment_cuts": ["ACINTURADO"],
        "garment_formality": 0.8,
        "occasion": "CORPORATIVO",
        "temperature_celsius": 21.0,
        "is_raining": False,
        "user_style_vector": [0.1] * 512,
        "look_style_vector": [0.1] * 512
    }

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/outfits/calculate-ihe", json=payload)

    assert response.status_code == 200
    data = response.json()

    assert "ihe_score" in data
    assert "s_cor" in data
    assert "s_bio" in data
    assert "s_ocasion" in data
    assert "s_cos" in data
    assert "is_strongly_recommended" in data
    assert isinstance(data["is_strongly_recommended"], bool)


@pytest.mark.anyio
async def test_freemium_item_quota_limit_rn02():
    """
    Valida a cota Freemium de peças (RN02):
    Retorna HTTP 403 Forbidden quando usuário não-premium com 30 peças tenta cadastrar a 31ª peça.
    """
    user_id = uuid.uuid4()
    user = User(
        id=user_id,
        email="freemium.user@harmonia.app",
        hashed_password="secret_pass",
        is_premium=False,
        items_count=30,
        looks_generated_today=0,
        created_at=datetime.now(timezone.utc)
    )
    store.users[user_id] = user

    item_payload = {
        "category": "top",
        "image_url": "https://s3.amazonaws.com/harmonia/item31.png",
        "dominant_l": 50.0,
        "dominant_a": 20.0,
        "dominant_b": 10.0,
        "formality_score": 0.5,
    }

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"/api/v1/wardrobe/items?user_id={user_id}",
            json=item_payload
        )

    assert response.status_code == 403
    data = response.json()
    assert "Limite da cota Freemium atingido (máximo 30 peças)" in data["detail"]


@pytest.mark.anyio
async def test_freemium_look_daily_quota_limit_rn02():
    """
    Valida a cota Freemium de combinações diárias por IA (RN02):
    Retorna HTTP 403 Forbidden quando usuário não-premium atinge 5 gerações no dia.
    """
    user_id = uuid.uuid4()
    user = User(
        id=user_id,
        email="freemium.look.user@harmonia.app",
        hashed_password="secret_pass",
        is_premium=False,
        items_count=5,
        looks_generated_today=5,
        created_at=datetime.now(timezone.utc)
    )
    store.users[user_id] = user

    payload = {
        "direct_garment_color": {"L": 50.0, "a": 0.0, "b": 0.0},
        "user_palette": "OUTONO_QUENTE",
        "user_biotype": "AMPULHETA",
        "garment_cuts": [],
        "garment_formality": 0.5,
        "occasion": "CASUAL",
        "temperature_celsius": 25.0,
        "user_style_vector": [0.0] * 512,
        "look_style_vector": [0.0] * 512
    }

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"/api/v1/outfits/calculate-ihe?user_id={user_id}",
            json=payload
        )

    assert response.status_code == 403
    data = response.json()
    assert "Limite da cota Freemium de combinações diárias atingido" in data["detail"]


@pytest.mark.anyio
async def test_multi_tenant_isolation_rn01():
    """
    Valida a garantia de isolamento Multi-Tenant estrito (RN01):
    Usuários não visualizam nem podem excluir peças de outros usuários.
    """
    user_a_id = uuid.uuid4()
    user_b_id = uuid.uuid4()
    item_a_id = uuid.uuid4()

    user_a = User(id=user_a_id, email="usera@harmonia.app", hashed_password="pw", is_premium=True, created_at=datetime.now(timezone.utc))
    user_b = User(id=user_b_id, email="userb@harmonia.app", hashed_password="pw", is_premium=True, created_at=datetime.now(timezone.utc))
    store.users[user_a_id] = user_a
    store.users[user_b_id] = user_b

    item_a = ClothingItem(
        id=item_a_id,
        user_id=user_a_id,
        category="top",
        image_url="https://s3.amazonaws.com/harmonia/item_a.png",
        dominant_l=50.0,
        dominant_a=10.0,
        dominant_b=10.0,
        formality_score=0.7,
        is_archived=False,
        created_at=datetime.now(timezone.utc)
    )
    store.clothing_items[item_a_id] = item_a

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # 1. Usuário B tenta listar peças e não deve ver a peça do Usuário A
        res_list = await client.get(f"/api/v1/wardrobe/items?user_id={user_b_id}")
        assert res_list.status_code == 200
        items_b = res_list.json()
        assert len(items_b) == 0

        # 2. Usuário B tenta excluir a peça do Usuário A e recebe 403 Forbidden
        res_del = await client.delete(f"/api/v1/wardrobe/items/{item_a_id}?user_id={user_b_id}")
        assert res_del.status_code == 403
        assert "Acesso negado" in res_del.json()["detail"]

        # 3. Usuário A lista suas peças e encontra sua peça
        res_list_a = await client.get(f"/api/v1/wardrobe/items?user_id={user_a_id}")
        assert res_list_a.status_code == 200
        items_a = res_list_a.json()
        assert len(items_a) == 1
        assert items_a[0]["id"] == str(item_a_id)
