"""
Testes de Integração Assíncronos da API RESTful do HarmonIA (httpx / AsyncClient)
Testa os Endpoints Health, Auth, Wardrobe (RN01, RN02, RF06) e Outfits/IHE (RN02, RF07, RF13).
"""

import uuid
from datetime import datetime, timedelta, timezone
import jwt
import pytest
import httpx
from cryptography.hazmat.primitives.asymmetric import ec
from httpx import ASGITransport

from app.main import app
from app.core import security
from app.core.config import settings
from app.core.database import get_db
from app.core.quota import quota_today
from app.core.supabase_admin import SupabaseAdminError, get_supabase_admin
from app.models.entities import User, ClothingItem, LookFeedback


TEST_SUPABASE_URL = "https://harmonia-test.supabase.co"
TEST_JWT_SECRET = "test-jwt-secret-with-at-least-32-bytes!!"


def make_token(user_id, email="user@harmonia.app", secret=TEST_JWT_SECRET, expires_in=3600, **overrides):
    """Gera um access token no formato emitido pelo Supabase Auth (HS256 legado)."""
    now = datetime.now(timezone.utc)
    claims = {
        "sub": str(user_id),
        "email": email,
        "aud": "authenticated",
        "role": "authenticated",
        "iss": f"{TEST_SUPABASE_URL}/auth/v1",
        "iat": now,
        "exp": now + timedelta(seconds=expires_in),
    }
    claims.update(overrides)
    return jwt.encode(claims, secret, algorithm="HS256")


def auth_headers(user_id, **kwargs):
    return {"Authorization": f"Bearer {make_token(user_id, **kwargs)}"}


# -----------------------------------------------------------------------------
# Repositório em Memória e Fake AsyncSession para Testes Isolados de API
# -----------------------------------------------------------------------------

class FakeSupabaseAdmin:
    """Dublê do Supabase administrativo: registra o que seria apagado e falha sob demanda."""

    def __init__(self):
        self.folder = {}
        self.deleted_objects = []
        self.deleted_auth_users = []
        self.fail_storage = False
        self.fail_auth = False

    def object_path(self, public_url):
        marker = f"{TEST_SUPABASE_URL}/storage/v1/object/public/wardrobe-items/"
        return public_url[len(marker):] if public_url.startswith(marker) else None

    async def list_user_objects(self, user_id):
        if self.fail_storage:
            raise SupabaseAdminError("storage fora do ar")
        return list(self.folder.get(user_id, []))

    async def delete_objects(self, paths):
        if self.fail_storage:
            raise SupabaseAdminError("storage fora do ar")
        self.deleted_objects.extend(sorted(paths))

    async def delete_auth_user(self, user_id):
        if self.fail_auth:
            raise SupabaseAdminError("auth fora do ar")
        self.deleted_auth_users.append(user_id)


supabase_admin = FakeSupabaseAdmin()


