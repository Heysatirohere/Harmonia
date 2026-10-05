"""
Testes do Feed Comunitário (RF14, RF15) e da privacidade por perfil e por post (RN05).
As consultas do feed rodam pelo tests.sql_eval, que avalia o WHERE de verdade.
"""

import uuid
from datetime import datetime, timedelta, timezone

import httpx
import pytest
from httpx import ASGITransport

from app.main import app
from app.models.entities import ClothingItem, LookFeedback, User
from tests.test_api_endpoints import (  # noqa: F401 (setup_test_environment é autouse)
    _photo_url,
    auth_headers,
    setup_test_environment,
    store,
    supabase_admin,
)


def member(name="Ana", body_shape="AMPULHETA", palette="OUTONO_QUENTE", public=True):
    user_id = uuid.uuid4()
    store.users[user_id] = User(
        id=user_id, email=f"{user_id}@harmonia.app", hashed_password="managed_by_supabase_auth",
        body_shape=body_shape, seasonal_palette=palette, is_premium=False, is_public=public,
        items_count=0, looks_generated_today=0, looks_signatures_today=[], display_name=name,
        created_at=datetime.now(timezone.utc),
    )
    return user_id


def headers(user_id, name=None):
    return auth_headers(user_id, user_metadata={"full_name": name}) if name else auth_headers(user_id)


def photo(user_id, name="look.jpg"):
    return _photo_url(f"{user_id}/{name}")


def new_post(user_id, caption="Linho cru para o escritório", **extra):
    return {"image_url": photo(user_id), "caption": caption, "occasion": "trabalho", **extra}


async def call(method, path, user_id, json=None, params=None, name=None):
    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        return await client.request(
            method, f"/api/v1/community{path}", json=json, params=params, headers=headers(user_id, name)
        )


async def publish(user_id, **payload):
    response = await call("POST", "/posts", user_id, json=new_post(user_id, **payload))
    assert response.status_code == 201, response.text
    return response.json()


async def feed(user_id, **params):
    response = await call("GET", "/posts", user_id, params=params)
    assert response.status_code == 200, response.text
    return response.json()


def captions(page):
    return [p["caption"] for p in page["posts"]]


# -----------------------------------------------------------------------------
# Publicação (RF14)
# -----------------------------------------------------------------------------

@pytest.mark.anyio
async def test_published_look_shows_in_the_feed_with_the_author_name():
    ana = member(name=None)
    response = await call("POST", "/posts", ana, json=new_post(ana, style_tags=["#Minimal", "minimal", " Linho "]), name="Ana Souza")
    assert response.status_code == 201
    post = response.json()
    assert post["author_name"] == "Ana Souza"         # vem do token e fica gravado
    assert post["occasion"] == "TRABALHO"
    assert post["style_tags"] == ["Minimal", "Linho"]  # sem # e sem repetidas
    assert post["is_mine"] and post["is_public"]
    assert (post["like_count"], post["liked_by_me"], post["saved_by_me"]) == (0, False, False)
    assert post["ihe_percentage"] is None and post["pieces"] == []

    bia = member("Bia")
    assert captions(await feed(bia)) == ["Linho cru para o escritório"]
    assert (await feed(bia))["posts"][0]["author_name"] == "Ana Souza"


@pytest.mark.anyio
@pytest.mark.parametrize(
    "url",
    [
        "https://elsewhere.example.com/look.jpg",
        "OTHER_USER",                       # pasta de outra pessoa
        "SUBFOLDER",                        # subpasta: a exclusão da conta não a enxergaria
    ],
)
async def test_photo_must_be_in_the_authors_folder(url):
    ana = member()
    if url == "OTHER_USER":
        url = photo(uuid.uuid4())
    elif url == "SUBFOLDER":
        url = _photo_url(f"{ana}/posts/look.jpg")
    response = await call("POST", "/posts", ana, json={**new_post(ana), "image_url": url})
    assert response.status_code == 422


@pytest.mark.anyio
async def test_blank_caption_and_long_tags_are_rejected():
    ana = member()
    assert (await call("POST", "/posts", ana, json=new_post(ana, caption="   "))).status_code == 422
    assert (await call("POST", "/posts", ana, json=new_post(ana, style_tags=["x" * 25]))).status_code == 422
    assert (await call("POST", "/posts", ana, json=new_post(ana, style_tags=list("abcdef")))).status_code == 422


def approved_look(user_id, action="APPROVED"):
    pieces = []
    for category, l_value in (("top", 60.0), ("bottom", 35.0)):
        piece = ClothingItem(
            id=uuid.uuid4(), user_id=user_id, category=category, subcategory=f"{category} linho",
            image_url=photo(user_id, f"{category}.png"), dominant_l=l_value, dominant_a=10.0, dominant_b=15.0,
            formality_score=0.6, is_archived=False, created_at=datetime.now(timezone.utc),
        )
        store.clothing_items[piece.id] = piece
        pieces.append(piece)
    feedback = LookFeedback(
        id=uuid.uuid4(), user_id=user_id, item_ids=[str(p.id) for p in pieces], action=action,
        occasion="CORPORATIVO", ihe_percentage=88.5, created_at=datetime.now(timezone.utc),
    )
    store.look_feedback[feedback.id] = feedback
    return feedback, pieces


