import 'package:flutter/material.dart';

/// Design Tokens oficiais do HarmonIA conforme AGENTS.md
class AppColors {
  AppColors._();

  // ── Renascença do Ateliê (AGENTS.md seção 3) ─────────────────────────────
  // Salas Cromáticas: cenografia de fundo, sempre com textura (ver AtelierRoom)
  static const Color velvetBordeaux = Color(0xFF3B1829);
  static const Color silkEmerald = Color(0xFF1C3120);
  static const Color frescoBlue = Color(0xFF2A5261);
  static const Color verdigris = Color(0xFF1B4543);
  static const Color gildedOchre = Color(0xFF634524);
  static const Color tapestryNoir = Color(0xFF0E0C0A);

  // Superfícies e texto
  static const Color paperBone = Color(0xFFE9E4D6);       // Cartões e folhas de leitura
  static const Color paperBoneRaised = Color(0xFFF4EFE3);
  static const Color ivoryText = Color(0xFFF4EEE1);       // Texto sobre qualquer Sala
  static const Color ivoryMuted = Color(0xD9F4EEE1);      // Legendas sobre Sala (85%)
  static const Color inkText = Color(0xFF15110E);         // Texto sobre paperBone
  static const Color inkSecondary = Color(0xFF5E554B);
  static const Color hairlineIvory = Color(0x33F4EEE1);
  static const Color hairlineInk = Color(0x1F15110E);

  // Acentos
  static const Color accentCinnabar = Color(0xFFB8361E);  // CTA, rótulo sempre ivoryText
  static const Color gildedLeaf = Color(0xFFD4AE5C);      // Realces e IHE >= 75%, só sobre Sala (ver AtelierRoom.allowsSmallGoldText)
  static const Color verdigrisLight = Color(0xFF6FA59A);  // ESG sobre Sala

  // ── Tokens legados (telas ainda não migradas para a Renascença) ──────────
  // Cores de Superfície & Fundo
  static const Color surfaceCanvas = Color(0xFFFBF9F5); // Fundo primário creme quente
  static const Color surfaceCanvasDark = Color(0xFF121212);
  static const Color surfaceRaised = Color(0xFFF3EFEA); // Cards editoriais e araras
  static const Color surfaceSubtle = Color(0xFFEBE5DC); // Fundo secundário e divisórias
  static const Color surfaceElevated = Color(0xFFFFFFFF); // Elevações limpas e overlays

  // Tipografia & Contraste
  static const Color textPrimary = Color(0xFF1A1817);   // Preto carvão profundo
  static const Color textSecondary = Color(0xFF706B65); // Metadados e legendas
  static const Color textTertiary = Color(0xFF9E9890);  // Dicas discretas
  static const Color textMuted = Color(0xFFA09990);     // Placeholders e auxiliares

  // Hairlines & Divisores
  static const Color borderSubtle = Color(0x141A1817);  // Hairline borders (0.5 a 1.0)
  static const Color borderGold = Color(0x3DB88E3E);    // Micro-borda joalheria

  // Acentos do Ecossistema
  static const Color accentTerracotta = Color(0xFFA34836); // Ação primária (CTA)
  static const Color accentOlive = Color(0xFF4B5842);      // Consumo consciente / ESG
  static const Color accentSand = Color(0xFFD9CDBF);       // Apoio a silhuetas
  static const Color iheGold = Color(0xFFB88E3E);          // IHE >= 75%
  static const Color iheGoldLight = Color(0xFFF5EACB);     // Fundo suave da chancela IHE

  // Sombras Orgânicas Editoriais
  static const List<BoxShadow> editorialShadow = [
    BoxShadow(
      color: Color(0x0A1A1817),
      blurRadius: 28,
      offset: Offset(0, 14),
    ),
    BoxShadow(
      color: Color(0x051A1817),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> floatingGarmentShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];
}
