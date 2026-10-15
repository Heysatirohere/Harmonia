"""Testes do backfill de vetores de estilo das peças antigas."""

import io
import uuid

from PIL import Image

from scripts.backfill_style_embeddings import BUCKET_PREFIX, embed_missing
from app.models.entities import ClothingItem


def piece(url, embedding=None):
    return ClothingItem(id=uuid.uuid4(), image_url=url, style_embedding=embedding)


def png():
    buffer = io.BytesIO()
    Image.new("RGBA", (20, 30), (30, 60, 160, 255)).save(buffer, format="PNG")
    return buffer.getvalue()


def test_embeds_only_pieces_without_vector_from_the_project_bucket():
    fetched = []

    def fetch(url):
        fetched.append(url)
        return png()

    new = piece(BUCKET_PREFIX + "u1/camisa.png")
    done = piece(BUCKET_PREFIX + "u1/calca.png", embedding=[0.1] * 512)
    foreign = piece("https://evil.example.com/x.png")

    vectors, failures = embed_missing([new, done, foreign], fetch, embed=lambda image: [1.0] * 512)

    assert list(vectors) == [str(new.id)]
    assert fetched == [new.image_url]
    assert failures == [(str(foreign.id), "foto fora do bucket do projeto")]


def test_a_broken_photo_does_not_stop_the_others():
    broken = piece(BUCKET_PREFIX + "u1/quebrada.png")
    good = piece(BUCKET_PREFIX + "u1/boa.png")

    def fetch(url):
        return b"nao e imagem" if url == broken.image_url else png()

    vectors, failures = embed_missing([broken, good], fetch, embed=lambda image: [1.0] * 512)

    assert list(vectors) == [str(good.id)]
    assert [f[0] for f in failures] == [str(broken.id)]