@pytest.mark.anyio
async def test_post_from_an_approved_look_carries_its_pieces_and_ihe():
    """O selo ✦ vem do registro de aprovação no servidor, não de um número enviado pelo app."""
    ana = member()
    feedback, pieces = approved_look(ana)
    post = await publish(ana, feedback_id=str(feedback.id), occasion="casual")

    assert post["ihe_percentage"] == 88.5
    assert post["occasion"] == "CORPORATIVO"
    assert [p["id"] for p in post["pieces"]] == [str(p.id) for p in pieces]
    assert post["pieces"][0]["subcategory"] == "top linho"

    # Peça apagada do acervo depois some do post
    del store.clothing_items[pieces[0].id]
    [again] = (await feed(ana))["posts"]
    assert [p["id"] for p in again["pieces"]] == [str(pieces[1].id)]


@pytest.mark.anyio
@pytest.mark.parametrize("owner, action", [("other", "APPROVED"), ("self", "DISCARDED")])
async def test_only_own_approved_looks_can_be_attached(owner, action):
    ana = member()
    feedback, _ = approved_look(ana if owner == "self" else member(), action=action)
    response = await call("POST", "/posts", ana, json=new_post(ana, feedback_id=str(feedback.id)))
    assert response.status_code == 404


# -----------------------------------------------------------------------------
# Privacidade (RN05)
# -----------------------------------------------------------------------------

@pytest.mark.anyio
async def test_private_post_is_only_visible_to_its_author():
    ana, bia = member("Ana"), member("Bia")
    await publish(ana, caption="Só para mim", is_public=False)
    await publish(ana, caption="Para todos")

    assert captions(await feed(ana)) == ["Para todos", "Só para mim"]
    assert captions(await feed(bia)) == ["Para todos"]


@pytest.mark.anyio
async def test_private_profile_hides_even_public_posts():
    ana, bia = member("Ana"), member("Bia")
    await publish(ana, caption="Público", is_public=True)
    store.users[ana].is_public = False

    assert captions(await feed(bia)) == []
    assert captions(await feed(ana)) == ["Público"]


@pytest.mark.anyio
async def test_new_posts_follow_the_profile_visibility_by_default():
    ana = member(public=False)
    post = await publish(ana)
    assert post["is_public"] is False


@pytest.mark.anyio
async def test_invisible_posts_cannot_be_liked_or_saved():
    ana, bia = member("Ana"), member("Bia")
    hidden = await publish(ana, is_public=False)
    assert (await call("PUT", f"/posts/{hidden['id']}/like", bia)).status_code == 404
    assert (await call("PUT", f"/posts/{hidden['id']}/save", bia)).status_code == 404


# -----------------------------------------------------------------------------
# Busca e filtros (RF15)
# -----------------------------------------------------------------------------

@pytest.mark.anyio
async def test_filters_by_same_body_shape_and_palette():
    me = member("Eu", body_shape="AMPULHETA", palette="OUTONO_QUENTE")
    twin = member("Mesmo biótipo", body_shape="AMPULHETA", palette="INVERNO_FRIO")
    palette_twin = member("Mesma cartela", body_shape="RETANGULO", palette="OUTONO_QUENTE")
    await publish(twin, caption="biótipo")
    await publish(palette_twin, caption="cartela")

    assert captions(await feed(me, filter="body_shape")) == ["biótipo"]
    assert captions(await feed(me, filter="palette")) == ["cartela"]


@pytest.mark.anyio
async def test_trait_filters_are_empty_without_a_profile():
    me = member(body_shape=None, palette=None)
    await publish(member(), caption="qualquer")
    assert (await feed(me, filter="body_shape"))["posts"] == []
    assert (await feed(me, filter="palette"))["posts"] == []


@pytest.mark.anyio
async def test_filters_by_occasion_and_rejects_unknown_ones():
    me, ana = member(), member()
    await publish(ana, caption="trabalho")
    await publish(ana, caption="festa", occasion="festa")

    assert captions(await feed(me, occasion="Festa")) == ["festa"]
    assert (await call("GET", "/posts", me, params={"occasion": "piquenique"})).status_code == 422


@pytest.mark.anyio
async def test_search_matches_caption_and_tags_case_insensitive():
    me, ana = member(), member()
    await publish(ana, caption="Alfaiataria em LINHO", style_tags=["Minimal"])
    await publish(ana, caption="Vestido fluido", style_tags=["Boho", "Café"])
    await publish(ana, caption="Desconto de 100% no estilo")

    assert captions(await feed(me, q="linho")) == ["Alfaiataria em LINHO"]
    assert captions(await feed(me, q="boho")) == ["Vestido fluido"]
    assert captions(await feed(me, q="café")) == ["Vestido fluido"]
    # % e _ são literais na busca, não curingas
    assert captions(await feed(me, q="100%")) == ["Desconto de 100% no estilo"]
    assert captions(await feed(me, q="%")) == ["Desconto de 100% no estilo"]


