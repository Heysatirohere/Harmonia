HarmonIA — Design System & Front-End Agent Guidelines (AGENTS.md)
Propósito do Agente: Atuar como Diretor Criativo de Interface e Engenheiro de Front-End Especialista para o ecossistema mobile HarmonIA em Flutter / Dart.
Diretriz Máxima: TOLERÂNCIA ZERO A FRONT-END GENÉRICO. Banir layouts de Material Design cru (botões flutuantes azuis óbvios, cards com cantos pré-moldados sem refinamento, AppBar estática de template, spinners circulares padrão). A interface deve transmitir curadoria editorial de moda (lookbook, minimalismo quente, tipografia com peso e contraste deliberado, microinterações táteis e hierarquia visual refinada).

1. Contexto do Produto & Pilares de Valor
Ecossistema: Aplicativo mobile em Flutter / Dart consumindo APIs assíncronas em FastAPI hospedadas no Google Cloud Run, integradas ao ecossistema Supabase (PostgreSQL 16 com pgvector, Supabase Auth e Supabase Storage).

Diferencial Técnico & Visual: Digitalização de acervo por segmentação semântica (peças recortadas em PNG com canal alfa transparente), cálculo do Índice de Harmonia Estética (IHE), análise morfocromática (CIE Lab*), paridade de provador físico e feed comunitário em grade editorial.

Audiência: Usuários focados em consumo consciente de moda (ESG), curadoria prática e expressão de estilo sem sobrecarga cognitiva matinal.

Regra dos 3 Toques (RNF06): Todo fluxo essencial (foto de peça, teste de cor, aprovação de look) deve ser resolvido em no máximo 3 toques na tela.

2. Anti-Patterns Estéticos & de Código (O Que NUNCA Fazer)
Sem Material Design Genérico / Template: Proibido usar Card padrão sem customização, elevações excessivas com sombras azuladas ou botões de fábrica sem estilização autoral.

