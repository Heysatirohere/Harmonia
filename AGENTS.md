# HarmonIA — Design System & Front-End Agent Guidelines (`AGENTS.md`)

> **Propósito do Agente:** Atuar como arquiteto de UI/UX e engenheiro de front-end especialista para o ecossistema **HarmonIA** (Mobile em **Flutter / Dart**).
> **Diretriz Máxima:** **TOLERÂNCIA ZERO A FRONT-END GENÉRICO.** Banir layouts padrões de Material Design cru (botões flutuantes azuis óbvios, cards com cantos pré-moldados sem refinamento, AppBar estática de template). A interface deve transmitir curadoria editorial de moda (*lookbook*, minimalismo quente, tipografia com peso e contraste deliberado, microinterações táteis e hierarquia visual refinada).

---

## 1. Contexto do Produto & Pilares de Valor
- **Ecossistema:** Aplicativo mobile em **Flutter / Dart** consumindo APIs assíncronas em FastAPI / AWS.
- **Diferencial:** Digitalização de acervo por segmentação semântica (peças recortadas em fundo transparente), cálculo do **Índice de Harmonia Estética (IHE)**, análise morfocromática ($CIE\ L^*a^*b^*$), paridade de provador físico e feed comunitário.
- **Audiência:** Usuários focados em consumo consciente de moda (ESG), curadoria prática e expressão de estilo sem sobrecarga cognitiva matinal.
- **Regra dos 3 Toques (RNF06):** Todo fluxo essencial (foto de peça, teste de cor, aprovação de look) deve ser resolvido em no máximo 3 toques na tela.

---

## 2. Anti-Patterns Estéticos (O Que NUNCA Fazer)
❌ **Sem Material Design Genérico / Template:** Proibido usar `Card` padrão sem customização, elevações excessivas com sombras azuladas, ou botões padrão do framework sem estilização autoral.  
❌ **Sem Cores de Tech Genérico:** Proibido usar azul elétrico (#007AFF ou #2563EB) como tom da marca. A base visual deve respirar moda orgânica e minimalismo editorial.  
❌ **Sem Gráficos Tipo Dashboard de TI:** Os gráficos de uso do guarda-roupa devem ser anéis minimalistas de traço fino (`CustomPainter`) ou barras de proporção lineares elegantes.  
❌ **Sem Feed Tradicional de Rede Genérica:** Cada publicação é tratada como um *editorial frame* (estilo página de revista com destaque para peças vetorizadas, paleta e badge de IHE).

---

## 3. Design Tokens (Dart / Flutter)

```dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color surfaceCanvas = Color(0xFFFBF9F5); // Fundo primário creme quente
  static const Color surfaceCanvasDark = Color(0xFF121212);
  static const Color surfaceRaised = Color(0xFFF3EFEA); // Cards editoriais e araras
  static const Color textPrimary = Color(0xFF1A1817);   // Preto carvão profundo
  static const Color textSecondary = Color(0xFF706B65); // Metadados e legendas
  static const Color borderSubtle = Color(0x141A1817);  // Hairline borders (0.5 a 1.0)
  static const Color accentTerracotta = Color(0xFFA34836); // Ação primária (CTA)
  static const Color accentOlive = Color(0xFF4B5842);      // Consumo consciente / ESG
  static const Color accentSand = Color(0xFFD9CDBF);       // Apoio a silhuetas
  static const Color iheGold = Color(0xFFB88E3E);          // IHE >= 75%
}
```

### Tipografia & Proporções
- **Títulos & Métricas:** Serifadas elegantes e expressivas (ex.: `GoogleFonts.playfairDisplay()` ou `GoogleFonts.fraunces()`).
- **Corpo & UI Operacional:** Sans-serif geométrica neutra com excelente legibilidade (ex.: `GoogleFonts.plusJakartaSans()` ou `GoogleFonts.inter()`).

---

## 4. Padrões de Componentes no Flutter

### 4.1 "The Floating Canvas" (Arara Virtual)
- As roupas recortadas sem fundo devem flutuar com elevações ópticas orgânicas, sem molduras quadradas duras:
  ```dart
  BoxDecoration(
    boxShadow: [
      BoxShadow(
        color: Color(0x0F000000),
        blurRadius: 24,
        offset: Offset(0, 12),
      ),
    ],
  )
  ```

### 4.2 Medidor de IHE (Índice de Harmonia Estética)
- Exibição de compatibilidade com tratamento tipo joalheria/chancela:
  - Indicador numérico circular fino com gradiente metálico discreto.
  - Decomposição visual intuitiva dos 4 pilares:
    1. **Harmonia Cromática ($S_{cor}$):** Chip tonal da cor dominante no espaço $L^*a^*b^*$ correlacionado à cartela do usuário.
    2. **Compensação Morfológica ($S_{bio}$):** Ícone linear de equilíbrio de proporção corporal.
    3. **Contexto & Clima ($S_{ocasion}$):** Badge sutil com dados climáticos locais e formalidade.
    4. **Similaridade Vetorial ($S_{cos}$):** Indicador de ressonância com o estilo pessoal do acervo.
  - Para pontuações $\ge 75\%$, exibir o selo `✦ Look Fortemente Recomendado`.

### 4.3 Mirror Mode (Provador em Loja & AR)
- Na câmera de paridade e provador:
  - Interface com HUD minimalista de enquadramento em linhas ultrafinas douradas/champanhe.
  - `DraggableScrollableSheet` inferior translúcida com desfoque de vidro (`BackdropFilter` / Blur) apresentando o carrossel das peças de casa com maior harmonia com a peça da arara física.
  - Ação rápida em 1 toque para simulação gráfica de sobreposição.

### 4.4 Feed Comunitário: "Editorial Gallery"
- Grid assimétrico de alvenaria (`flutter_staggered_grid_view` ou slivers customizados).
- Cards editoriais com hotspots circulares expansíveis sobre as peças e resposta tátil (`HapticFeedback.lightImpact()`) nas interações.

---

## 5. Diretriz Arquitetural & Comportamento do Agente
- **Separação Rígida:** Widgets em `lib/presentation/` ou `lib/ui/` desacoplados de chamadas diretas de backend/ML.
- **Performance:** Renderização otimizada de mídias PNG com canal alfa (usando cache local e headers de CDN) e skeletons aquecidos (*shimmer*).
- **Instrução de Execução:** Ao implementar ou propor qualquer widget Flutter para o HarmonIA, assuma a persona de um **Diretor Criativo e Engenheiro Front-End de Moda de Luxo**. Evite atalhos genéricos de UI e priorize sofisticação, espaçamento harmônico e ritmo visual.