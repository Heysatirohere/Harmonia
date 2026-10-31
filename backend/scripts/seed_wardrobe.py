"""
Popula o banco de dados com um acervo variado de peças recortadas (PNG com canal alfa),
histórico de uso (LookFeedback) para o Dashboard de Rotação e publicações para o Feed Comunitário.

Uso, de dentro de backend/:
    .venv/bin/python -m scripts.seed_wardrobe
"""

import asyncio
from datetime import datetime, timedelta, timezone
import io
from typing import List, Tuple
import uuid

import httpx
import numpy as np
from PIL import Image, ImageDraw
from sqlalchemy import select

from app.core.config import settings
from app.core.database import AsyncSessionLocal
from app.main import ensure_schema
from app.models.entities import ClothingItem, CommunityPost, LookFeedback, User
from app.vision.color_extraction import srgb_to_lab
from app.vision.garment_attributes import GARMENT_LABELS, _label_vectors


def _draw_silhouette(kind: str, rgb: Tuple[int, int, int], size: int = 512) -> bytes:
    """
    Gera um recorte PNG com fundo transparente (canal alfa) desenhando a silhueta
    da peça de vestuário com leve sombreado têxtil para renderização no Floating Canvas.
    """
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    r, g, b = rgb
    darker = (max(0, int(r * 0.82)), max(0, int(g * 0.82)), max(0, int(b * 0.82)), 255)
    lighter = (min(255, int(r * 1.12)), min(255, int(g * 1.12)), min(255, int(b * 1.12)), 255)
    fill = (r, g, b, 255)

    if kind == "shirt":
        # Corpo e mangas de camisa/camiseta
        poly = [
            (165, 80), (215, 65), (297, 65), (347, 80),
            (435, 165), (390, 225), (345, 180),
            (345, 435), (167, 435),
            (167, 180), (122, 225), (77, 165),
        ]
        draw.polygon(poly, fill=fill, outline=darker)
        # Gola em V
        draw.polygon([(215, 65), (256, 125), (297, 65)], fill=darker)
        draw.line([(256, 125), (256, 435)], fill=darker, width=3)
    elif kind == "blazer":
        poly = [
            (155, 70), (215, 58), (297, 58), (357, 70),
            (430, 185), (395, 365), (350, 365), (342, 195),
            (348, 445), (262, 445), (256, 390), (250, 445), (164, 445),
            (170, 195), (162, 365), (117, 365), (82, 185),
        ]
        draw.polygon(poly, fill=fill, outline=darker)
        # Lapelas estruturadas
        draw.polygon([(215, 58), (256, 235), (195, 200)], fill=lighter, outline=darker)
        draw.polygon([(297, 58), (256, 235), (317, 200)], fill=lighter, outline=darker)
    elif kind == "sweater":
        poly = [
            (160, 82), (210, 68), (302, 68), (352, 82),
            (425, 195), (390, 385), (345, 380), (340, 200),
            (340, 430), (172, 430),
            (172, 200), (167, 380), (122, 385), (87, 195),
        ]
        draw.polygon(poly, fill=fill, outline=darker)
        # Punhos e barra canelados
        draw.rectangle([172, 405, 340, 430], fill=darker)
    elif kind == "trousers":
        poly = [
            (168, 60), (344, 60),
            (366, 445), (274, 445),
            (256, 195),
            (238, 445), (146, 445),
        ]
        draw.polygon(poly, fill=fill, outline=darker)
        draw.rectangle([168, 60, 344, 90], fill=darker)
        draw.line([(210, 90), (192, 440)], fill=lighter, width=2)
        draw.line([(302, 90), (320, 440)], fill=lighter, width=2)
    elif kind == "wide_pants":
        poly = [
            (178, 60), (334, 60),
            (395, 445), (266, 445),
            (256, 185),
            (246, 445), (117, 445),
        ]
        draw.polygon(poly, fill=fill, outline=darker)
        draw.rectangle([178, 60, 334, 88], fill=darker)
    elif kind == "skirt":
        poly = [
            (188, 75), (324, 75),
            (395, 425), (117, 425),
        ]
        draw.polygon(poly, fill=fill, outline=darker)
        draw.rectangle([188, 75, 324, 102], fill=darker)
        draw.line([(230, 102), (195, 425)], fill=lighter, width=2)
        draw.line([(282, 102), (317, 425)], fill=lighter, width=2)
    elif kind == "dress":
        poly = [
            (185, 65), (225, 60), (256, 130), (287, 60), (327, 65),
            (365, 145), (325, 175), (305, 140),
            (295, 215), (390, 445), (122, 445), (217, 215),
            (207, 140), (187, 175), (147, 145),
        ]
        draw.polygon(poly, fill=fill, outline=darker)
        draw.line([(217, 215), (295, 215)], fill=darker, width=4)
    elif kind == "jumpsuit":
        poly = [
            (185, 60), (230, 55), (256, 115), (282, 55), (327, 60),
            (340, 195), (312, 215),
            (362, 448), (270, 448), (256, 285), (242, 448), (150, 448),
            (200, 215), (172, 195),
        ]
        draw.polygon(poly, fill=fill, outline=darker)
        draw.line([(200, 215), (312, 215)], fill=darker, width=4)
    elif kind == "shoes":
        # Silhueta de calçado (par lateral estilizado)
        poly = [
            (95, 290), (155, 240), (235, 265), (335, 310),
            (420, 325), (430, 365), (415, 390), (90, 390),
        ]
        draw.polygon(poly, fill=fill, outline=darker)
        draw.rectangle([90, 372, 420, 395], fill=darker)
    elif kind == "boots":
        poly = [
            (145, 145), (265, 145), (275, 285), (395, 325),
            (415, 365), (405, 400), (130, 400), (130, 285),
        ]
        draw.polygon(poly, fill=fill, outline=darker)
        draw.rectangle([130, 378, 410, 402], fill=darker)
    else:
        draw.rounded_rectangle([120, 80, 392, 432], radius=28, fill=fill, outline=darker)

    buf = io.BytesIO()
    img.save(buf, format="PNG", optimize=True)
    return buf.getvalue()