class InMemoryStore:
    def __init__(self):
        self.users = {}
        self.clothing_items = {}
        self.look_feedback = {}

    def clear(self):
        self.users.clear()
        self.clothing_items.clear()
        self.look_feedback.clear()


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
        # DELETEs em massa só valem no commit, como numa transação
        self.pending_deletes = []

    async def execute(self, statement):
        sql_text = str(statement).lower()

        # 0. DELETE em massa por usuário (exclusão de conta, RN04)
        if sql_text.startswith("delete from"):
            table = sql_text.split()[2]
            target = next(v for v in statement.compile().params.values() if isinstance(v, uuid.UUID))
            self.pending_deletes.append((table, target))
            return FakeExecuteResult([])

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
            # Busca por id/e-mail sem correspondência não encontra ninguém (como no banco real)
            if any(isinstance(p, uuid.UUID) or (isinstance(p, str) and "@" in p) for p in params.values()):
                return FakeExecuteResult([])
            return FakeExecuteResult(users_list)

        # 2.1 Feedback de looks (RF13)
        if "from look_feedback" in sql_text:
            params = statement.compile().params
            entries = list(self.store.look_feedback.values())
            for p_val in params.values():
                if isinstance(p_val, uuid.UUID):
                    entries = [e for e in entries if p_val in (e.id, e.user_id)]
                elif isinstance(p_val, str):
                    entries = [e for e in entries if e.action == p_val]
            return FakeExecuteResult(entries)

        # 3. Queries de Peças de Vestuário
        if "from clothing_items" in sql_text or "clothing_items." in sql_text:
            items_list = list(self.store.clothing_items.values())
            compiled = statement.compile()
            params = compiled.params if hasattr(compiled, "params") else {}

            user_id_param = None
            item_id_param = None
            category_param = None

            for p_key, p_val in params.items():
                if isinstance(p_val, uuid.UUID):
                    if "user_id" in p_key or p_val in self.store.users:
                        user_id_param = p_val
                    elif "id" in p_key:
                        item_id_param = p_val
                    elif any(i.id == p_val for i in items_list):
                        item_id_param = p_val
                    else:
                        item_id_param = p_val
                elif isinstance(p_val, str) and p_val in ["top", "bottom", "shoes", "one_piece", "outerwear"]:
                    category_param = p_val

            filtered = items_list
            # Filtro IN (lista de ids)
            for p_val in params.values():
                if isinstance(p_val, (list, tuple)) and p_val and isinstance(p_val[0], uuid.UUID):
                    filtered = [i for i in filtered if i.id in p_val]
            if item_id_param is not None:
                filtered = [i for i in filtered if i.id == item_id_param]
            elif user_id_param is not None:
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
        elif isinstance(instance, LookFeedback):
            self.store.look_feedback[instance.id] = instance

    async def delete(self, instance):
        if isinstance(instance, ClothingItem) and instance.id in self.store.clothing_items:
            del self.store.clothing_items[instance.id]
        elif isinstance(instance, LookFeedback):
            self.store.look_feedback.pop(instance.id, None)
        elif isinstance(instance, User) and instance.id in self.store.users:
            del self.store.users[instance.id]

    async def commit(self):
        for table, target in self.pending_deletes:
            if table == "users":
                self.store.users.pop(target, None)
            elif table == "clothing_items":
                for key in [k for k, v in self.store.clothing_items.items() if v.user_id == target]:
                    del self.store.clothing_items[key]
            elif table == "look_feedback":
                for key in [k for k, v in self.store.look_feedback.items() if v.user_id == target]:
                    del self.store.look_feedback[key]
        self.pending_deletes.clear()

    async def flush(self):
        pass

    async def refresh(self, instance):
        pass

    async def rollback(self):
        self.pending_deletes.clear()

    async def close(self):
        pass


async def override_get_db():
    session = MockAsyncSession()
    try:
        yield session
    finally:
        await session.close()


@pytest.fixture(autouse=True)
def setup_test_environment(monkeypatch):
    monkeypatch.setattr(settings, "SUPABASE_URL", TEST_SUPABASE_URL)
    monkeypatch.setattr(settings, "SUPABASE_JWT_SECRET", TEST_JWT_SECRET)
    store.clear()
    supabase_admin.__init__()
    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_supabase_admin] = lambda: supabase_admin
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
        response = await client.post(
            "/api/v1/outfits/calculate-ihe", json=payload, headers=auth_headers(uuid.uuid4())
        )

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
            "/api/v1/wardrobe/items",
            json=item_payload,
            headers=auth_headers(user_id),
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
        looks_counter_date=quota_today(),
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
            "/api/v1/outfits/calculate-ihe",
            json=payload,
            headers=auth_headers(user_id),
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
        res_list = await client.get("/api/v1/wardrobe/items", headers=auth_headers(user_b_id))
        assert res_list.status_code == 200
        items_b = res_list.json()
        assert len(items_b) == 0

        # 2. Usuário B tenta excluir a peça do Usuário A e recebe 403 Forbidden
        res_del = await client.delete(f"/api/v1/wardrobe/items/{item_a_id}", headers=auth_headers(user_b_id))
        assert res_del.status_code == 403
        assert "Acesso negado" in res_del.json()["detail"]

        # 3. Usuário A lista suas peças e encontra sua peça
        res_list_a = await client.get("/api/v1/wardrobe/items", headers=auth_headers(user_a_id))
        assert res_list_a.status_code == 200
        items_a = res_list_a.json()
        assert len(items_a) == 1
        assert items_a[0]["id"] == str(item_a_id)


