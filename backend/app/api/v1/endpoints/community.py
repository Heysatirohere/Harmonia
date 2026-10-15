"""
Feed Comunitário (RF14, RF15) com privacidade por perfil e por post (RN05)

Quem vê o quê: o autor vê todos os próprios posts; os demais só veem um post se ele
e o perfil do autor forem públicos. Toda leitura passa por aqui, nunca direto no banco.
"""

from datetime import datetime, timezone
from typing import Dict, List, Literal, Optional, Set
from uuid import UUID
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import Text, and_, cast, delete, desc, func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.core.supabase_admin import SupabaseAdmin, SupabaseAdminError, get_supabase_admin, is_user_photo
from app.engine.context_rules import normalize_occasion
from app.models.entities import ClothingItem, CommunityPost, LookFeedback, PostReaction, SavedPost, User
from app.schemas.dtos import (
    CommunityFeedResponse,
    CommunityPostCreate,
    CommunityPostResponse,
    PostPieceResponse,
)

router = APIRouter()

FeedFilter = Literal["all", "body_shape", "palette", "saved", "mine"]
ANONYMOUS_AUTHOR = "Membro HarmonIA"


def _visible_to(user: User):
    """Condição SQL: posts que `user` pode ver (os próprios + públicos de perfis públicos)."""
    public_authors = select(User.id).where(User.is_public.is_(True))
    return or_(
        CommunityPost.user_id == user.id,
        and_(CommunityPost.is_public.is_(True), CommunityPost.user_id.in_(public_authors)),
    )


def _escape_like(text: str) -> str:
    return text.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


async def _visible_post(db: AsyncSession, user: User, post_id: UUID) -> CommunityPost:
    stmt = select(CommunityPost).where(CommunityPost.id == post_id, _visible_to(user))
    post = (await db.execute(stmt)).scalars().first()
    if post is None:
        # 404 e não 403: um post privado de outra pessoa não existe para quem pergunta
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Publicação não encontrada.")
    return post


async def _to_responses(db: AsyncSession, user: User, posts: List[CommunityPost]) -> List[CommunityPostResponse]:
    """Monta a resposta de uma página de posts com autores, peças, curtidas e salvos em poucas consultas."""
    if not posts:
        return []
    post_ids = [p.id for p in posts]

    author_ids = {p.user_id for p in posts}
    authors = {
        a.id: a for a in (await db.execute(select(User).where(User.id.in_(author_ids)))).scalars().all()
    }

    piece_ids = {UUID(i) for p in posts for i in p.item_ids}
    pieces: Dict[str, ClothingItem] = {}
    if piece_ids:
        rows = (await db.execute(select(ClothingItem).where(ClothingItem.id.in_(piece_ids)))).scalars().all()
        pieces = {str(i.id): i for i in rows}

    like_counts = dict((await db.execute(
        select(PostReaction.post_id, func.count())
        .where(PostReaction.post_id.in_(post_ids))
        .group_by(PostReaction.post_id)
    )).all())
    liked: Set[UUID] = set((await db.execute(
        select(PostReaction.post_id).where(PostReaction.user_id == user.id, PostReaction.post_id.in_(post_ids))
    )).scalars().all())
    saved: Set[UUID] = set((await db.execute(
        select(SavedPost.post_id).where(SavedPost.user_id == user.id, SavedPost.post_id.in_(post_ids))
    )).scalars().all())

    responses = []
    for post in posts:
        author = authors.get(post.user_id)
        responses.append(CommunityPostResponse(
            id=post.id,
            author_name=(author.display_name if author and author.display_name else ANONYMOUS_AUTHOR),
            author_body_shape=author.body_shape if author else None,
            author_palette=author.seasonal_palette if author else None,
            image_url=post.image_url,
            caption=post.caption,
            occasion=post.occasion,
            style_tags=list(post.style_tags or []),
            ihe_percentage=post.ihe_percentage,
            # Peças apagadas do acervo depois da publicação somem do post
            pieces=[PostPieceResponse.model_validate(pieces[i]) for i in post.item_ids if i in pieces],
            like_count=like_counts.get(post.id, 0),
            liked_by_me=post.id in liked,
            saved_by_me=post.id in saved,
            is_public=post.is_public,
            is_mine=post.user_id == user.id,
            created_at=post.created_at,
        ))
    return responses