def _label_embedding(label_key: str, seed_offset: int) -> List[float]:
    """
    Obtém um vetor de 512 dimensões normalizado no espaço CLIP a partir dos vetores de rótulo
    de `garment_labels.npz`, com leve perturbação determinística para diferenciar peças da mesma família.
    """
    vecs = _label_vectors()
    keys = [g.key for g in GARMENT_LABELS]
    idx = keys.index(label_key) if label_key in keys else 0
    base = np.array(vecs["garment"][idx], dtype=np.float64)
    rng = np.random.default_rng(1000 + seed_offset)
    noise = rng.normal(0.0, 0.03, size=base.shape)
    vec = base + noise
    norm = float(np.linalg.norm(vec))
    return [round(float(v), 6) for v in (vec / norm)]


async def _upload_to_supabase(
    client: httpx.AsyncClient,
    user_id: uuid.UUID,
    filename: str,
    png_bytes: bytes,
) -> str:
    """Envia o PNG transparente para a pasta do usuário no bucket `wardrobe-items`."""
    base = (settings.SUPABASE_URL or "").rstrip("/")
    bucket = settings.SUPABASE_STORAGE_BUCKET
    key = settings.SUPABASE_SERVICE_ROLE_KEY or settings.SUPABASE_KEY
    object_path = f"{user_id}/{filename}"
    url = f"{base}/storage/v1/object/{bucket}/{object_path}"
    headers = {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Content-Type": "image/png",
        "x-upsert": "true",
    }
    resp = await client.post(url, content=png_bytes, headers=headers)
    if resp.status_code >= 400:
        raise RuntimeError(f"Falha no upload de {object_path}: {resp.status_code} {resp.text}")
    return f"{base}/storage/v1/object/public/{bucket}/{object_path}"