@pytest.mark.anyio
async def test_mine_and_saved_filters():
    me, ana = member("Eu"), member("Ana")
    mine = await publish(me, caption="meu")
    theirs = await publish(ana, caption="dela")
    await publish(ana, caption="outro dela")
    await call("PUT", f"/posts/{theirs['id']}/save", me)

    assert captions(await feed(me, filter="mine")) == ["meu"]
    assert captions(await feed(me, filter="saved")) == ["dela"]
    assert mine["is_mine"] is True


@pytest.mark.anyio
async def test_saved_post_disappears_when_its_author_goes_private():
    me, ana = member(), member()
    post = await publish(ana)
    await call("PUT", f"/posts/{post['id']}/save", me)
    store.users[ana].is_public = False
    assert (await feed(me, filter="saved"))["posts"] == []


@pytest.mark.anyio
async def test_pagination_walks_the_feed_newest_first():
    me, ana = member(), member()
    for n in range(25):
        await publish(ana, caption=f"look {n}")

    first = await feed(me, limit=20)
    assert captions(first)[0] == "look 24" and len(first["posts"]) == 20
    assert first["next_before"] is not None

    second = await feed(me, limit=20, before=first["next_before"])
    assert captions(second) == [f"look {n}" for n in range(4, -1, -1)]
    assert second["next_before"] is None


# -----------------------------------------------------------------------------
# Curtir e salvar (RF14, Seção 3.5.2)
# -----------------------------------------------------------------------------

@pytest.mark.anyio
async def test_like_is_idempotent_and_counted_per_person():
    ana, bia, caio = member("Ana"), member("Bia"), member("Caio")
    post = await publish(ana)

    for _ in range(2):
        assert (await call("PUT", f"/posts/{post['id']}/like", bia)).status_code == 204
    await call("PUT", f"/posts/{post['id']}/like", caio)

    [seen_by_bia] = (await feed(bia))["posts"]
    [seen_by_ana] = (await feed(ana))["posts"]
    assert (seen_by_bia["like_count"], seen_by_bia["liked_by_me"]) == (2, True)
    assert (seen_by_ana["like_count"], seen_by_ana["liked_by_me"]) == (2, False)

    assert (await call("DELETE", f"/posts/{post['id']}/like", bia)).status_code == 204
    [after] = (await feed(bia))["posts"]
    assert (after["like_count"], after["liked_by_me"]) == (1, False)


@pytest.mark.anyio
async def test_saving_is_private_to_who_saved():
    ana, bia = member("Ana"), member("Bia")
    post = await publish(ana)
    await call("PUT", f"/posts/{post['id']}/save", bia)

    assert (await feed(bia))["posts"][0]["saved_by_me"] is True
    assert (await feed(ana))["posts"][0]["saved_by_me"] is False
    await call("DELETE", f"/posts/{post['id']}/save", bia)
    assert (await feed(bia))["posts"][0]["saved_by_me"] is False


# -----------------------------------------------------------------------------
# Exclusão (RN04)
# -----------------------------------------------------------------------------

@pytest.mark.anyio
async def test_deleting_a_post_removes_its_photo_likes_and_saves():
    ana, bia = member("Ana"), member("Bia")
    post = await publish(ana)
    await call("PUT", f"/posts/{post['id']}/like", bia)
    await call("PUT", f"/posts/{post['id']}/save", bia)

    assert (await call("DELETE", f"/posts/{post['id']}", bia)).status_code == 404   # só o autor
    assert (await call("DELETE", f"/posts/{post['id']}", ana)).status_code == 204

    assert supabase_admin.deleted_objects == [f"{ana}/look.jpg"]
    assert store.community_posts == {} and store.post_reactions == [] and store.saved_posts == []


@pytest.mark.anyio
async def test_post_stays_when_its_photo_cannot_be_removed():
    ana = member()
    post = await publish(ana)
    supabase_admin.fail_storage = True
    assert (await call("DELETE", f"/posts/{post['id']}", ana)).status_code == 502
    assert len(store.community_posts) == 1


@pytest.mark.anyio
async def test_account_deletion_removes_posts_photos_and_interactions():
    ana, bia = member("Ana"), member("Bia")
    ana_post = await publish(ana)
    bia_post = await publish(bia)
    await call("PUT", f"/posts/{ana_post['id']}/like", bia)   # curtida de outra pessoa no post dela
    await call("PUT", f"/posts/{bia_post['id']}/like", ana)   # curtida dela no post de outra pessoa
    await call("PUT", f"/posts/{bia_post['id']}/save", ana)

    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete("/api/v1/users/me", headers=auth_headers(ana))

    assert response.status_code == 204
    assert f"{ana}/look.jpg" in supabase_admin.deleted_objects
    assert [p.user_id for p in store.community_posts.values()] == [bia]
    assert store.post_reactions == [] and store.saved_posts == []


@pytest.mark.anyio
async def test_feed_requires_authentication():
    async with httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        assert (await client.get("/api/v1/community/posts")).status_code == 401
