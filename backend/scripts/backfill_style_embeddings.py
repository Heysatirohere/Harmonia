"""
Gera o vetor de estilo (S_cos) das peças cadastradas antes dele existir.

Baixa o recorte PNG de cada peça sem vetor (só do bucket deste projeto), roda o mesmo
CLIP do /wardrobe/segment e grava em clothing_items.style_embedding.

Uso, de dentro de backend/:
    python -m scripts.backfill_style_embeddings            # só mostra o que faria
    python -m scripts.backfill_style_embeddings --apply    # grava no banco do DATABASE_URL
"""

import argparse
import asyncio
import io
from typing import Callable, Dict, Iterable, List, Optional, Tuple

import httpx
from PIL import Image
from sqlalchemy import select

from app.core.config import settings
from app.models.entities import ClothingItem
from app.vision.style_embedding import embed_garment

BUCKET_PREFIX = f"{settings.SUPABASE_URL.rstrip('/')}/storage/v1/object/public/{settings.SUPABASE_STORAGE_BUCKET}/"


def embed_missing(
    items: Iterable[ClothingItem],
    fetch: Callable[[str], bytes],
    embed: Callable[[Image.Image], List[float]] = embed_garment,
) -> Tuple[Dict[str, List[float]], List[Tuple[str, str]]]:
    """Vetores das peças sem vetor, por ID, e as peças que falharam com o motivo."""
    vectors: Dict[str, List[float]] = {}
    failures: List[Tuple[str, str]] = []
    for item in items:
        if item.style_embedding is not None:
            continue
        if not item.image_url.startswith(BUCKET_PREFIX):
            failures.append((str(item.id), "foto fora do bucket do projeto"))
            continue
        try:
            vectors[str(item.id)] = embed(Image.open(io.BytesIO(fetch(item.image_url))))
        except Exception as exc:  # Uma foto quebrada não interrompe as outras
            failures.append((str(item.id), str(exc)))
    return vectors, failures


async def main(apply: bool) -> None:
    from app.core.database import AsyncSessionLocal

    async with AsyncSessionLocal() as db:
        items = (await db.execute(select(ClothingItem).where(ClothingItem.style_embedding.is_(None)))).scalars().all()
        print(f"{len(items)} peças sem vetor de estilo")

        with httpx.Client(timeout=30.0) as client:
            def fetch(url: str) -> bytes:
                response = client.get(url)
                response.raise_for_status()
                return response.content

            vectors, failures = embed_missing(items, fetch)

        for item_id, reason in failures:
            print(f"  falhou {item_id}: {reason}")
        print(f"{len(vectors)} vetores gerados, {len(failures)} falhas")

        if not apply:
            print("Simulação: nada foi gravado. Rode com --apply para gravar.")
            return
        for item in items:
            vector: Optional[List[float]] = vectors.get(str(item.id))
            if vector is not None:
                item.style_embedding = vector
        await db.commit()
        print("Vetores gravados.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--apply", action="store_true", help="grava os vetores no banco")
    asyncio.run(main(parser.parse_args().apply))