SEED_ITEMS = [
    # --- PARTES DE CIMA (5 peças) ---
    {
        "slug": "seed_camisa_linho_terracota.png",
        "shape": "shirt",
        "label_key": "shirt",
        "category": "Partes de cima",
        "subcategory": "Camisa de Linho Terracota",
        "rgb": (190, 92, 64),
        "formality_score": 0.62,
        "cut_type": "ACINTURADO",
        "pattern": "solid",
        "season": "VERAO",
        "thermal_category": "LEVE",
        "purchase_price": 249.90,
        "brand": "Ateliê Botânico • Linho Puro",
        "fabric_composition": "100% Linho Certificado Europeu",
        "is_conscious_fashion": True,
        "capsules": ["Trabalho", "Mala de Viagem"],
        "days_ago": 18,
    },
    {
        "slug": "seed_camisa_oxford_offwhite.png",
        "shape": "shirt",
        "label_key": "shirt",
        "category": "Partes de cima",
        "subcategory": "Camisa Seda & Algodão Off-White",
        "rgb": (238, 231, 218),
        "formality_score": 0.78,
        "cut_type": "ALFAIATARIA_ESTRUTURADA",
        "pattern": "solid",
        "season": "ANO_TODO",
        "thermal_category": "MEDIO",
        "purchase_price": 289.00,
        "brand": "Alfaiataria Paulistana",
        "fabric_composition": "70% Algodão Orgânico, 30% Seda",
        "is_conscious_fashion": True,
        "capsules": ["Trabalho", "Essenciais"],
        "days_ago": 40,
    },
    {
        "slug": "seed_camiseta_oliva.png",
        "shape": "shirt",
        "label_key": "tshirt",
        "category": "Partes de cima",
        "subcategory": "Camiseta Algodão Verde Oliva",
        "rgb": (88, 104, 68),
        "formality_score": 0.25,
        "cut_type": "DECOTE_V",
        "pattern": "solid",
        "season": "VERAO",
        "thermal_category": "LEVE",
        "purchase_price": 119.90,
        "brand": "Básicos Circulares",
        "fabric_composition": "100% Algodão Peruano Pima",
        "is_conscious_fashion": True,
        "capsules": ["Fim de Semana", "Mala de Viagem"],
        "days_ago": 25,
    },
    {
        "slug": "seed_blazer_ocre_dourado.png",
        "shape": "blazer",
        "label_key": "blazer",
        "category": "Partes de cima",
        "subcategory": "Blazer Alfaiataria Caramelo",
        "rgb": (168, 114, 64),
        "formality_score": 0.85,
        "cut_type": "ESTRUTURADO_OMBRO",
        "pattern": "solid",
        "season": "MEIA_ESTACAO",
        "thermal_category": "MEDIO",
        "purchase_price": 549.00,
        "brand": "Curadoria Vintage • Segunda Mão",
        "fabric_composition": "Lã Fria & Linho Reciclado",
        "is_conscious_fashion": True,
        "capsules": ["Trabalho"],
        "days_ago": 65,
    },
    {
        "slug": "seed_sueter_trico_bordo.png",
        "shape": "sweater",
        "label_key": "sweater",
        "category": "Partes de cima",
        "subcategory": "Suéter Tricô Veludo Bordô",
        "rgb": (106, 36, 52),
        "formality_score": 0.55,
        "cut_type": "RETO",
        "pattern": "solid",
        "season": "INVERNO",
        "thermal_category": "PESADO",
        "purchase_price": 319.00,
        "brand": "Tricotaria da Serra",
        "fabric_composition": "100% Lã Merino Rastreável",
        "is_conscious_fashion": True,
        "capsules": ["Inverno"],
        "days_ago": 105,  # Peça adormecida (>90 dias sem uso) para testar reativação no Analytics!
    },
    # --- PARTES DE BAIXO (4 peças) ---
    {
        "slug": "seed_calca_alfaiataria_cafe.png",
        "shape": "trousers",
        "label_key": "trousers",
        "category": "Partes de baixo",
        "subcategory": "Calça Alfaiataria Marrom Café",
        "rgb": (68, 48, 38),
        "formality_score": 0.80,
        "cut_type": "CINTURA_ALTA",
        "pattern": "solid",
        "season": "ANO_TODO",
        "thermal_category": "MEDIO",
        "purchase_price": 379.90,
        "brand": "Ateliê Sob Medida",
        "fabric_composition": "Alfaiataria 65% Liocel, 35% Algodão",
        "is_conscious_fashion": True,
        "capsules": ["Trabalho", "Essenciais"],
        "days_ago": 32,
    },
    {
        "slug": "seed_pantalona_areia.png",
        "shape": "wide_pants",
        "label_key": "trousers",
        "category": "Partes de baixo",
        "subcategory": "Pantalona Fluida Linho Areia",
        "rgb": (218, 204, 182),
        "formality_score": 0.65,
        "cut_type": "PANTALONA",
        "pattern": "solid",
        "season": "VERAO",
        "thermal_category": "LEVE",
        "purchase_price": 329.00,
        "brand": "Costa Natural",
        "fabric_composition": "55% Linho, 45% Viscose Ecovero",
        "is_conscious_fashion": True,
        "capsules": ["Trabalho", "Mala de Viagem"],
        "days_ago": 20,
    },
    {
        "slug": "seed_jeans_reto_indigo.png",
        "shape": "trousers",
        "label_key": "jeans",
        "category": "Partes de baixo",
        "subcategory": "Calça Jeans Reta Índigo",
        "rgb": (48, 66, 92),
        "formality_score": 0.35,
        "cut_type": "RETO",
        "pattern": "solid",
        "season": "ANO_TODO",
        "thermal_category": "MEDIO",
        "purchase_price": 259.90,
        "brand": "Denim Consciente",
        "fabric_composition": "100% Algodão Reciclado (Lavagem Ozônio)",
        "is_conscious_fashion": True,
        "capsules": ["Fim de Semana", "Essenciais"],
        "days_ago": 50,
    },
    {
        "slug": "seed_saia_midi_esmeralda.png",
        "shape": "skirt",
        "label_key": "skirt",
        "category": "Partes de baixo",
        "subcategory": "Saia Midi Seda Esmeralda",
        "rgb": (38, 84, 62),
        "formality_score": 0.72,
        "cut_type": "EVASE",
        "pattern": "solid",
        "season": "MEIA_ESTACAO",
        "thermal_category": "LEVE",
        "purchase_price": 390.00,
        "brand": "Seda Real • Brechó de Luxo",
        "fabric_composition": "100% Seda Pura Reutilizada",
        "is_conscious_fashion": True,
        "capsules": ["Noite & Eventos"],
        "days_ago": 98,  # Segunda peça adormecida (>90 dias)
    },
    # --- CALÇADOS (3 peças) ---
    {
        "slug": "seed_mocassim_couro_caramelo.png",
        "shape": "shoes",
        "label_key": "dress_shoes",
        "category": "Calçados",
        "subcategory": "Mocassim Couro Caramelo",
        "rgb": (152, 92, 50),
        "formality_score": 0.72,
        "cut_type": "RETO",
        "pattern": "solid",
        "season": "ANO_TODO",
        "thermal_category": "MEDIO",
        "purchase_price": 420.00,
        "brand": "Sapataria Artesanal",
        "fabric_composition": "Couro Curtimento Vegetal Sem Cromo",
        "is_conscious_fashion": True,
        "capsules": ["Trabalho", "Essenciais"],
        "days_ago": 35,
    },
    {
        "slug": "seed_tenis_minimalista_marfim.png",
        "shape": "shoes",
        "label_key": "sneakers",
        "category": "Calçados",
        "subcategory": "Tênis Minimalista Marfim",
        "rgb": (235, 228, 214),
        "formality_score": 0.22,
        "cut_type": "RETO",
        "pattern": "solid",
        "season": "ANO_TODO",
        "thermal_category": "LEVE",
        "purchase_price": 349.90,
        "brand": "Passo Circular",
        "fabric_composition": "Algodão Orgânico & Borracha Nativa da Amazônia",
        "is_conscious_fashion": True,
        "capsules": ["Fim de Semana", "Mala de Viagem"],
        "days_ago": 22,
    },
    {
        "slug": "seed_bota_chelsea_tabaco.png",
        "shape": "boots",
        "label_key": "boots",
        "category": "Calçados",
        "subcategory": "Bota Chelsea Camurça Tabaco",
        "rgb": (108, 68, 44),
        "formality_score": 0.65,
        "cut_type": "RETO",
        "pattern": "solid",
        "season": "INVERNO",
        "thermal_category": "PESADO",
        "purchase_price": 499.00,
        "brand": "Manufatura do Sul",
        "fabric_composition": "Camurça Ecológica Impermeabilizada",
        "is_conscious_fashion": False,
        "capsules": ["Inverno", "Noite & Eventos"],
        "days_ago": 74,
    },
    # --- PEÇAS ÚNICAS (2 peças) ---
    {
        "slug": "seed_vestido_envelope_terracota.png",
        "shape": "dress",
        "label_key": "dress",
        "category": "Peças únicas",
        "subcategory": "Vestido Midi Envelope Terracota",
        "rgb": (178, 76, 52),
        "formality_score": 0.76,
        "cut_type": "VESTIDO_ENVELOPE",
        "pattern": "solid",
        "season": "VERAO",
        "thermal_category": "LEVE",
        "purchase_price": 460.00,
        "brand": "Ateliê Renascença",
        "fabric_composition": "100% Crepe de Viscose Certificada FSC",
        "is_conscious_fashion": True,
        "capsules": ["Noite & Eventos", "Mala de Viagem"],
        "days_ago": 15,
    },
    {
        "slug": "seed_macacao_alfaiataria_floresta.png",
        "shape": "jumpsuit",
        "label_key": "jumpsuit",
        "category": "Peças únicas",
        "subcategory": "Macacão Alfaiataria Verde Floresta",
        "rgb": (36, 68, 52),
        "formality_score": 0.88,
        "cut_type": "ACINTURADO",
        "pattern": "solid",
        "season": "ANO_TODO",
        "thermal_category": "MEDIO",
        "purchase_price": 590.00,
        "brand": "Alta Costura Circular",
        "fabric_composition": "Linho Pesado & Seda Crua",
        "is_conscious_fashion": True,
        "capsules": ["Noite & Eventos", "Trabalho"],
        "days_ago": 48,
    },
]