@pytest.mark.anyio
async def test_generate_daily_outfits_endpoint():
    """
    Testa o endpoint /v1/outfits/generate-daily (RF07).
    Garante retorno de combinações ranqueadas pelo IHE com peças do acervo do usuário.
    """
    user_id = uuid.uuid4()
    user = User(
        id=user_id,
        email="daily.outfit.user@harmonia.app",
        hashed_password="pw",
        body_shape="AMPULHETA",
        seasonal_palette="OUTONO_QUENTE",
        style_vector=[0.1] * 512,
        is_premium=True,
        looks_generated_today=0,
        created_at=datetime.now(timezone.utc)
    )
    store.users[user_id] = user

    top = ClothingItem(
        id=uuid.uuid4(),
        user_id=user_id,
        category="top",
        subcategory="Camisa Linho",
        image_url="https://s3.amazonaws.com/top.png",
        dominant_l=55.0,
        dominant_a=20.0,
        dominant_b=20.0,
        formality_score=0.7,
        cut_type="acinturado",
        style_embedding=[0.1] * 512,
        is_archived=False,
        created_at=datetime.now(timezone.utc)
    )
    bottom = ClothingItem(
        id=uuid.uuid4(),
        user_id=user_id,
        category="bottom",
        subcategory="Pantalona",
        image_url="https://s3.amazonaws.com/bottom.png",
        dominant_l=40.0,
        dominant_a=5.0,
        dominant_b=15.0,
        formality_score=0.7,
        cut_type="reta",
        style_embedding=[0.1] * 512,
        is_archived=False,
        created_at=datetime.now(timezone.utc)
    )
    store.clothing_items[top.id] = top
    store.clothing_items[bottom.id] = bottom

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        payload = {
            "occasion": "CASUAL",
            "temperature_celsius": 24.0,
            "is_raining": False,
            "limit": 3
        }
        res = await client.post("/api/v1/outfits/generate-daily", json=payload, headers=auth_headers(user_id))
        assert res.status_code == 200
        data = res.json()
        assert len(data) >= 1
        best = data[0]
        assert "ihe_score" in best
        assert "s_cor" in best
        assert "s_bio" in best
        assert "styling_advice" in best
        assert len(best["items"]) >= 1



# -----------------------------------------------------------------------------
# Autenticação via JWT do Supabase (RF01, RNF02, RN01)
# -----------------------------------------------------------------------------

@pytest.mark.anyio
async def test_protected_endpoints_require_bearer_token():
    """Sem Authorization, as rotas protegidas respondem 401."""
    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        responses = [
            await client.get("/api/v1/wardrobe/items"),
            await client.delete(f"/api/v1/wardrobe/items/{uuid.uuid4()}"),
            await client.post("/api/v1/outfits/generate-daily", json={"occasion": "CASUAL"}),
        ]

    for response in responses:
        assert response.status_code == 401
        assert response.headers["www-authenticate"] == "Bearer"


@pytest.mark.anyio
async def test_x_user_id_header_is_not_trusted():
    """O header X-User-ID legado não concede acesso ao acervo de outro usuário (RN01)."""
    victim_id = uuid.uuid4()
    attacker_id = uuid.uuid4()
    for uid, email in ((victim_id, "victim@harmonia.app"), (attacker_id, "attacker@harmonia.app")):
        store.users[uid] = User(
            id=uid, email=email, hashed_password="pw", is_premium=True, created_at=datetime.now(timezone.utc)
        )
    victim_item = ClothingItem(
        id=uuid.uuid4(), user_id=victim_id, category="top", image_url="https://example.com/v.png",
        dominant_l=50.0, dominant_a=10.0, dominant_b=10.0, formality_score=0.5, is_archived=False,
        created_at=datetime.now(timezone.utc)
    )
    store.clothing_items[victim_item.id] = victim_item

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        anonymous = await client.get("/api/v1/wardrobe/items", headers={"X-User-ID": str(victim_id)})
        impersonating = await client.get(
            f"/api/v1/wardrobe/items?user_id={victim_id}",
            headers={"X-User-ID": str(victim_id), **auth_headers(attacker_id)},
        )

    assert anonymous.status_code == 401
    assert impersonating.status_code == 200
    assert impersonating.json() == []


@pytest.mark.anyio
@pytest.mark.parametrize(
    "token_kwargs, expected_detail",
    [
        ({"secret": "outro-segredo-que-nao-e-o-do-projeto!!"}, "Token de acesso inválido."),
        ({"expires_in": -60}, "Sessão expirada. Faça login novamente."),
        ({"aud": "anon"}, "Token de acesso inválido."),
        ({"iss": "https://outro-projeto.supabase.co/auth/v1"}, "Token de acesso inválido."),
        ({"sub": "nao-e-um-uuid"}, "Token de acesso sem identificador de usuário válido."),
    ],
)
async def test_rejects_invalid_tokens(token_kwargs, expected_detail):
    """Assinatura, expiração, audiência, emissor e `sub` são todos validados."""
    headers = auth_headers(uuid.uuid4(), **token_kwargs)

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/wardrobe/items", headers=headers)

    assert response.status_code == 401
    assert response.json()["detail"] == expected_detail


