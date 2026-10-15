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
from app.models.entities import User, ClothingItem, LookFeedback, CommunityPost, PostReaction, SavedPost
from sqlalchemy.sql.selectable import Select
from tests.sql_eval import Evaluator


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
        # Feed comunitário: avaliado pelo tests.sql_eval, que interpreta o WHERE de verdade
        self.community_posts = {}
        self.post_reactions = []
        self.saved_posts = []

    def clear(self):
        self.users.clear()
        self.clothing_items.clear()
        self.look_feedback.clear()
        self.community_posts.clear()
        self.post_reactions.clear()
        self.saved_posts.clear()

    def rows(self, table):
        return {
            "users": lambda: list(self.users.values()),
            "clothing_items": lambda: list(self.clothing_items.values()),
            "look_feedback": lambda: list(self.look_feedback.values()),
            "community_posts": lambda: list(self.community_posts.values()),
            "post_reactions": lambda: list(self.post_reactions),
            "saved_posts": lambda: list(self.saved_posts),
        }[table]()

    def drop_post(self, post_id):
        """Apaga o post e, como o ON DELETE CASCADE do banco, as curtidas e os salvos dele."""
        self.community_posts.pop(post_id, None)
        self.post_reactions[:] = [r for r in self.post_reactions if r.post_id != post_id]
        self.saved_posts[:] = [r for r in self.saved_posts if r.post_id != post_id]


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

    def all(self):
        return list(self._data) if isinstance(self._data, list) else [self._data]


COMMUNITY_TABLES = {"community_posts", "post_reactions", "saved_posts"}


class MockAsyncSession:
    """Mock de AsyncSession do SQLAlchemy para testes isolados sem dependência de BD externo."""

    def __init__(self):
        self.store = store
        # DELETEs em massa só valem no commit, como numa transação
        self.pending_deletes = []
        self.pending_community_deletes = []
        self.evaluator = Evaluator(self.store.rows)

    async def execute(self, statement):
        sql_text = str(statement).lower()

        # Feed comunitário: consulta e DELETE avaliados pela semântica real do SQL
        table = statement.table.name if sql_text.startswith("delete from") else (
            statement.get_final_froms()[0].name if isinstance(statement, Select) else None
        )
        if table in COMMUNITY_TABLES:
            if sql_text.startswith("delete from"):
                rows = self.evaluator.matching_rows(table, statement.whereclause)
                self.pending_community_deletes.append((table, rows))
                return FakeExecuteResult([])
            return FakeExecuteResult(self.evaluator.select(statement))

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
        elif isinstance(instance, CommunityPost):
            self.store.community_posts[instance.id] = instance
        elif isinstance(instance, PostReaction):
            self.store.post_reactions.append(instance)
        elif isinstance(instance, SavedPost):
            self.store.saved_posts.append(instance)

    async def delete(self, instance):
        if isinstance(instance, ClothingItem) and instance.id in self.store.clothing_items:
            del self.store.clothing_items[instance.id]
        elif isinstance(instance, LookFeedback):
            self.store.look_feedback.pop(instance.id, None)
        elif isinstance(instance, User) and instance.id in self.store.users:
            del self.store.users[instance.id]
        elif isinstance(instance, CommunityPost):
            self.store.drop_post(instance.id)

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
        for table, rows in self.pending_community_deletes:
            if table == "community_posts":
                for post in rows:
                    self.store.drop_post(post.id)
            else:
                getattr(self.store, table)[:] = [r for r in getattr(self.store, table) if r not in rows]
        self.pending_community_deletes.clear()

    async def flush(self):
        pass

    async def refresh(self, instance):
        pass

    async def rollback(self):
        self.pending_deletes.clear()
        self.pending_community_deletes.clear()

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


# -----------------------------------------------------------------------------
# Lacunas do Acervo e Afiliação (RF11, RF12, RN03)
# -----------------------------------------------------------------------------

@pytest.mark.anyio
async def test_gaps_rank_partner_pieces_without_spending_quota():
    user_id = _seed_wardrobe_user()
    items_before = set(store.clothing_items)

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/outfits/gaps", headers=auth_headers(user_id))

    assert response.status_code == 200
    data = response.json()
    assert data["occasion"] == "CASUAL"
    assert data["baseline_ihe_percentage"] is not None
    assert 0 < len(data["gaps"]) <= 3
    for gap in data["gaps"]:
        assert gap["strong_looks"] > 0 or gap["delta_ihe"] >= 0
        assert gap["color_hex"].startswith("#")
        for product in gap["products"]:
            assert product["store"] in {"CEA", "RENNER"}
            assert "utm_source=harmonia" in product["url"]
            assert f"utm_content={gap['id']}" in product["url"]
    assert set(store.clothing_items) == items_before
    assert store.users[user_id].looks_generated_today == 0


