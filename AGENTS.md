HarmonIA — Design System & Front-End Agent Guidelines (AGENTS.md)
Propósito do Agente: Atuar como Diretor Criativo de Interface e Engenheiro de Front-End Especialista para o ecossistema mobile HarmonIA em Flutter / Dart.
Diretriz Máxima: TOLERÂNCIA ZERO A FRONT-END GENÉRICO E A INTERFACE "PASTEL". Banir layouts de Material Design cru (botões flutuantes azuis óbvios, cards com cantos pré-moldados sem refinamento, AppBar estática de template, spinners circulares padrão) e telas inteiras em creme de baixo croma. A interface deve ter a presença de um editorial de moda de alta costura: fundos pictóricos em tons de joia, tipografia de revista com contraste extremo, cenografia que muda conforme o usuário rola a tela e microinterações táteis com gesto teatral.

Direção Criativa: "Renascença do Ateliê"
Referência: Shopify Editions Winter '26 — "The Renaissance Edition" (https://www.shopify.com/editions/winter2026). O que adotamos dela:
- Cada seção vive sobre um fundo pictórico próprio (veludo drapeado, seda, afresco, folha de ouro, tapeçaria botânica), escuro e com textura, nunca uma cor chapada.
- O fundo acompanha a rolagem: ao passar de uma seção para a próxima, a cenografia se dissolve na seguinte, de modo que o scroll é também uma troca de sala.
- O conteúdo (cartões, peças recortadas, números) flutua sobre essa cenografia, com base clara em papel cor de osso para leitura longa.
O que NÃO adotamos: os ativos gráficos da Shopify (imagens, vídeos, fontes licenciadas) e os gradientes neon dos cartões de produto dela.
Mudança em relação à versão anterior: a base deixa de ser linho/creme ("minimalismo quente") e passa a ser cenografia em tons de joia. O creme sobrevive apenas como papel de leitura (paperBone), nunca como o tom dominante de uma tela.

1. Contexto do Produto & Pilares de Valor
Ecossistema: Aplicativo mobile em Flutter / Dart consumindo APIs assíncronas em FastAPI hospedadas no Google Cloud Run, integradas ao ecossistema Supabase (PostgreSQL 16 com pgvector, Supabase Auth e Supabase Storage).

Diferencial Técnico & Visual: Digitalização de acervo por segmentação semântica (peças recortadas em PNG com canal alfa transparente), cálculo do Índice de Harmonia Estética (IHE), análise morfocromática (CIE Lab*), paridade de provador físico e feed comunitário em grade editorial.

Audiência: Usuários focados em consumo consciente de moda (ESG), curadoria prática e expressão de estilo sem sobrecarga cognitiva matinal.

Regra dos 3 Toques (RNF06): Todo fluxo essencial (foto de peça, teste de cor, aprovação de look) deve ser resolvido em no máximo 3 toques na tela. A cenografia nunca pode adicionar toques nem atrasar uma ação.

2. Anti-Patterns Estéticos & de Código (O Que NUNCA Fazer)
Sem Interface Pastel: Proibido que uma tela principal tenha como fundo dominante um tom claro de baixo croma (creme, bege, linho, cinza claro). Telas principais usam uma Sala Cromática (seção 4). paperBone é reservado a cartões e folhas de leitura.

Sem Cor Chapada na Cenografia: Fundos de Sala nunca são um Color sólido isolado. Sempre há textura (imagem de tecido/afresco ou ruído procedural) e luz (gradiente de vinheta), mesmo que sutis.

Sem Material Design Genérico / Template: Proibido usar Card padrão sem customização, elevações excessivas com sombras azuladas ou botões de fábrica sem estilização autoral.