@pytest.mark.anyio
async def test_accepts_asymmetric_token_via_jwks(monkeypatch):
    """Tokens ES256 (chaves assimétricas do Supabase) são validados pela chave pública do JWKS."""
    private_key = ec.generate_private_key(ec.SECP256R1())
    requested_urls = []

    class FakeJwksClient:
        def get_signing_key_from_jwt(self, token):
            return jwt.PyJWK.from_dict(
                {**jwt.algorithms.ECAlgorithm.to_jwk(private_key.public_key(), as_dict=True), "alg": "ES256"}
            )

    def fake_jwks_client(url):
        requested_urls.append(url)
        return FakeJwksClient()

    monkeypatch.setattr(security, "_jwks_client", fake_jwks_client)
    monkeypatch.setattr(settings, "SUPABASE_JWT_SECRET", None)

    user_id = uuid.uuid4()
    now = datetime.now(timezone.utc)
    token = jwt.encode(
        {
            "sub": str(user_id),
            "email": "es256@harmonia.app",
            "aud": "authenticated",
            "iss": f"{TEST_SUPABASE_URL}/auth/v1",
            "exp": now + timedelta(hours=1),
        },
        private_key,
        algorithm="ES256",
        headers={"kid": "test-key"},
    )

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/wardrobe/items", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 200
    assert requested_urls == [f"{TEST_SUPABASE_URL}/auth/v1/.well-known/jwks.json"]


@pytest.mark.anyio
async def test_hs256_token_rejected_when_secret_not_configured(monkeypatch):
    """Sem SUPABASE_JWT_SECRET, tokens HS256 não são aceitos (evita confusão de algoritmo)."""
    monkeypatch.setattr(settings, "SUPABASE_JWT_SECRET", None)

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/wardrobe/items", headers=auth_headers(uuid.uuid4()))

    assert response.status_code == 401


@pytest.mark.anyio
async def test_profile_provisioned_from_verified_token_claims():
    """Usuário autenticado sem linha em public.users é provisionado com o e-mail do token."""
    user_id = uuid.uuid4()
    item_payload = {
        "category": "top",
        "image_url": "https://example.supabase.co/storage/v1/object/wardrobe-items/top.png",
        "dominant_l": 50.0,
        "dominant_a": 10.0,
        "dominant_b": 10.0,
        "formality_score": 0.5,
    }

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            "/api/v1/wardrobe/items",
            json=item_payload,
            headers=auth_headers(user_id, email="nova.conta@harmonia.app"),
        )

    assert response.status_code == 201
    assert store.users[user_id].email == "nova.conta@harmonia.app"
    assert store.users[user_id].items_count == 1


# -----------------------------------------------------------------------------
# Perfil de Estilo (RF02, RF18)
# -----------------------------------------------------------------------------

@pytest.mark.anyio
async def test_read_profile_before_onboarding():
    """Conta nova começa sem biótipo nem cartela e com o onboarding pendente."""
    user_id = uuid.uuid4()

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/users/me", headers=auth_headers(user_id, email="ana@harmonia.app"))

    assert response.status_code == 200
    data = response.json()
    assert data["id"] == str(user_id)
    assert data["email"] == "ana@harmonia.app"
    assert data["body_shape"] is None
    assert data["seasonal_palette"] is None
    assert data["onboarding_completed"] is False
    assert data["max_items_allowed"] == settings.FREEMIUM_MAX_CLOTHING_ITEMS
    assert data["max_daily_looks_allowed"] == settings.FREEMIUM_MAX_DAILY_LOOKS


@pytest.mark.anyio
async def test_update_profile_normalizes_and_completes_onboarding():
    """Os valores são salvos nas chaves do motor do IHE e completam o onboarding."""
    user_id = uuid.uuid4()
    headers = auth_headers(user_id)

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(
            "/api/v1/users/me",
            json={"body_shape": "Triângulo Invertido", "seasonal_palette": "outono quente"},
            headers=headers,
        )
        reread = await client.get("/api/v1/users/me", headers=headers)

    assert response.status_code == 200
    assert response.json()["body_shape"] == "TRIANGULO_INVERTIDO"
    assert response.json()["seasonal_palette"] == "OUTONO_QUENTE"
    assert response.json()["onboarding_completed"] is True
    assert reread.json()["body_shape"] == "TRIANGULO_INVERTIDO"
    assert store.users[user_id].seasonal_palette == "OUTONO_QUENTE"


@pytest.mark.anyio
async def test_partial_update_keeps_other_field():
    """Recalibrar só o biótipo mantém a cartela já salva."""
    user_id = uuid.uuid4()
    headers = auth_headers(user_id)

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        await client.patch(
            "/api/v1/users/me",
            json={"body_shape": "AMPULHETA", "seasonal_palette": "VERAO_FRIO"},
            headers=headers,
        )
        response = await client.patch("/api/v1/users/me", json={"body_shape": "OVAL"}, headers=headers)

    assert response.status_code == 200
    assert response.json()["body_shape"] == "OVAL"
    assert response.json()["seasonal_palette"] == "VERAO_FRIO"