@pytest.mark.anyio
async def test_gaps_never_list_out_of_stock_products_rn03():
    """A camiseta preta da Renner está esgotada no catálogo: nunca pode sair na resposta."""
    user_id = _seed_wardrobe_user()

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/outfits/gaps?limit=5", headers=auth_headers(user_id))

    product_ids = {p["id"] for gap in response.json()["gaps"] for p in gap["products"]}
    assert "renner-camiseta-preta" not in product_ids


@pytest.mark.anyio
async def test_gaps_of_an_empty_wardrobe():
    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/outfits/gaps", headers=auth_headers(uuid.uuid4()))

    assert response.status_code == 200
    assert response.json()["gaps"] == []
    assert response.json()["baseline_ihe_percentage"] is None


@pytest.mark.anyio
async def test_gaps_ignore_other_users_wardrobes():
    """RN01: o acervo de outra conta não cria lacunas para ninguém."""
    _seed_wardrobe_user()

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/outfits/gaps", headers=auth_headers(uuid.uuid4()))

    assert response.json()["gaps"] == []


@pytest.mark.anyio
async def test_gaps_reject_unknown_occasion():
    user_id = _seed_wardrobe_user()

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/outfits/gaps?occasion=PIQUENIQUE", headers=auth_headers(user_id))

    assert response.status_code == 422


@pytest.mark.anyio
async def test_gaps_require_bearer_token():
    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/outfits/gaps")

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
async def test_duplicate_garments_keep_the_shared_photo_until_the_last_one():
    """Cadastros repetidos dividem a foto: apagar uma cópia não pode deixar a outra sem imagem."""
    user_id = _seed_wardrobe_user()
    first, second = [i for i in store.clothing_items.values() if i.user_id == user_id]
    first.image_url = second.image_url = _photo_url(f"{user_id}/top.png")
    headers = auth_headers(user_id)

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        copy = await client.delete(f"/api/v1/wardrobe/items/{first.id}", headers=headers)
        assert copy.status_code == 204
        assert supabase_admin.deleted_objects == []

        last = await client.delete(f"/api/v1/wardrobe/items/{second.id}", headers=headers)

    assert last.status_code == 204
    assert supabase_admin.deleted_objects == [f"{user_id}/top.png"]


@pytest.mark.anyio
async def test_another_users_copy_does_not_protect_the_photo():
    """RN01: só peças do próprio usuário contam como donas da foto."""
    user_id = _seed_wardrobe_user()
    other_id = _seed_wardrobe_user()
    item = next(i for i in store.clothing_items.values() if i.user_id == user_id)
    stranger = next(i for i in store.clothing_items.values() if i.user_id == other_id)
    item.image_url = stranger.image_url = _photo_url(f"{user_id}/top.png")

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"/api/v1/wardrobe/items/{item.id}", headers=auth_headers(user_id))

    assert response.status_code == 204
    assert supabase_admin.deleted_objects == [f"{user_id}/top.png"]


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


@pytest.mark.anyio
async def test_update_user_privacy_mode_rn05():
    """
    Testa a alternância do Modo de Privacidade: Público vs Privado (RN05).
    """
    user_id = uuid.uuid4()
    store.users[user_id] = User(
        id=user_id,
        email="privacy@harmonia.app",
        hashed_password="pw",
        is_premium=False,
        is_public=True,
        items_count=0,
        looks_generated_today=0,
        created_at=datetime.now(timezone.utc),
    )

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # 1. Altera visibilidade para Privado
        res_private = await client.patch(
            "/api/v1/users/me",
            json={"is_public": False},
            headers=auth_headers(user_id),
        )
        assert res_private.status_code == 200
        assert res_private.json()["is_public"] is False

        # 2. Altera de volta para Público
        res_public = await client.patch(
            "/api/v1/users/me",
            json={"is_public": True},
            headers=auth_headers(user_id),
        )
        assert res_public.status_code == 200
        assert res_public.json()["is_public"] is True



# -----------------------------------------------------------------------------
# Saúde do Acervo (Seção 3.2.2)
# -----------------------------------------------------------------------------

def _age_items(user_id, days):
    """Cadastra as peças do usuário `days` dias atrás."""
    for item in store.clothing_items.values():
        if item.user_id == user_id:
            item.created_at = datetime.now(timezone.utc) - timedelta(days=days)