async def seed() -> None:
    await ensure_schema()
    now = datetime.now(timezone.utc)

    async with AsyncSessionLocal() as db:
        users = (await db.execute(select(User))).scalars().all()
        if not users:
            print("Nenhum usuário encontrado na tabela `users`. Faça login no app primeiro.")
            return

        user = users[0]
        print(f"Populando acervo para: {user.email} (id={user.id}, cartela={user.seasonal_palette}, biótipo={user.body_shape})")

        existing_items = (await db.execute(
            select(ClothingItem).where(ClothingItem.user_id == user.id)
        )).scalars().all()
        existing_subcats = {i.subcategory for i in existing_items}

        created_by_slug = {
            i.subcategory: i for i in existing_items if i.subcategory
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            added_count = 0
            for idx, spec in enumerate(SEED_ITEMS):
                if spec["subcategory"] in existing_subcats:
                    print(f"  [já existe] {spec['subcategory']}")
                    continue

                png_bytes = _draw_silhouette(spec["shape"], spec["rgb"])
                image_url = await _upload_to_supabase(client, user.id, spec["slug"], png_bytes)

                rgb_arr = np.array([spec["rgb"]], dtype=np.uint8)
                lab = srgb_to_lab(rgb_arr)[0]
                L, a, b = round(float(lab[0]), 1), round(float(lab[1]), 1), round(float(lab[2]), 1)

                embedding = _label_embedding(spec["label_key"], idx)
                created_at = now - timedelta(days=spec["days_ago"])

                item = ClothingItem(
                    id=uuid.uuid4(),
                    user_id=user.id,
                    category=spec["category"],
                    subcategory=spec["subcategory"],
                    image_url=image_url,
                    dominant_l=L,
                    dominant_a=a,
                    dominant_b=b,
                    formality_score=spec["formality_score"],
                    cut_type=spec["cut_type"],
                    pattern=spec["pattern"],
                    season=spec["season"],
                    thermal_category=spec["thermal_category"],
                    purchase_price=spec["purchase_price"],
                    brand=spec["brand"],
                    fabric_composition=spec["fabric_composition"],
                    is_conscious_fashion=spec["is_conscious_fashion"],
                    disposal_status="ACTIVE",
                    capsules=spec["capsules"],
                    style_embedding=embedding,
                    is_archived=False,
                    created_at=created_at,
                )
                db.add(item)
                created_by_slug[spec["subcategory"]] = item
                added_count += 1
                print(f"  + {spec['category']}: {spec['subcategory']} (L*={L}, a*={a}, b*={b})")

        await db.flush()

        # Atualiza contador real de peças ativas do usuário
        all_user_items = (await db.execute(
            select(ClothingItem).where(ClothingItem.user_id == user.id, ClothingItem.is_archived == False)
        )).scalars().all()
        user.items_count = len(all_user_items)

        # Semear histórico de looks aprovados (LookFeedback) para ativar métricas de rotação (Ativas, 30d, 60d, >90d)
        existing_feedbacks = (await db.execute(
            select(LookFeedback).where(LookFeedback.user_id == user.id)
        )).scalars().all()

        if not existing_feedbacks:
            def item_id(name: str) -> str:
                return str(created_by_slug[name].id)

            feedback_specs = [
                # Usos recentes (< 30 dias -> faixa "active")
                (["Camisa de Linho Terracota", "Pantalona Fluida Linho Areia", "Mocassim Couro Caramelo"], "TRABALHO", 94.2, 3),
                (["Camisa de Linho Terracota", "Calça Alfaiataria Marrom Café", "Mocassim Couro Caramelo"], "TRABALHO", 92.8, 9),
                (["Camiseta Algodão Verde Oliva", "Pantalona Fluida Linho Areia", "Tênis Minimalista Marfim"], "CASUAL", 91.5, 5),
                (["Vestido Midi Envelope Terracota", "Mocassim Couro Caramelo"], "FESTA", 95.0, 12),
                (["Camisa Seda & Algodão Off-White", "Calça Alfaiataria Marrom Café", "Mocassim Couro Caramelo"], "TRABALHO", 89.4, 19),
                # Uso entre 30 e 60 dias atrás -> deixa Jeans na janela de 30-60 dias ("idle_30")
                (["Camisa Seda & Algodão Off-White", "Calça Jeans Reta Índigo", "Tênis Minimalista Marfim"], "CASUAL", 86.0, 42),
                # Uso entre 60 e 90 dias atrás -> deixa Blazer e Bota na janela de 60-90 dias ("idle_60")
                (["Blazer Alfaiataria Caramelo", "Calça Alfaiataria Marrom Café", "Bota Chelsea Camurça Tabaco"], "NOITE", 90.3, 68),
                # Suéter Bordô (105d) e Saia Esmeralda (98d) ficam sem uso recente -> peças adormecidas (>90 dias, "dormant")!
            ]
            for names, occasion, ihe_pct, days_ago in feedback_specs:
                if all(n in created_by_slug for n in names):
                    fb = LookFeedback(
                        id=uuid.uuid4(),
                        user_id=user.id,
                        item_ids=[item_id(n) for n in names],
                        action="APPROVED",
                        occasion=occasion,
                        ihe_percentage=ihe_pct,
                        created_at=now - timedelta(days=days_ago),
                    )
                    db.add(fb)
            await db.flush()
            print("  + 7 registros de histórico de uso (LookFeedback) criados para o Dashboard de Rotação.")

        # Semear 2 publicações no Feed Comunitário se ainda não houver nenhuma
        existing_posts = (await db.execute(select(CommunityPost))).scalars().all()
        if not existing_posts and "Vestido Midi Envelope Terracota" in created_by_slug:
            p1_items = [
                str(created_by_slug["Camisa de Linho Terracota"].id),
                str(created_by_slug["Pantalona Fluida Linho Areia"].id),
                str(created_by_slug["Mocassim Couro Caramelo"].id),
            ]
            p2_items = [
                str(created_by_slug["Vestido Midi Envelope Terracota"].id),
                str(created_by_slug["Mocassim Couro Caramelo"].id),
            ]
            db.add(CommunityPost(
                id=uuid.uuid4(),
                user_id=user.id,
                image_url=created_by_slug["Camisa de Linho Terracota"].image_url,
                caption="Coordenação em linho terracota e pantalona areia para o expediente no ateliê. Harmonia Outono Quente.",
                occasion="TRABALHO",
                style_tags=["Alfaiataria", "Linho", "ESG", "OutonoQuente"],
                item_ids=p1_items,
                ihe_percentage=94.2,
                is_public=True,
                created_at=now - timedelta(days=2),
            ))
            db.add(CommunityPost(
                id=uuid.uuid4(),
                user_id=user.id,
                image_url=created_by_slug["Vestido Midi Envelope Terracota"].image_url,
                caption="Silhueta envelope valorizando o biótipo ampulheta com paleta terrosa intensa.",
                occasion="FESTA",
                style_tags=["Envelope", "Terracota", "Editorial"],
                item_ids=p2_items,
                ihe_percentage=95.0,
                is_public=True,
                created_at=now - timedelta(days=1),
            ))
            print("  + 2 publicações criadas no Feed Comunitário.")

        await db.commit()
        print(f"Concluído! Total de peças no acervo de {user.email}: {user.items_count}/30.")


if __name__ == "__main__":
    asyncio.run(seed())