@pytest.mark.anyio
@pytest.mark.parametrize(
    "payload",
    [{"body_shape": "PERA"}, {"seasonal_palette": "INVERNO_VIVO"}],
)
async def test_update_profile_rejects_unknown_values(payload):
    """Valores fora do vocabulário do motor do IHE são recusados com 422."""
    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch("/api/v1/users/me", json=payload, headers=auth_headers(uuid.uuid4()))

    assert response.status_code == 422


@pytest.mark.anyio
async def test_profile_requires_bearer_token():
    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        read = await client.get("/api/v1/users/me")
        update = await client.patch("/api/v1/users/me", json={"body_shape": "OVAL"})

    assert read.status_code == 401
    assert update.status_code == 401


# -----------------------------------------------------------------------------
# Cota diária de looks: vira o dia e só cobra consultas novas (RN02)
# -----------------------------------------------------------------------------

def _seed_wardrobe_user(looks_today=0, counter_date=None, premium=False, signatures=None):
    user_id = uuid.uuid4()
    store.users[user_id] = User(
        id=user_id,
        email=f"{user_id}@harmonia.app",
        hashed_password="managed_by_supabase_auth",
        body_shape="AMPULHETA",
        seasonal_palette="OUTONO_QUENTE",
        is_premium=premium,
        items_count=2,
        looks_generated_today=looks_today,
        looks_counter_date=counter_date,
        looks_signatures_today=signatures or [],
        created_at=datetime.now(timezone.utc),
    )
    for category, l_value in (("top", 60.0), ("bottom", 35.0)):
        item = ClothingItem(
            id=uuid.uuid4(),
            user_id=user_id,
            category=category,
            image_url=f"https://example.supabase.co/{category}.png",
            dominant_l=l_value,
            dominant_a=15.0,
            dominant_b=18.0,
            formality_score=0.4,
            is_archived=False,
            created_at=datetime.now(timezone.utc),
        )
        store.clothing_items[item.id] = item
    return user_id


async def _generate(client, user_id, occasion="CASUAL", temperature=22.0):
    return await client.post(
        "/api/v1/outfits/generate-daily",
        json={"occasion": occasion, "temperature_celsius": temperature, "is_raining": False, "limit": 3},
        headers=auth_headers(user_id),
    )


@pytest.mark.anyio
async def test_look_counter_resets_on_a_new_day():
    """O limite atingido ontem não bloqueia hoje."""
    user_id = _seed_wardrobe_user(looks_today=5, counter_date=quota_today() - timedelta(days=1))

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        profile = await client.get("/api/v1/users/me", headers=auth_headers(user_id))
        response = await _generate(client, user_id)

    assert profile.json()["looks_generated_today"] == 0
    assert response.status_code == 200
    assert store.users[user_id].looks_generated_today == 1
    assert store.users[user_id].looks_counter_date == quota_today()


@pytest.mark.anyio
async def test_repeating_the_same_query_does_not_spend_quota():
    """Reabrir o Look do Dia com a mesma ocasião e clima devolve os looks sem cobrar de novo."""
    user_id = _seed_wardrobe_user()

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        first = await _generate(client, user_id)
        again = await _generate(client, user_id)
        other_occasion = await _generate(client, user_id, occasion="TRABALHO")

    assert first.status_code == again.status_code == other_occasion.status_code == 200
    assert first.json() == again.json()
    assert store.users[user_id].looks_generated_today == 2


@pytest.mark.anyio
async def test_quota_reached_blocks_new_queries_but_not_repeats():
    """No limite, uma consulta já feita hoje continua disponível; uma nova é recusada."""
    user_id = _seed_wardrobe_user()

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        await _generate(client, user_id)
        store.users[user_id].looks_generated_today = settings.FREEMIUM_MAX_DAILY_LOOKS
        repeat = await _generate(client, user_id)
        new_query = await _generate(client, user_id, occasion="FESTA")

    assert repeat.status_code == 200
    assert new_query.status_code == 403
    assert "Limite da cota Freemium de combinações diárias atingido" in new_query.json()["detail"]


@pytest.mark.anyio
async def test_empty_wardrobe_does_not_spend_quota():
    user_id = uuid.uuid4()

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await _generate(client, user_id)

    assert response.status_code == 200
    assert response.json() == []
    assert store.users[user_id].looks_generated_today == 0


@pytest.mark.anyio
async def test_generate_rejects_unknown_occasion():
    user_id = _seed_wardrobe_user()

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await _generate(client, user_id, occasion="PIQUENIQUE")

    assert response.status_code == 422


# -----------------------------------------------------------------------------
# Paridade de Provador (RF08, RF09)
# -----------------------------------------------------------------------------

STORE_TOP = {
    "category": "Partes de cima",
    "dominant_l": 48.0,
    "dominant_a": 30.0,
    "dominant_b": 28.0,
    "occasion": "CASUAL",
}