def _approve(user_id, item_ids, days_ago, action="APPROVED"):
    entry = LookFeedback(
        id=uuid.uuid4(),
        user_id=user_id,
        item_ids=[str(i) for i in item_ids],
        action=action,
        occasion="CASUAL",
        ihe_percentage=80.0,
        created_at=datetime.now(timezone.utc) - timedelta(days=days_ago),
    )
    store.look_feedback[entry.id] = entry
    return entry


@pytest.mark.anyio
async def test_analytics_derives_rotation_from_approved_looks():
    user_id = _seed_wardrobe_user()
    _age_items(user_id, 120)
    top, bottom = sorted(
        (i for i in store.clothing_items.values() if i.user_id == user_id), key=lambda i: i.category, reverse=True
    )
    _approve(user_id, [top.id, bottom.id], days_ago=100)
    _approve(user_id, [top.id], days_ago=5)
    # Descartes não são uso
    _approve(user_id, [bottom.id], days_ago=1, action="DISCARDED")

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/wardrobe/analytics", headers=auth_headers(user_id))

    assert response.status_code == 200
    data = response.json()
    assert data["total_pieces"] == 2
    assert (data["active_count"], data["idle_30_count"], data["idle_60_count"], data["dormant_count"]) == (1, 0, 0, 1)
    assert data["total_wears"] == 3
    assert data["never_worn_count"] == 0
    [dormant] = data["dormant_items"]
    assert dormant["item"]["id"] == str(bottom.id)
    assert dormant["wear_count"] == 1
    assert dormant["days_idle"] == 100
    assert sum(c["percentage"] for c in data["color_distribution"]) == pytest.approx(100.0)


@pytest.mark.anyio
async def test_analytics_ignores_other_users_pieces_and_looks():
    """RN01: peças e aprovações de outra conta não entram na conta de ninguém."""
    user_id = _seed_wardrobe_user()
    other_id = _seed_wardrobe_user()
    _age_items(user_id, 200)
    _approve(other_id, _wardrobe_ids(user_id), days_ago=1)

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/wardrobe/analytics", headers=auth_headers(user_id))

    data = response.json()
    assert data["total_pieces"] == 2
    assert data["dormant_count"] == 2
    assert data["total_wears"] == 0
    assert data["never_worn_count"] == 2
    assert {d["item"]["user_id"] for d in data["dormant_items"]} == {str(user_id)}


@pytest.mark.anyio
async def test_undoing_an_approval_removes_the_wear():
    user_id = _seed_wardrobe_user()
    _age_items(user_id, 120)
    look = _wardrobe_ids(user_id)

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        approval = await client.post("/api/v1/outfits/feedback", json=_feedback(look), headers=auth_headers(user_id))
        worn = (await client.get("/api/v1/wardrobe/analytics", headers=auth_headers(user_id))).json()
        await client.delete(f"/api/v1/outfits/feedback/{approval.json()['id']}", headers=auth_headers(user_id))
        undone = (await client.get("/api/v1/wardrobe/analytics", headers=auth_headers(user_id))).json()

    assert (worn["active_count"], worn["total_wears"]) == (2, 2)
    assert (undone["active_count"], undone["dormant_count"], undone["total_wears"]) == (0, 2, 0)


@pytest.mark.anyio
async def test_analytics_of_an_empty_wardrobe():
    user_id = _seed_wardrobe_user()
    for key in [k for k, v in store.clothing_items.items() if v.user_id == user_id]:
        del store.clothing_items[key]

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/wardrobe/analytics", headers=auth_headers(user_id))

    assert response.status_code == 200
    data = response.json()
    assert data["total_pieces"] == 0
    assert data["color_distribution"] == []
    assert data["dormant_items"] == []


@pytest.mark.anyio
async def test_item_list_carries_color_family_and_usage_for_filters():
    """RF06: cada peça vem com a família cromática e o uso, para filtrar por cor e frequência."""
    user_id = _seed_wardrobe_user()
    _age_items(user_id, 120)
    top = next(i for i in store.clothing_items.values() if i.user_id == user_id and i.category == "top")
    _approve(user_id, [top.id], days_ago=10)
    _approve(user_id, [top.id], days_ago=3)
    _approve(user_id, [top.id], days_ago=1, action="DISCARDED")

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/wardrobe/items", headers=auth_headers(user_id))

    assert response.status_code == 200
    by_category = {item["category"]: item for item in response.json()}
    assert (by_category["top"]["usage_rate"], by_category["top"]["days_idle"]) == (2, 3)
    assert by_category["top"]["last_worn_at"] is not None
    assert (by_category["bottom"]["usage_rate"], by_category["bottom"]["days_idle"]) == (0, 120)
    assert by_category["bottom"]["last_worn_at"] is None
    assert all(item["color_family"] for item in by_category.values())


