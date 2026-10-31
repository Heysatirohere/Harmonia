# HarmonIA — Consultoria Estilística, Visão Computacional & Inteligência Cromática ("Renascença do Ateliê")

Plataforma mobile integrada em **Flutter / Dart** e **FastAPI / Python 3.12+** com **PostgreSQL 16 + `pgvector`**, projetada para digitalização de acervo têxtil com segmentação em canal alfa, análise morfocromática no espaço perceptualmente uniforme **CIE $L^*a^*b^*$**, cálculo determinístico e vetorial do **Índice de Harmonia Estética (IHE)**, **Mirror Mode AR** em ponto de venda e **Moda Circular / ESG**.

---

## 1. Direção Criativa: "Renascença do Ateliê" (`AGENTS.md`)

- **Salas Cromáticas Guiadas pelo Scroll (`RoomScene` & `shaders/atelier_room.frag`)**:
  - Cada tela e seção vive sobre uma cenografia pictórica procedural em GLSL (`velvetBordeaux`, `silkEmerald`, `frescoBlue`, `verdigris`, `gildedOchre`, `tapestryNoir`) com textura de tecido/afresco e vinheta de palco, dissolvendo suavemente entre seções durante a rolagem (`resolveRoomBlend`).
- **Tipografia Editorial & Contraste Verificado**:
  - *Display Editorial* e *Hero* em **Bodoni Moda** (`40pt` / `56pt`), *Subtítulo Curatorial* em **Bodoni Moda Italic** (`20pt`) e *UI / Leitura / Badges* em **Inter Tight** (`15pt` / `14pt` / `11pt` com kerning `+1.2`).
- **Componentes Editoriais Exclusivos**:
  - **Medidor Joalheiro do IHE (`AtelierIheGauge`)**: Arco vetorial em `CustomPainter` com reflexo de folha de ouro batido (`gildedLeaf`), pontuação central em `56pt`, chancela `✦ LOOK FORTEMENTE RECOMENDADO` ($\ge 75\%$) e decomposição visual dos 4 pilares científicos ($S_{cor}, S_{bio}, S_{ocasion}, S_{cos}$).
  - **The Floating Canvas (Arara Virtual Magnética)**: Peças recortadas em PNG transparente com halo de luz no contorno alfa, montagem interativa por arraste magnético (`Draggable` / `DragTarget`) com `AppMotion.theatricalGesture` e `HapticFeedback`.
  - **Mirror Mode & AR Try-On**: Visor de provador com HUD em linhas capilares `gildedLeaf`, folha translúcida com `BackdropFilter` (`16px`), carrossel horizontal de paridade imediata e sobreposição gráfica AR em 1 toque.
  - **Editorial Gallery (Feed Comunitário)**: Grade assimétrica (`3:4` e `4:5`) sobre `tapestryNoir`, hotspots circulares `gildedLeaf` sobre as peças revelando marca, tecido e coordenadas `CIE L*a*b*` em folha `paperBone`, além de **Moodboards Semânticos** privados.

---

## 2. Motor Científico do Índice de Harmonia Estética (IHE)

$$\text{IHE} = 0.35 \cdot S_{\text{cor}} + 0.25 \cdot S_{\text{bio}} + 0.20 \cdot S_{\text{ocasion}} + 0.20 \cdot S_{\text{cos}}$$

1. **Harmonia Cromática ($S_{\text{cor}}$)**: Distância euclidiana $\Delta E^*_{ab}$ no espaço **CIE $L^*a^*b^*$** (iluminante D65) entre os centróides k-means++ da peça e a cartela sazonal expandida do usuário (12 estações), convertida por decaimento exponencial $S_{\text{cor}} = \exp(-\Delta E^*_{ab} / 18.0)$.
2. **Compensação Morfológica ($S_{\text{bio}}$)**: Matriz de compatibilidade geométrica entre os 5 biótipos corporais (`AMPULHETA`, `RETANGULO`, `TRIANGULO`, `TRIANGULO_INVERTIDO`, `OVAL`) e os 13 cortes estruturais inferidos via CLIP Zero-Shot (`cut_type`).
3. **Contexto & Clima ($S_{\text{ocasion}}$)**: Adequação termo-climática real (inferida da categoria térmica das peças `LEVE`, `MEDIO`, `PESADO`, `IMPERMEAVEL` cruzada com telemetria Open-Meteo) e grau de formalidade da ocasião (`Casual`, `Trabalho`, `Noite`, `Festa`, `Gala`).
4. **Similaridade Vetorial ($S_{\text{cos}}$)**: Similaridade de cosseno em espaço latente de 512 dimensões (CLIP ViT-B/32) centrada no guarda-roupa do usuário, atualizando o vetor de preferência `users.style_vector` no PostgreSQL/`pgvector` a cada aprovação ou descarte (`RF13`).

---

## 3. Estrutura do Projeto

```text
Harmonia_Refatorado/
├── lib/
│   ├── core/               # Conversão CIE L*a*b*, Cliente HTTP, Config Supabase, Tokens de Cor e Tipografia
│   ├── domain/             # Modelos de Domínio e Contratos de Repositório (Auth, StyleProfile, Wardrobe, Outfit, Community, Weather)
│   ├── data/services/      # Implementações RESTful assíncronas (FastAPI + Open-Meteo + Supabase Auth/Storage)
│   ├── models/             # Entidades de Vestuário, Segmentação, Paridade, Lacunas, Analytics e Filtros
│   └── presentation/
│       ├── atelier/        # RoomScene, RoomMarker, AtelierShimmer, PaperSheet, GoldSeal, CinnabarButton
│       ├── screens/        # 12 Telas Editoriais (Look do Dia, Arara Virtual, Scanner, Mirror AR, Analytics, Lacunas, Feed, Perfil...)
│       └── widgets/        # AtelierIheGauge, ClothingCard, StoreParitySheet, EditorialFeedCard, RecalibrationDialogs...
├── shaders/
│   └── atelier_room.frag   # Fragment Shader GLSL das 6 Salas Cromáticas
├── test/                   # Suíte com 152 testes automatizados (Unitários, Contratos HTTP e Widget Tests)
└── backend/
    ├── app/
    │   ├── api/v1/         # 28 Endpoints RESTful (users, wardrobe, outfits, community, weather, health)
    │   ├── core/           # Config, Async SQLAlchemy, JWT/JWKS Security, Quota RN02, SupabaseAdmin
    │   ├── engine/         # IHE Calculator, CIE Lab*, Morphology, Context Rules, StyleSpace, Outfit Generator, Gap Analysis
    │   ├── models/         # Entidades ORM SQLAlchemy 2.0 + pgvector
    │   ├── schemas/        # DTOs Pydantic v2
    │   └── vision/         # Segmentação rembg (U2Net), k-means++ Lab*, Colorimetria Selfie, CLIP ViT-B/32 ONNX
    ├── init_db/            # DDL PostgreSQL 16 + pgvector + RLS Supabase
    └── tests/              # Suíte com 272 testes pytest assíncronos
```

---

## 4. Como Executar os Testes e Validações

### Backend (FastAPI / Python)
```bash
cd backend
./.venv/bin/pytest -q
```

### Frontend (Flutter / Dart)
```bash
flutter analyze
flutter test
```