@pytest.mark.anyio
async def test_store_parity_ranks_wardrobe_without_spending_quota():
    """A peça da loja é comparada com o acervo; nada é gravado e a cota não muda."""
    user_id = _seed_wardrobe_user()
    items_before = set(store.clothing_items)

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/outfits/store-parity", json=STORE_TOP, headers=auth_headers(user_id))

    assert response.status_code == 200
    data = response.json()
    assert data["looks_evaluated"] == 1  # a única parte de baixo do acervo
    assert len(data["matches"]) == 1
    match = data["matches"][0]
    assert match["item"]["category"] == "bottom"
    assert 0 < match["ihe_percentage"] <= 100
    assert match["rationale"]
    assert data["ihe_percentage"] == match["ihe_percentage"]
    assert data["palette_harmony"] is not None
    assert set(store.clothing_items) == items_before
    assert store.users[user_id].looks_generated_today == 0


@pytest.mark.anyio
async def test_store_parity_works_even_at_the_daily_limit():
    user_id = _seed_wardrobe_user(looks_today=settings.FREEMIUM_MAX_DAILY_LOOKS, counter_date=quota_today())

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/outfits/store-parity", json=STORE_TOP, headers=auth_headers(user_id))

    assert response.status_code == 200


@pytest.mark.anyio
async def test_store_parity_with_empty_wardrobe():
    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/outfits/store-parity", json=STORE_TOP, headers=auth_headers(uuid.uuid4()))

    assert response.status_code == 200
    data = response.json()
    assert data["matches"] == []
    assert data["ihe_percentage"] == 0.0
    assert data["palette_harmony"] is None  # conta nova, sem cartela


@pytest.mark.anyio
async def test_store_parity_isolates_other_users_wardrobes():
    """RN01: as peças de outra conta nunca entram no ranking."""
    owner = _seed_wardrobe_user()
    stranger = uuid.uuid4()

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/outfits/store-parity", json=STORE_TOP, headers=auth_headers(stranger))

    assert response.status_code == 200
    owner_ids = {str(i.id) for i in store.clothing_items.values() if i.user_id == owner}
    assert not owner_ids & {m["item"]["id"] for m in response.json()["matches"]}


@pytest.mark.anyio
async def test_store_parity_requires_bearer_token():
    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/outfits/store-parity", json=STORE_TOP)

    assert response.status_code == 401


@pytest.mark.anyio
async def test_temperature_change_within_band_does_not_spend_quota():
    """Com clima real a temperatura oscila; na mesma faixa do motor os looks são os mesmos e não há nova cobrança."""
    user_id = _seed_wardrobe_user()

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        morning = await _generate(client, user_id, temperature=18.2)
        afternoon = await _generate(client, user_id, temperature=23.9)
        hot = await _generate(client, user_id, temperature=29.0)

    assert morning.json() == afternoon.json()
    assert hot.status_code == 200
    assert store.users[user_id].looks_generated_today == 2



# -----------------------------------------------------------------------------
# Feedback de Recomendações (RF13)
# -----------------------------------------------------------------------------

def _wardrobe_ids(user_id):
    return [str(i.id) for i in store.clothing_items.values() if i.user_id == user_id]


def _feedback(item_ids, action="APPROVED", ihe=82.0):
    return {"item_ids": item_ids, "action": action, "occasion": "casual", "ihe_percentage": ihe}


@pytest.mark.anyio
async def test_approving_a_look_records_feedback():
    user_id = _seed_wardrobe_user()
    look = _wardrobe_ids(user_id)

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/outfits/feedback", json=_feedback(look), headers=auth_headers(user_id))

    assert response.status_code == 201
    data = response.json()
    assert data["action"] == "APPROVED"
    assert data["occasion"] == "CASUAL"
    assert sorted(data["item_ids"]) == sorted(look)
    entry = store.look_feedback[uuid.UUID(data["id"])]
    assert entry.user_id == user_id


@pytest.mark.anyio
async def test_discarded_look_is_not_suggested_again():
    """Retroalimentação: o look descartado some das próximas gerações."""
    user_id = _seed_wardrobe_user()
    # Segunda parte de baixo: dois looks possíveis
    second_bottom = ClothingItem(
        id=uuid.uuid4(), user_id=user_id, category="bottom", image_url="https://example.supabase.co/bottom2.png",
        dominant_l=70.0, dominant_a=-10.0, dominant_b=5.0, formality_score=0.4, is_archived=False,
        created_at=datetime.now(timezone.utc),
    )
    store.clothing_items[second_bottom.id] = second_bottom
    headers = auth_headers(user_id)

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        before = (await _generate(client, user_id)).json()
        best = sorted(item["id"] for item in before[0]["items"])
        await client.post("/api/v1/outfits/feedback", json=_feedback(best, "DISCARDED"), headers=headers)
        after = (await _generate(client, user_id)).json()

    assert best not in [sorted(item["id"] for item in look["items"]) for look in after]
    assert len(before) == 2
    assert len(after) == 1
    # Gerar de novo depois do descarte é uma consulta nova
    assert store.users[user_id].looks_generated_today == 2


