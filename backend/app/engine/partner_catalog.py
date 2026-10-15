"""
Catálogo de Parceiros para Lacunas do Acervo (RF11, RF12, RN03)

Enquanto as APIs de estoque da C&A e da Lojas Renner não estão integradas, o catálogo é
uma curadoria estática de arquétipos de peças-chave. Cada arquétipo traz a cor L*a*b*,
a formalidade e o corte que o motor IHE usa para medir quantos looks ele destravaria,
e os produtos dos parceiros que o atendem. Sem fotos nem preços: esses dados só valem
vindos da API do parceiro, então o app manda a pessoa para a busca na loja.

Trocar por uma integração real é implementar `PartnerCatalog.archetypes()`.
"""

from dataclasses import dataclass, field
from typing import List, Protocol
from urllib.parse import quote, urlencode


STORE_NAMES = {
    "CEA": "C&A",
    "RENNER": "Lojas Renner",
}

UTM_PARAMS = {
    "utm_source": "harmonia",
    "utm_medium": "app",
    "utm_campaign": "lacunas_acervo",
}


def partner_search_url(store: str, query: str, gap_id: str) -> str:
    """Busca do produto no e-commerce do parceiro com UTM de afiliação (RF12, Seção 3.6.3)."""
    utm = urlencode({**UTM_PARAMS, "utm_content": gap_id})
    if store == "RENNER":
        return f"https://www.lojasrenner.com.br/b?{urlencode({'Ntt': query})}&{utm}"
    if store == "CEA":
        path = quote(query)
        return f"https://www.cea.com.br/{path}?{urlencode({'_q': query, 'map': 'ft'})}&{utm}"
    raise ValueError(f"Parceiro desconhecido: {store}")


@dataclass(frozen=True)
class PartnerProduct:
    id: str
    store: str
    name: str
    search_query: str
    L: float
    a: float
    b: float
    in_stock: bool = True


@dataclass(frozen=True)
class GapArchetype:
    """Peça-chave candidata: o que o motor avalia contra o acervo."""
    id: str
    title: str
    category: str  # família do gerador: top, bottom, shoes, one_piece
    L: float
    a: float
    b: float
    formality: float
    cut_type: str
    products: List[PartnerProduct] = field(default_factory=list)


class PartnerCatalog(Protocol):
    def archetypes(self) -> List[GapArchetype]: ...