Sem Cores de Tech Genérico: Proibido usar azul elétrico (#007AFF, #2563EB) ou gradientes saturados de IA (neon, arco-íris, roxo-rosa). A saturação vem de pigmentos históricos: bordô, esmeralda, azul afresco, verdete, ocre, cinábrio, ouro.

Sem Spinners Padrão: Proibido usar CircularProgressIndicator cru. Estados de espera usam shimmer tingido pela Sala atual ou transições sutis com opacidade modulada.

Sem Sombras Retangulares em PNGs Transparentes: Proibido aplicar BoxShadow no container de peças recortadas, pois gera sombra na caixa delimitadora invisível e quebra o realismo da peça.

Sem Animação Infantil ou Seca: Proibido bounce repetido, elástico com várias oscilações ou cortes secos sem inércia. O único overshoot permitido é o Gesto Teatral (seção 3), uma única ultrapassagem curta, aplicado só a escala e posição.

Sem Contraste Insuficiente: Texto sobre Sala usa sempre ivoryText. Corpo de texto exige contraste mínimo de 4,5:1 e componentes interativos 3:1 contra o fundo (WCAG AA). Nunca texto escuro sobre Sala escura nem dourado sobre paperBone.

Sem Ativos de Terceiros: Proibido reutilizar imagens, vídeos ou fontes da Shopify ou de qualquer referência. Texturas devem ser próprias, procedurais ou de fontes com licença livre (CC0 / domínio público, ex.: acervos abertos do Met, Rijksmuseum, ambientCG), com a origem registrada em assets/textures/CREDITS.md.

3. Design Tokens (Dart / Flutter)
Salas Cromáticas — cenografia de fundo (AppColors):

velvetBordeaux: Color(0xFF3B1829) — Veludo bordô drapeado

silkEmerald: Color(0xFF1C3120) — Seda esmeralda profunda

frescoBlue: Color(0xFF2A5261) — Azul de afresco craquelado

verdigris: Color(0xFF1B4543) — Verdete / cobre oxidado

gildedOchre: Color(0xFF634524) — Ocre com douramento

tapestryNoir: Color(0xFF0E0C0A) — Tapeçaria botânica noturna

Superfícies e texto:

paperBone: Color(0xFFE9E4D6) — Papel cor de osso para cartões e folhas de leitura

paperBoneRaised: Color(0xFFF4EFE3) — Cartão elevado sobre paperBone

ivoryText: Color(0xFFF4EEE1) — Texto sobre qualquer Sala

ivoryMuted: Color(0xD9F4EEE1) — Legendas sobre Sala (85%)

inkText: Color(0xFF15110E) — Texto sobre paperBone

inkSecondary: Color(0xFF5E554B) — Metadados sobre paperBone

hairlineIvory: Color(0x33F4EEE1) — Linhas capilares sobre Sala

hairlineInk: Color(0x1F15110E) — Linhas capilares sobre paperBone

Acentos:

accentCinnabar: Color(0xFFB8361E) — Ação primária (CTA), sempre com rótulo ivoryText (5,1:1)

gildedLeaf: Color(0xFFD4AE5C) — Folha de ouro: realces, traços do HUD e IHE >= 75% (Chancela de Alta Compatibilidade). Sobre Sala apenas, nunca sobre paperBone. Em texto pequeno, só em velvetBordeaux, silkEmerald e tapestryNoir; em frescoBlue, verdigris e gildedOchre, só em números e títulos a partir de 24pt

verdigrisLight: Color(0xFF6FA59A) — Consumo consciente / ESG sobre Sala

Contrastes verificados no pior caso, isto é, no ponto mais claro da textura sob a luz da vinheta (ivoryText / ivoryMuted / gildedLeaf): velvetBordeaux 10,7 / 8,2 / 5,9 · silkEmerald 8,9 / 6,9 / 4,9 · tapestryNoir 15,2 / 11,2 / 8,4 · verdigris 7,3 / 5,8 / 4,0 · gildedOchre 5,8 / 4,7 / 3,2 · frescoBlue 5,6 / 4,5 / 3,1. Sobre paperBone: inkText 14,8 · inkSecondary 5,8 · accentCinnabar 4,6. O brilho máximo da textura (1.35 no drapeado, ~1.14 no reboco) faz parte desse cálculo: ao mudar um token ou o shader, recalcular e manter os mínimos.

CTA sobre Sala: accentCinnabar contra velvetBordeaux fica abaixo de 3:1; nessa Sala (e em tapestryNoir) o CTA recebe contorno capilar ivoryText de 1.0 ou usa a variante marfim (fundo ivoryText, rótulo inkText).

Motion & Física (AppMotion):

editorialDecel: Cubic(0.16, 1.0, 0.3, 1.0) — Ease-Out-Expo, padrão para opacidade, cor e cenografia

editorialIn: Cubic(0.7, 0.0, 0.84, 0.0)

theatricalGesture: Cubic(0.34, 1.56, 0.64, 1.0) — Gesto Teatral: uma ultrapassagem curta, só em escala e translação (entrada de cartões, encaixe de peça, chips). Nunca em opacidade ou cor

fast: Duration(milliseconds: 200) — Toggles, chips, microinterações

medium: Duration(milliseconds: 450) — Bottom sheets, cards, Gesto Teatral

slow: Duration(milliseconds: 700) — Transições de silhueta e look completo

roomDissolve: Duration(milliseconds: 900) — Troca de Sala quando não guiada pelo scroll (troca de aba, abertura de tela)

Espaçamentos (AppSpacing):

pageMargin: 24.0

elementGap: 16.0

tightGap: 8.0

sectionGap: 56.0 — Respiro entre Salas numa mesma rolagem

radiusLarge: 20.0 | radiusMedium: 14.0 | radiusSmall: 8.0

4. Cenografia: Salas Cromáticas & Fundo Guiado pelo Scroll
4.1 Composição de uma Sala
Cada Sala é uma pilha fixa atrás do conteúdo, de baixo para cima:
1. Cor base da Sala (token da seção 3).
2. Textura: imagem de tecido/pintura em assets/textures/ (WebP, no máximo 1080 px no lado maior, até ~250 KB) ou ruído procedural via CustomPainter/FragmentShader quando não houver imagem. Opacidade entre 0.35 e 0.8, BlendMode.overlay ou softLight sobre a cor base.
3. Vinheta: RadialGradient do centro-superior para as bordas, escurecendo 20–35%, para dar profundidade de palco e segurar o contraste do texto.
Nada disso recebe toque; a Sala fica isolada em RepaintBoundary.

4.2 Mapeamento Sala × Tela (ponto de partida)
Look do Dia / IHE: velvetBordeaux → gildedOchre na seção do medidor IHE.
Guarda-Roupa (Arara Virtual): cabeçalho em silkEmerald; em "Todos", cada categoria é uma seção com sua Sala (Partes de cima: silkEmerald · Partes de baixo: velvetBordeaux · Calçados: gildedOchre · Peças únicas: frescoBlue · demais: verdigris); com filtro ativo, a tela inteira dissolve para a Sala da categoria.
Digitalizar Peça: frescoBlue (a peça recortada precisa de fundo frio para a cor dela se destacar).
Dashboard de Rotação: gildedOchre → verdigris.
Feed Comunitário: tapestryNoir.
Mirror Mode (provador): tapestryNoir sobre a câmera, sem textura (a câmera é a cenografia).
Perfil, Conta e Autenticação: velvetBordeaux com folhas em paperBone.

4.3 Fundo Guiado pelo Scroll
Em telas com várias seções, cada seção declara sua Sala. O fundo não rola junto: ele fica fixo e se dissolve entre a Sala da seção atual e a da próxima conforme a posição de rolagem.
- Implementação: RoomScene (lib/presentation/atelier/room_scene.dart) atrás de um CustomScrollView, com um RoomMarker (sliver de altura zero) no início de cada seção. O progresso t entre as âncoras mistura as duas Salas no shader, com a curva easeInOutCubic aplicada a t (suave nas duas pontas, porque acompanha o dedo). editorialDecel fica para as dissoluções com tempo (roomDissolve).
- O fundo segue a seção que está sendo lida: a troca começa quando o início da próxima seção cruza 55% da altura da tela (a partir do topo) e se completa depois de ela subir mais 40%, nunca de forma abrupta na fronteira.
- O fim da rolagem precisa de respiro (cerca de meia tela) para que o início da última seção alcance o topo e a troca se complete.
- Somente a cenografia é redesenhada durante o scroll (RepaintBoundary + AnimatedBuilder restrito ao fundo); o conteúdo não reconstrói.
- Texturas são pré-carregadas com precacheImage ao abrir a tela e decodificadas no tamanho da tela (cacheWidth = largura × devicePixelRatio).
- Acessibilidade: com MediaQuery.disableAnimations ativo, a troca de Sala acontece por corte simples na fronteira da seção, sem dissolução.

5. Tipografia Editorial & Escala Rítmica
Contraste de revista: serifada de altíssimo contraste (didone) para gestos editoriais, grotesca neutra para dados. As duas vêm do google_fonts.

Display Editorial

Fonte: Bodoni Moda

Tamanho / Altura: 40pt (height: 1.05); hero de tela até 56pt

Peso: w600 a w800

Espaçamento (letterSpacing): -1.0

Aplicação: Títulos de tela, destaques da arara virtual e pontuação central do IHE.

Subtítulo Curatorial

Fonte: Bodoni Moda Italic

Tamanho / Altura: 20pt (height: 1.2)

Peso: w400 ou w500

Espaçamento (letterSpacing): -0.2

Aplicação: Nomes de ocasiões, categorias de estilo e citações curatoriais.

UI Headline

Fonte: Inter Tight (substituto livre da grotesca PP Neue Montreal da referência)

Tamanho / Altura: 15pt (height: 1.30)

Peso: w600

Espaçamento (letterSpacing): -0.2

Aplicação: Títulos de seções, botões de ação primária e abas de navegação.

Body Reading

Fonte: Inter Tight

Tamanho / Altura: 14pt (height: 1.45)

Peso: w400

Espaçamento (letterSpacing): 0.0

Aplicação: Descrição detalhada de peças e notas têxteis.

Metadados & Badges

Fonte: Inter Tight

Tamanho / Altura: 11pt (height: 1.30)

Peso: w600

Espaçamento (letterSpacing): +1.2 (sempre em Caixa Alta)

Aplicação: Selos de certificação IHE e identificadores morfocromáticos (Lab*).

Regra de cor tipográfica: sobre Sala, ivoryText (títulos) e ivoryMuted (legendas); sobre paperBone, inkText e inkSecondary. Títulos Display podem receber gildedLeaf apenas sobre Sala.

6. Pipeline de Mídia & Renderização de Silhuetas (Canal Alfa)
6.1 Renderização de Peças Recortadas
Qualidade de Reamostragem: Imagens segmentadas devem utilizar obrigatoriamente FilterQuality.medium para evitar serrilhado em telas de alta densidade.

Sombra de Silhueta: Para projetar sombras realistas no contorno de peças com fundo transparente, utilize renderização de máscara alfa via ShaderMask ou CustomPainter, nunca BoxShadow no container pai. Sobre Sala escura, preferir um halo de luz suave (máscara alfa clareada) em vez de sombra.

Prevenção de Estouro de Memória: O carregamento via rede deve restringir as dimensões decodificadas no heap via memCacheWidth e memCacheHeight, calculados com base na largura da tela multiplicada pelo devicePixelRatio. Vale também para as texturas das Salas.

6.2 Estados de Carregamento Editorial
Shimmer Tingido: Varredura linear lenta (1200ms a 1500ms) entre a cor da Sala atual e a mesma cor clareada ~12%. Sobre paperBone, entre paperBone e paperBoneRaised.

Entrada Suave: Transição de imagem com fade gradual cruzado orquestrada com a curva AppMotion.editorialDecel; o cartão que a contém pode entrar com theatricalGesture em escala (0.96 → 1.0).

7. Padrões Estruturais de Componentes
7.1 "The Floating Canvas" (Arara Virtual)
As roupas recortadas flutuam diretamente sobre a Sala silkEmerald, sem cartão atrás, com grid de respiração ampla e halo de luz no contorno (6.1).

O arraste de peças para montagem de look deve disparar HapticFeedback.selectionClick() a cada encaixe magnético na arara, com o encaixe animado por theatricalGesture.

Finalização ou aprovação de look aciona HapticFeedback.mediumImpact().

7.2 Medidor de IHE (Índice de Harmonia Estética)
Componente inspirado em joalheria e folha de ouro, sempre sobre Sala:

Traço fino vetorial desenhado via CustomPainter com gradiente metálico de gildedLeaf (claro → escuro → claro, simulando reflexo de ouro batido).

Pontuação central em Bodoni Moda, 56pt, ivoryText; o sinal de porcentagem em gildedLeaf.

Decomposição visual dos 4 pilares:

Harmonia Cromática (S_cor): Chip tonal da cor dominante no espaço L*a*b* correlacionado à cartela do usuário.

Compensação Morfológica (S_bio): Ícone linear refinado de equilíbrio de silhueta.

Contexto & Clima (S_ocasion): Badge sutil com dados climáticos locais e nível de formalidade.

Similaridade Vetorial (S_cos): Indicador de ressonância com o acervo prévio.

Para pontuações iguais ou superiores a 75%, exibir o selo ✦ Look Fortemente Recomendado em caixa alta com kerning expandido (+1.2), em gildedLeaf, e a Sala transita para gildedOchre.

7.3 Mirror Mode (Provador em Loja & AR)
Visor de câmera com HUD minimalista de enquadramento em linhas ultrafinas gildedLeaf.

DraggableScrollableSheet translúcida com BackdropFilter (desfoque gaussiano de 16px) sobre tapestryNoir a 70%, exibindo carrossel horizontal de harmonizações imediatas em texto ivoryText.

Ação em 1 toque para sobreposição da peça virtual sobre o reflexo do provador.

7.4 Feed Comunitário: "Editorial Gallery"
Grid assimétrico de alvenaria (flutter_staggered_grid_view ou slivers customizados com proporções 3:4 e 4:5) sobre tapestryNoir.

Hotspots circulares sutis (anel gildedLeaf capilar) sobre as peças que expandem ao toque revelando marca, tecido e composição de cores em uma folha paperBone.

7.5 Folhas de Leitura (paperBone)
Formulários, descrições longas e configurações aparecem em folhas paperBone com cantos radiusLarge que sobem sobre a Sala, como uma página sobre o veludo. Dentro da folha valem as cores de texto ink; fora dela, as cores ivory.

8. Arquitetura & Instrução de Execução
Separação Rígida de Camadas: Widgets em lib/presentation/ desacoplados de regras de negócio, chamadas diretas de backend e clientes HTTP.

Componentização Autoral: Proibido misturar estilos globais inline repetidos. Todo estilo recorrente deve ser abstraído em componentes ou extensões de ThemeData. A cenografia (Sala, textura, vinheta, fundo guiado pelo scroll) é um componente único reutilizado por todas as telas; nenhuma tela implementa seu próprio fundo.

Instrução de Execução: Ao implementar qualquer interface para o HarmonIA, adote rigorosamente o padrão de um Diretor Criativo e Engenheiro de Front-End de Moda de Alta Costura. Priorize cenografia com profundidade, precisão tipográfica, contraste verificado, espaçamento harmônico, feedback tátil refinado e execução técnica limpa no Flutter.