@pytest.mark.anyio
async def test_undoing_a_discard_brings_the_look_back():
    user_id = _seed_wardrobe_user()
    look = _wardrobe_ids(user_id)
    headers = auth_headers(user_id)

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        created = await client.post("/api/v1/outfits/feedback", json=_feedback(look, "DISCARDED"), headers=headers)
        assert (await _generate(client, user_id)).json() == []
        undo = await client.delete(f"/api/v1/outfits/feedback/{created.json()['id']}", headers=headers)
        again = await _generate(client, user_id)

    assert undo.status_code == 204
    assert len(again.json()) == 1


@pytest.mark.anyio
async def test_feedback_rejects_pieces_from_another_wardrobe():
    """RN01: não se registra feedback com peças de outra conta, nem se apaga o feedback alheio."""
    owner = _seed_wardrobe_user()
    stranger = _seed_wardrobe_user()

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        foreign = await client.post(
            "/api/v1/outfits/feedback",
            json=_feedback(_wardrobe_ids(owner)[:1] + _wardrobe_ids(stranger)[:1]),
            headers=auth_headers(stranger),
        )
        own = await client.post("/api/v1/outfits/feedback", json=_feedback(_wardrobe_ids(owner)), headers=auth_headers(owner))
        steal = await client.delete(f"/api/v1/outfits/feedback/{own.json()['id']}", headers=auth_headers(stranger))

    assert foreign.status_code == 404
    assert steal.status_code == 404
    assert uuid.UUID(own.json()["id"]) in store.look_feedback


@pytest.mark.anyio
@pytest.mark.parametrize(
    "payload",
    [
        {"item_ids": [], "action": "APPROVED", "ihe_percentage": 80},
        {"item_ids": [str(uuid.uuid4())], "action": "LIKED", "ihe_percentage": 80},
        {"item_ids": [str(uuid.uuid4())] * 2, "action": "APPROVED", "ihe_percentage": 80},
    ],
)
async def test_feedback_validates_payload(payload):
    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/outfits/feedback", json=payload, headers=auth_headers(uuid.uuid4()))

    assert response.status_code == 422



# -----------------------------------------------------------------------------
# Direito ao Esquecimento (RN04)
# -----------------------------------------------------------------------------

def _photo_url(path):
    return f"{TEST_SUPABASE_URL}/storage/v1/object/public/wardrobe-items/{path}"


@pytest.mark.anyio
async def test_account_deletion_purges_photos_records_and_login():
    """Fotos (antigas e da pasta do usuário), peças, feedback, perfil e login somem."""
    user_id = _seed_wardrobe_user()
    items = [i for i in store.clothing_items.values() if i.user_id == user_id]
    items[0].image_url = _photo_url("garments/legacy_top.png")
    items[1].image_url = _photo_url(f"{user_id}/bottom.png")
    supabase_admin.folder[user_id] = [f"{user_id}/bottom.png", f"{user_id}/orphan.png"]
    other = _seed_wardrobe_user()
    headers = auth_headers(user_id)

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        await client.post("/api/v1/outfits/feedback", json=_feedback(_wardrobe_ids(user_id)), headers=headers)
        response = await client.delete("/api/v1/users/me", headers=headers)

    assert response.status_code == 204
    assert supabase_admin.deleted_objects == sorted(
        ["garments/legacy_top.png", f"{user_id}/bottom.png", f"{user_id}/orphan.png"]
    )
    assert supabase_admin.deleted_auth_users == [user_id]
    assert user_id not in store.users
    assert not [i for i in store.clothing_items.values() if i.user_id == user_id]
    assert not [f for f in store.look_feedback.values() if f.user_id == user_id]
    # Outra conta intacta (RN01)
    assert other in store.users
    assert len([i for i in store.clothing_items.values() if i.user_id == other]) == 2


@pytest.mark.anyio
async def test_storage_failure_deletes_nothing():
    user_id = _seed_wardrobe_user()
    supabase_admin.fail_storage = True

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete("/api/v1/users/me", headers=auth_headers(user_id))

    assert response.status_code == 502
    assert "Nada foi excluído" in response.json()["detail"]
    assert user_id in store.users
    assert supabase_admin.deleted_auth_users == []