@pytest.mark.anyio
async def test_item_usage_ignores_other_users_approvals():
    """RN01: aprovações de outra conta não contam como uso."""
    user_id = _seed_wardrobe_user()
    other_id = _seed_wardrobe_user()
    _approve(other_id, _wardrobe_ids(user_id), days_ago=1)

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/wardrobe/items", headers=auth_headers(user_id))

    assert {item["usage_rate"] for item in response.json()} == {0}


@pytest.mark.anyio
async def test_analytics_requires_authentication():
    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/wardrobe/analytics")
    assert response.status_code == 401


# -----------------------------------------------------------------------------
# Vetor de estilo (S_cos) aprendido com o feedback (RF13)
# -----------------------------------------------------------------------------

def _style_vec(axis):
    """Vetor dominado por um eixo comum, como os do CLIP, mais um eixo de estilo."""
    v = [0.0] * 512
    v[0], v[axis] = 1.0, 0.3
    norm = sum(x * x for x in v) ** 0.5
    return [x / norm for x in v]


def _seed_styled_wardrobe():
    """Duas partes de cima iguais em tudo menos no estilo, e uma parte de baixo neutra."""
    user_id = _seed_wardrobe_user()
    for key in [k for k, v in store.clothing_items.items() if v.user_id == user_id]:
        del store.clothing_items[key]
    pieces = {}
    for name, category, axis in (("minimal", "top", 1), ("boho", "top", 2), ("calca", "bottom", 3)):
        piece = ClothingItem(
            id=uuid.uuid4(), user_id=user_id, category=category,
            image_url=f"https://example.supabase.co/{name}.png",
            dominant_l=50.0, dominant_a=10.0, dominant_b=15.0, formality_score=0.4,
            style_embedding=_style_vec(axis), is_archived=False, created_at=datetime.now(timezone.utc),
        )
        store.clothing_items[piece.id] = piece
        pieces[name] = piece
    return user_id, pieces


def _looks_by_top(response, pieces):
    by_id = {str(p.id): name for name, p in pieces.items()}
    return {
        next(by_id[i["id"]] for i in look["items"] if by_id[i["id"]] != "calca"): look
        for look in response.json()
    }


@pytest.mark.anyio
async def test_approving_a_look_steers_the_next_suggestions():
    user_id, pieces = _seed_styled_wardrobe()

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        before = _looks_by_top(await _generate(client, user_id), pieces)
        approval = _feedback([str(pieces["minimal"].id), str(pieces["calca"].id)])
        await client.post("/api/v1/outfits/feedback", json=approval, headers=auth_headers(user_id))
        after = _looks_by_top(await _generate(client, user_id), pieces)

    # Sem histórico o pilar é neutro e as duas empatam
    assert before["minimal"]["s_cos"] == before["boho"]["s_cos"] == 0.5
    assert before["minimal"]["ihe_score"] == before["boho"]["ihe_score"]
    # Depois de aprovar, o estilo aprovado sobe e o outro desce
    assert after["minimal"]["s_cos"] > 0.5 > after["boho"]["s_cos"]
    assert after["minimal"]["ihe_score"] > after["boho"]["ihe_score"]


@pytest.mark.anyio
async def test_store_piece_vector_counts_in_parity():
    """A peça da loja no estilo que o usuário aprova forma looks com S_cos maior que uma no estilo oposto."""
    user_id, pieces = _seed_styled_wardrobe()
    store.look_feedback.clear()
    _approve(user_id, [pieces["minimal"].id, pieces["calca"].id], days_ago=1)

    def parity(axis):
        return {
            "category": "top", "dominant_l": 50.0, "dominant_a": 10.0, "dominant_b": 15.0,
            "formality_score": 0.4, "style_embedding": _style_vec(axis),
        }

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        like = await client.post("/api/v1/outfits/store-parity", json=parity(1), headers=auth_headers(user_id))
        unlike = await client.post("/api/v1/outfits/store-parity", json=parity(2), headers=auth_headers(user_id))

    assert like.status_code == unlike.status_code == 200
    assert like.json()["ihe_percentage"] > unlike.json()["ihe_percentage"]


@pytest.mark.anyio
async def test_store_parity_rejects_a_vector_of_the_wrong_size():
    user_id, _ = _seed_styled_wardrobe()
    payload = {"category": "top", "dominant_l": 50.0, "dominant_a": 10.0, "dominant_b": 15.0, "style_embedding": [0.1] * 10}

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/outfits/store-parity", json=payload, headers=auth_headers(user_id))

    assert response.status_code == 422
