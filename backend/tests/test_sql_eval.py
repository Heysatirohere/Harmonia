"""O avaliador do mock precisa concordar com o Postgres nas formas que o feed usa."""

import uuid
from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import Text, cast, desc, func, or_, select

from app.models.entities import CommunityPost, PostReaction, User
from tests.sql_eval import Evaluator, UnsupportedClause

T0 = datetime(2026, 10, 5, tzinfo=timezone.utc)


def post(user_id, minutes, caption="look", tags=(), public=True):
    return CommunityPost(
        id=uuid.uuid4(), user_id=user_id, image_url="x", caption=caption, occasion="CASUAL",
        style_tags=list(tags), item_ids=[], is_public=public, created_at=T0 + timedelta(minutes=minutes),
    )


@pytest.fixture
def db():
    alice = User(id=uuid.uuid4(), email="a", hashed_password="x", is_public=True, body_shape="AMPULHETA")
    bia = User(id=uuid.uuid4(), email="b", hashed_password="x", is_public=False, body_shape="AMPULHETA")
    posts = [
        post(alice.id, 1, "Alfaiataria em linho", ["Minimal"]),
        post(alice.id, 2, "Noite de gala", ["Gala"], public=False),
        post(bia.id, 3, "100% algodão", ["Café"]),
    ]
    reactions = [PostReaction(post_id=posts[0].id, user_id=u) for u in (alice.id, bia.id)]
    tables = {"users": [alice, bia], "community_posts": posts, "post_reactions": reactions}
    return Evaluator(lambda name: tables[name]), alice, bia, posts


def test_in_subquery_and_boolean_literals(db):
    ev, alice, bia, posts = db
    public_authors = select(User.id).where(User.is_public.is_(True))
    stmt = select(CommunityPost).where(CommunityPost.is_public.is_(True), CommunityPost.user_id.in_(public_authors))
    assert ev.select(stmt) == [posts[0]]


def test_or_order_and_limit(db):
    ev, alice, bia, posts = db
    stmt = (
        select(CommunityPost)
        .where(or_(CommunityPost.user_id == bia.id, CommunityPost.is_public.is_(False)))
        .order_by(desc(CommunityPost.created_at))
        .limit(1)
    )
    assert ev.select(stmt) == [posts[2]]


def test_ilike_is_case_insensitive_and_respects_escape(db):
    ev, *_, posts = db
    linho = select(CommunityPost).where(CommunityPost.caption.ilike("%LINHO%", escape="\\"))
    percent = select(CommunityPost).where(CommunityPost.caption.ilike("%100\\%%", escape="\\"))
    literal_percent_only = select(CommunityPost).where(CommunityPost.caption.ilike("%\\%%", escape="\\"))
    assert ev.select(linho) == [posts[0]]
    assert ev.select(percent) == [posts[2]]
    assert ev.select(literal_percent_only) == [posts[2]]


def test_jsonb_cast_keeps_accents_like_postgres(db):
    ev, *_, posts = db
    stmt = select(CommunityPost).where(cast(CommunityPost.style_tags, Text).ilike("%café%"))
    assert ev.select(stmt) == [posts[2]]


def test_count_with_group_by(db):
    ev, alice, bia, posts = db
    stmt = select(PostReaction.post_id, func.count()).group_by(PostReaction.post_id)
    assert ev.select(stmt) == [(posts[0].id, 2)]


def test_unknown_constructs_fail_loudly(db):
    ev, *_ = db
    with pytest.raises(UnsupportedClause):
        ev.select(select(CommunityPost).where(CommunityPost.caption.regexp_match("x")))