@pytest.mark.anyio
async def test_auth_failure_rolls_back_records_and_retry_completes():
    user_id = _seed_wardrobe_user()
    headers = auth_headers(user_id)
    supabase_admin.fail_auth = True

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        failed = await client.delete("/api/v1/users/me", headers=headers)
        assert failed.status_code == 502
        assert user_id in store.users
        assert len([i for i in store.clothing_items.values() if i.user_id == user_id]) == 2

        supabase_admin.fail_auth = False
        retried = await client.delete("/api/v1/users/me", headers=headers)

    assert retried.status_code == 204
    assert user_id not in store.users
    assert supabase_admin.deleted_auth_users == [user_id]


@pytest.mark.anyio
async def test_deleting_a_garment_removes_its_photo():
    user_id = _seed_wardrobe_user()
    item = next(i for i in store.clothing_items.values() if i.user_id == user_id)
    item.image_url = _photo_url(f"{user_id}/top.png")

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"/api/v1/wardrobe/items/{item.id}", headers=auth_headers(user_id))

    assert response.status_code == 204
    assert supabase_admin.deleted_objects == [f"{user_id}/top.png"]
    assert item.id not in store.clothing_items


@pytest.mark.anyio
async def test_garment_stays_when_its_photo_cannot_be_removed():
    user_id = _seed_wardrobe_user()
    item = next(i for i in store.clothing_items.values() if i.user_id == user_id)
    item.image_url = _photo_url(f"{user_id}/top.png")
    supabase_admin.fail_storage = True

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"/api/v1/wardrobe/items/{item.id}", headers=auth_headers(user_id))

    assert response.status_code == 502
    assert item.id in store.clothing_items


@pytest.mark.anyio
async def test_account_deletion_without_admin_key_is_unavailable(monkeypatch):
    """Sem a service role key o servidor recusa com 503 em vez de apagar pela metade."""
    app.dependency_overrides.pop(get_supabase_admin)
    monkeypatch.setattr(settings, "SUPABASE_SERVICE_ROLE_KEY", None)
    user_id = _seed_wardrobe_user()

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete("/api/v1/users/me", headers=auth_headers(user_id))

    assert response.status_code == 503
    assert user_id in store.users


@pytest.mark.anyio
async def test_update_clothing_item_attributes_and_multi_tenant():
    """
    Testa o endpoint PATCH /v1/wardrobe/items/{item_id} (RF05, 3.2.3).
    Valida atualização de atributos e isolamento Multi-Tenant estrito (RN01).
    """
    user_a_id = uuid.uuid4()
    user_b_id = uuid.uuid4()
    store.users[user_a_id] = User(id=user_a_id, email="a@harmonia.app", hashed_password="pw", is_premium=True, created_at=datetime.now(timezone.utc))
    store.users[user_b_id] = User(id=user_b_id, email="b@harmonia.app", hashed_password="pw", is_premium=True, created_at=datetime.now(timezone.utc))

    item_id = uuid.uuid4()
    item = ClothingItem(
        id=item_id,
        user_id=user_a_id,
        category="top",
        subcategory="Camisa Linho",
        image_url="https://example.com/camisa.png",
        dominant_l=80.0,
        dominant_a=-5.0,
        dominant_b=15.0,
        formality_score=0.5,
        is_archived=False,
        created_at=datetime.now(timezone.utc),
    )
    store.clothing_items[item_id] = item

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # 1. Usuário B tenta atualizar peça do Usuário A -> 403 Forbidden (RN01)
        res_forbidden = await client.patch(
            f"/api/v1/wardrobe/items/{item_id}",
            json={"formality_score": 0.9, "subcategory": "Hackeada"},
            headers=auth_headers(user_b_id),
        )
        assert res_forbidden.status_code == 403
        assert "Acesso negado" in res_forbidden.json()["detail"]

        # 2. Usuário A atualiza com sucesso sua peça -> 200 OK
        res_update = await client.patch(
            f"/api/v1/wardrobe/items/{item_id}",
            json={"formality_score": 0.85, "subcategory": "Camisa Linho Fino", "cut_type": "Alfaiataria"},
            headers=auth_headers(user_a_id),
        )
        assert res_update.status_code == 200
        data = res_update.json()
        assert data["formality_score"] == 0.85
        assert data["subcategory"] == "Camisa Linho Fino"
        assert data["cut_type"] == "Alfaiataria"

        # 3. Tentativa de atualizar peça inexistente -> 404 Not Found
        res_404 = await client.patch(
            f"/api/v1/wardrobe/items/{uuid.uuid4()}",
            json={"subcategory": "Inexistente"},
            headers=auth_headers(user_a_id),
        )
        assert res_404.status_code == 404