@router.get("/posts", response_model=CommunityFeedResponse, status_code=status.HTTP_200_OK)
async def list_posts(
    filter: FeedFilter = Query(default="all", description="Recorte do feed (RF15)"),
    occasion: Optional[str] = Query(default=None, description="Só looks desta ocasião"),
    q: Optional[str] = Query(default=None, max_length=60, description="Busca na legenda e nas tags"),
    before: Optional[datetime] = Query(default=None, description="Paginação: posts anteriores a esta data"),
    limit: int = Query(default=20, ge=1, le=30),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Feed do mais recente para o mais antigo (RF14), com os recortes da Seção 3.5.3:
    pessoas com o mesmo biótipo ou a mesma cartela, os salvos (moodboard) e os próprios posts.
    """
    conditions = [_visible_to(user)]

    if filter in ("body_shape", "palette"):
        trait = User.body_shape if filter == "body_shape" else User.seasonal_palette
        mine = user.body_shape if filter == "body_shape" else user.seasonal_palette
        if mine is None:
            # Sem perfil definido não há com quem comparar
            return CommunityFeedResponse(posts=[], next_before=None)
        conditions.append(CommunityPost.user_id.in_(select(User.id).where(trait == mine)))
    elif filter == "saved":
        conditions.append(CommunityPost.id.in_(select(SavedPost.post_id).where(SavedPost.user_id == user.id)))
    elif filter == "mine":
        conditions.append(CommunityPost.user_id == user.id)

    if occasion:
        try:
            conditions.append(CommunityPost.occasion == normalize_occasion(occasion))
        except ValueError as exc:
            raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))

    if q and q.strip():
        pattern = f"%{_escape_like(q.strip())}%"
        conditions.append(or_(
            CommunityPost.caption.ilike(pattern, escape="\\"),
            cast(CommunityPost.style_tags, Text).ilike(pattern, escape="\\"),
        ))

    if before is not None:
        conditions.append(CommunityPost.created_at < before)

    stmt = (
        select(CommunityPost)
        .where(*conditions)
        .order_by(desc(CommunityPost.created_at), desc(CommunityPost.id))
        .limit(limit + 1)
    )
    page = list((await db.execute(stmt)).scalars().all())
    has_more = len(page) > limit
    page = page[:limit]

    return CommunityFeedResponse(
        posts=await _to_responses(db, user, page),
        next_before=page[-1].created_at if has_more else None,
    )


@router.post("/posts", response_model=CommunityPostResponse, status_code=status.HTTP_201_CREATED)
async def create_post(
    payload: CommunityPostCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Publica a foto de um look (RF14). A foto precisa estar na pasta do autor no Storage.
    Com `feedback_id`, peças, ocasião e IHE vêm do look aprovado: o selo ✦ do feed não
    pode ser inventado pelo app.
    """
    if not is_user_photo(payload.image_url, user.id):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="A foto precisa ser enviada pelo app antes da publicação.",
        )

    item_ids: List[str] = []
    ihe: Optional[float] = None
    occasion = payload.occasion
    if payload.feedback_id is not None:
        stmt = select(LookFeedback).where(
            LookFeedback.id == payload.feedback_id,
            LookFeedback.user_id == user.id,
            LookFeedback.action == "APPROVED",
        )
        look = (await db.execute(stmt)).scalars().first()
        if look is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Look aprovado não encontrado.")
        item_ids = [str(i) for i in look.item_ids]
        ihe = look.ihe_percentage
        occasion = look.occasion

    post = CommunityPost(
        id=uuid.uuid4(),
        user_id=user.id,
        image_url=payload.image_url,
        caption=payload.caption,
        occasion=occasion,
        style_tags=payload.style_tags,
        item_ids=item_ids,
        ihe_percentage=ihe,
        # Sem escolha explícita, o post segue a visibilidade do perfil (RN05)
        is_public=user.is_public if payload.is_public is None else payload.is_public,
        created_at=datetime.now(timezone.utc),
    )
    db.add(post)
    await db.commit()
    [response] = await _to_responses(db, user, [post])
    return response


@router.delete("/posts/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_post(
    post_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    admin: SupabaseAdmin = Depends(get_supabase_admin),
):
    """Apaga um post próprio e a foto dele no Storage; curtidas e salvos caem junto."""
    stmt = select(CommunityPost).where(CommunityPost.id == post_id, CommunityPost.user_id == user.id)
    post = (await db.execute(stmt)).scalars().first()
    if post is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Publicação não encontrada.")

    photo = admin.object_path(post.image_url)
    if photo:
        try:
            await admin.delete_objects([photo])
        except SupabaseAdminError:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Não foi possível apagar a foto agora. Tente novamente.",
            )
    await db.delete(post)
    await db.commit()


async def _mark(db: AsyncSession, user: User, post_id: UUID, model) -> Response:
    """Curtir ou salvar: idempotente, só em posts que o usuário pode ver."""
    await _visible_post(db, user, post_id)
    stmt = select(model).where(model.post_id == post_id, model.user_id == user.id)
    if (await db.execute(stmt)).scalars().first() is None:
        db.add(model(post_id=post_id, user_id=user.id, created_at=datetime.now(timezone.utc)))
        try:
            await db.commit()
        except IntegrityError:
            # Dois toques simultâneos: o outro já gravou, o resultado é o mesmo
            await db.rollback()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


async def _unmark(db: AsyncSession, user: User, post_id: UUID, model) -> Response:
    await db.execute(delete(model).where(model.post_id == post_id, model.user_id == user.id))
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.put("/posts/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
async def like_post(post_id: UUID, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    return await _mark(db, user, post_id, PostReaction)


@router.delete("/posts/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
async def unlike_post(post_id: UUID, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    return await _unmark(db, user, post_id, PostReaction)


@router.put("/posts/{post_id}/save", status_code=status.HTTP_204_NO_CONTENT)
async def save_post(post_id: UUID, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    """Salva no moodboard privado (Seção 3.5.2)."""
    return await _mark(db, user, post_id, SavedPost)


@router.delete("/posts/{post_id}/save", status_code=status.HTTP_204_NO_CONTENT)
async def unsave_post(post_id: UUID, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    return await _unmark(db, user, post_id, SavedPost)