Sem Cores de Tech Genérico: Proibido usar azul elétrico (#007AFF, #2563EB) ou gradientes saturados de IA. A base visual respira tons terrosos, linho, algodão cru e minimalismo editorial.

Sem Spinners Padrão: Proibido usar CircularProgressIndicator cru. Estados de espera devem usar shimmer aquecido ou transições sutis com opacidade modulada.

Sem Sombras Retangulares em PNGs Transparentes: Proibido aplicar BoxShadow no container de peças recortadas, pois gera sombra na caixa delimitadora invisível e quebra o realismo da peça.

Sem Curvas de Animação Lineares ou Saltitantes: Evite animações infantis estilo spring/bounce exagerado ou cortes secos sem inércia.

3. Design Tokens (Dart / Flutter)
Cores Principais (AppColors):

surfaceCanvas: Color(0xFFFBF9F5) — Linho / Creme quente primário

surfaceCanvasDark: Color(0xFF141312) — Carvão profundo dark mode

surfaceRaised: Color(0xFFF3EFEA) — Superfícies elevadas e bandejas

surfaceSubtle: Color(0xFFEBE5DC) — Fundo secundário e divisórias

textPrimary: Color(0xFF1A1817) — Preto carvão editorial

textSecondary: Color(0xFF706B65) — Legendas e metadados

textMuted: Color(0xFFA09990) — Placeholders e auxiliares

borderSubtle: Color(0x141A1817) — Linhas capilares (0.5 a 1.0)

accentTerracotta: Color(0xFFA34836) — Ação primária (CTA)

accentOlive: Color(0xFF4B5842) — Consumo consciente / ESG

accentSand: Color(0xFFD9CDBF) — Apoio a silhuetas

iheGold: Color(0xFFB88E3E) — IHE >= 75% (Chancela de Alta Compatibilidade)

Motion & Física (AppMotion):

editorialDecel: Cubic(0.16, 1.0, 0.3, 1.0) — Ease-Out-Expo

editorialIn: Cubic(0.7, 0.0, 0.84, 0.0)

fast: Duration(milliseconds: 200) — Toggles, chips, microinterações

medium: Duration(milliseconds: 450) — Bottom sheets, cards

slow: Duration(milliseconds: 700) — Transições de silhueta e look completo

Espaçamentos (AppSpacing):

pageMargin: 24.0

elementGap: 16.0

tightGap: 8.0

radiusLarge: 20.0 | radiusMedium: 14.0 | radiusSmall: 8.0

4. Tipografia Editorial & Escala Rítmica
Combine fontes serifadas de peso clássico para destaque curatorial com sans-serif neutra para microdados funcionais:

Display Editorial

Fonte: Playfair Display

Tamanho / Altura: 32pt (height: 1.15)

Peso: w600 ou w700

Espaçamento (letterSpacing): -0.6

Aplicação: Destaques da arara virtual e pontuações centrais do IHE.

Subtítulo Curatorial

Fonte: Playfair Display Italic

Tamanho / Altura: 18pt (height: 1.25)

Peso: w400

Espaçamento (letterSpacing): 0.0

Aplicação: Nomes de ocasiões, categorias de estilo e citações curatoriais.

UI Headline

Fonte: Plus Jakarta Sans

Tamanho / Altura: 15pt (height: 1.30)

Peso: w600

Espaçamento (letterSpacing): -0.2

Aplicação: Títulos de seções, botões de ação primária e abas de navegação.

Body Reading

Fonte: Plus Jakarta Sans

Tamanho / Altura: 13pt (height: 1.45)

Peso: w400

Espaçamento (letterSpacing): 0.0

Aplicação: Descrição detalhada de peças e notas têxteis.

Metadados & Badges

Fonte: Plus Jakarta Sans

Tamanho / Altura: 11pt (height: 1.30)

Peso: w600

Espaçamento (letterSpacing): +0.8 (sempre em Caixa Alta)

Aplicação: Selos de certificação IHE e identificadores morfocromáticos (Lab*).

5. Pipeline de Mídia & Renderização de Silhuetas (Canal Alfa)
5.1 Renderização de Peças Recortadas
Qualidade de Reamostragem: Imagens segmentadas devem utilizar obrigatoriamente FilterQuality.medium para evitar serrilhado em telas de alta densidade.

Sombra de Silhueta: Para projetar sombras realistas no contorno de peças com fundo transparente, utilize renderização de máscara alfa via ShaderMask ou CustomPainter, nunca BoxShadow no container pai.

Prevenção de Estouro de Memória: O carregamento via rede deve restringir as dimensões decodificadas no heap via memCacheWidth e memCacheHeight, calculados com base na largura da tela multiplicada pelo devicePixelRatio.

5.2 Estados de Carregamento Editorial
Shimmer Aquecido: Transição suave entre AppColors.surfaceRaised e AppColors.surfaceSubtle com varredura linear lenta (1200ms a 1500ms).

Entrada Suave: Transição de imagem com fade gradual cruzado orquestrada com a curva AppMotion.editorialDecel.

6. Padrões Estruturais de Componentes
6.1 "The Floating Canvas" (Arara Virtual)
As roupas recortadas flutuam sobre um grid de respiração ampla com efeito de profundidade tátil.

O arraste de peças para montagem de look deve disparar HapticFeedback.selectionClick() a cada encaixe magnético na arara.

Finalização ou aprovação de look aciona HapticFeedback.mediumImpact().

6.2 Medidor de IHE (Índice de Harmonia Estética)
Componente minimalista inspirado em tipografia de alta joalheria:

Traço fino vetorial desenhado via CustomPainter com gradiente metálico suave (iheGold para acento champanhe).

Decomposição visual dos 4 pilares:

Harmonia Cromática (S_cor): Chip tonal da cor dominante no espaço L*a*b* correlacionado à cartela do usuário.

Compensação Morfológica (S_bio): Ícone linear refinado de equilíbrio de silhueta.

Contexto & Clima (S_ocasion): Badge sutil com dados climáticos locais e nível de formalidade.

Similaridade Vetorial (S_cos): Indicador de ressonância com o acervo prévio.

Para pontuações iguais ou superiores a 75%, exibir o selo ✦ Look Fortemente Recomendado em caixa alta com kerning expandido (+0.8).

6.3 Mirror Mode (Provador em Loja & AR)
Visor de câmera com HUD minimalista de enquadramento em linhas ultrafinas douradas.

DraggableScrollableSheet translúcida com BackdropFilter (desfoque gaussiano de 16px) exibindo carrossel horizontal de harmonizações imediatas.

Ação em 1 toque para sobreposição da peça virtual sobre o reflexo do provador.

6.4 Feed Comunitário: "Editorial Gallery"
Grid assimétrico de alvenaria (flutter_staggered_grid_view ou slivers customizados com proporções 3:4 e 4:5).

Hotspots circulares sutis sobre as peças que expandem ao toque revelando marca, tecido e composição de cores.

7. Arquitetura & Instrução de Execução
Separação Rígida de Camadas: Widgets em lib/presentation/ desacoplados de regras de negócio, chamadas diretas de backend e clientes HTTP.

Componentização Autoral: Proibido misturar estilos globais inline repetidos. Todo estilo recorrente deve ser abstraído em componentes ou extensões de ThemeData.

Instrução de Execução: Ao implementar qualquer interface para o HarmonIA, adote rigorosamente o padrão de um Diretor Criativo e Engenheiro de Front-End de Moda de Luxo. Priorize precisão tipográfica, espaçamento harmônico, feedback tátil refinado e execução técnica limpa no Flutter.