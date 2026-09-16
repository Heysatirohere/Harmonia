import 'package:flutter/material.dart';

/// Design Tokens oficiais do HarmonIA conforme AGENTS.md
class AppColors {
  AppColors._();

  // Cores de Superfície & Fundo
  static const Color surfaceCanvas = Color(0xFFFBF9F5); // Fundo primário creme quente
  static const Color surfaceCanvasDark = Color(0xFF121212);
  static const Color surfaceRaised = Color(0xFFF3EFEA); // Cards editoriais e araras
  static const Color surfaceElevated = Color(0xFFFFFFFF); // Elevações limpas e overlays

  // Tipografia & Contraste
  static const Color textPrimary = Color(0xFF1A1817);   // Preto carvão profundo
  static const Color textSecondary = Color(0xFF706B65); // Metadados e legendas
  static const Color textTertiary = Color(0xFF9E9890);  // Dicas discretas

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