_ARCHETYPES: List[GapArchetype] = [
    GapArchetype(
        id="camisa-linho-off-white", title="Camisa de linho off-white", category="top",
        L=92.0, a=0.5, b=6.0, formality=0.6, cut_type="RETO",
        products=[
            PartnerProduct("renner-camisa-linho-off", "RENNER", "Camisa de linho manga longa off-white",
                           "camisa linho off white", 92.0, 0.5, 7.0),
            PartnerProduct("cea-camisa-linho-off", "CEA", "Camisa de linho off-white",
                           "camisa linho off white", 91.0, 1.0, 6.0),
        ],
    ),
    GapArchetype(
        id="camiseta-preta-basica", title="Camiseta preta básica", category="top",
        L=12.0, a=0.0, b=0.0, formality=0.2, cut_type="RETO",
        products=[
            PartnerProduct("cea-camiseta-preta", "CEA", "Camiseta básica preta de algodão",
                           "camiseta basica preta", 12.0, 0.0, 0.0),
            PartnerProduct("renner-camiseta-preta", "RENNER", "Camiseta básica preta",
                           "camiseta basica preta", 13.0, 0.0, -1.0, in_stock=False),
        ],
    ),
    GapArchetype(
        id="blusa-terracota", title="Blusa terracota", category="top",
        L=48.0, a=34.0, b=36.0, formality=0.45, cut_type="ACINTURADO",
        products=[
            PartnerProduct("renner-blusa-terracota", "RENNER", "Blusa de viscose terracota",
                           "blusa terracota", 48.0, 35.0, 36.0),
        ],
    ),
    GapArchetype(
        id="calca-alfaiataria-marinho", title="Calça de alfaiataria marinho", category="bottom",
        L=22.0, a=2.0, b=-18.0, formality=0.75, cut_type="CINTURA_ALTA",
        products=[
            PartnerProduct("renner-calca-alfaiataria-marinho", "RENNER", "Calça de alfaiataria cintura alta marinho",
                           "calca alfaiataria marinho", 22.0, 2.0, -18.0),
            PartnerProduct("cea-calca-alfaiataria-marinho", "CEA", "Calça reta de alfaiataria azul-marinho",
                           "calca alfaiataria azul marinho", 23.0, 1.0, -17.0),
        ],
    ),
    GapArchetype(
        id="jeans-reto-medio", title="Jeans reto azul médio", category="bottom",
        L=45.0, a=-2.0, b=-22.0, formality=0.3, cut_type="RETO",
        products=[
            PartnerProduct("cea-jeans-reto", "CEA", "Calça jeans reta lavagem média",
                           "calca jeans reta", 45.0, -2.0, -22.0),
            PartnerProduct("renner-jeans-reto", "RENNER", "Calça jeans reta azul médio",
                           "calca jeans reta", 44.0, -1.0, -23.0),
        ],
    ),
    GapArchetype(
        id="pantalona-caramelo", title="Pantalona caramelo", category="bottom",
        L=55.0, a=14.0, b=34.0, formality=0.55, cut_type="PANTALONA",
        products=[
            PartnerProduct("renner-pantalona-caramelo", "RENNER", "Calça pantalona caramelo",
                           "calca pantalona caramelo", 55.0, 14.0, 34.0),
        ],
    ),
    GapArchetype(
        id="saia-midi-oliva", title="Saia midi oliva", category="bottom",
        L=42.0, a=-14.0, b=26.0, formality=0.5, cut_type="EVASE",
        products=[
            PartnerProduct("cea-saia-midi-oliva", "CEA", "Saia midi evasê verde oliva",
                           "saia midi verde oliva", 42.0, -14.0, 26.0),
        ],
    ),
    GapArchetype(
        id="mocassim-couro-caramelo", title="Mocassim de couro caramelo", category="shoes",
        L=45.0, a=16.0, b=32.0, formality=0.6, cut_type="RETO",
        products=[
            PartnerProduct("renner-mocassim-caramelo", "RENNER", "Mocassim de couro caramelo",
                           "mocassim couro caramelo", 45.0, 16.0, 32.0),
            PartnerProduct("cea-mocassim-caramelo", "CEA", "Mocassim caramelo",
                           "mocassim caramelo", 46.0, 15.0, 31.0),
        ],
    ),
    GapArchetype(
        id="tenis-branco-minimalista", title="Tênis branco minimalista", category="shoes",
        L=95.0, a=0.0, b=1.0, formality=0.2, cut_type="RETO",
        products=[
            PartnerProduct("cea-tenis-branco", "CEA", "Tênis branco casual",
                           "tenis branco casual", 95.0, 0.0, 1.0),
            PartnerProduct("renner-tenis-branco", "RENNER", "Tênis branco minimalista",
                           "tenis branco", 94.0, 0.0, 2.0),
        ],
    ),
    GapArchetype(
        id="vestido-envelope-vinho", title="Vestido envelope vinho", category="one_piece",
        L=28.0, a=36.0, b=12.0, formality=0.7, cut_type="VESTIDO_ENVELOPE",
        products=[
            PartnerProduct("renner-vestido-envelope-vinho", "RENNER", "Vestido midi envelope vinho",
                           "vestido envelope vinho", 28.0, 36.0, 12.0),
        ],
    ),
]


class StaticPartnerCatalog:
    """Curadoria estática usada até a integração com as APIs dos parceiros."""

    def archetypes(self) -> List[GapArchetype]:
        return list(_ARCHETYPES)
