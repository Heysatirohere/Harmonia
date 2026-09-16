import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cores Oficiais do HarmonIA conforme AGENTS.md
class AppColors {
  AppColors._();

  // Cores de Superfície & Fundo
  static const Color surfaceCanvas = Color(0xFFFBF9F5); // Linho / Creme quente primário
  static const Color surfaceCanvasDark = Color(0xFF141312); // Carvão profundo dark mode
  static const Color surfaceRaised = Color(0xFFF3EFEA); // Superfícies elevadas e bandejas
  static const Color surfaceSubtle = Color(0xFFEBE5DC); // Fundo secundário e divisórias
  static const Color surfaceElevated = Color(0xFFFFFFFF); // Elevações limpas e overlays

  // Tipografia & Contraste
  static const Color textPrimary = Color(0xFF1A1817); // Preto carvão editorial
  static const Color textSecondary = Color(0xFF706B65); // Legendas e metadados
  static const Color textMuted = Color(0xFFA09990); // Placeholders e auxiliares

  // Hairlines & Divisores
  static const Color borderSubtle = Color(0x141A1817); // Linhas capilares (0.5 a 1.0)
  static const Color borderGold = Color(0x3DB88E3E); // Micro-borda joalheria

  // Acentos do Ecossistema
  static const Color accentTerracotta = Color(0xFFA34836); // Ação primária (CTA)
  static const Color accentOlive = Color(0xFF4B5842); // Consumo consciente / ESG
  static const Color accentSand = Color(0xFFD9CDBF); // Apoio a silhuetas
  static const Color iheGold = Color(0xFFB88E3E); // IHE >= 75%
  static const Color iheGoldLight = Color(0xFFF5EACB); // Fundo suave da chancela IHE

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

/// Movimento & Física Orquestrada conforme AGENTS.md
class AppMotion {
  AppMotion._();

  static const Cubic editorialDecel = Cubic(0.16, 1.0, 0.3, 1.0); // Ease-Out-Expo
  static const Cubic editorialIn = Cubic(0.7, 0.0, 0.84, 0.0);

  static const Duration fast = Duration(milliseconds: 200); // Toggles, chips, microinterações
  static const Duration medium = Duration(milliseconds: 450); // Bottom sheets, cards
  static const Duration slow = Duration(milliseconds: 700); // Transições de silhueta e look completo
}

/// Espaçamentos & Dimensões Curatórias conforme AGENTS.md
class AppSpacing {
  AppSpacing._();

  static const double pageMargin = 24.0;
  static const double elementGap = 16.0;
  static const double tightGap = 8.0;

  static const double radiusLarge = 20.0;
  static const double radiusMedium = 14.0;
  static const double radiusSmall = 8.0;
}

/// Tipografia Editorial & Escala Rítmica conforme AGENTS.md
class AppTypography {
  AppTypography._();

  /// Display Editorial: Playfair Display 32pt (height: 1.15, w600/w700, letterSpacing: -0.6)
  static TextStyle displayEditorial({Color color = AppColors.textPrimary}) {
    return GoogleFonts.playfairDisplay(
      fontSize: 32,
      height: 1.15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.6,
      color: color,
    );
  }

  /// Subtítulo Curatorial: Playfair Display Italic 18pt (height: 1.25, w400, letterSpacing: 0.0)
  static TextStyle subtitleCuratorial({Color color = AppColors.textSecondary}) {
    return GoogleFonts.playfairDisplay(
      fontSize: 18,
      height: 1.25,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.0,
      color: color,
    );
  }

  /// UI Headline: Plus Jakarta Sans 15pt (height: 1.30, w600, letterSpacing: -0.2)
  static TextStyle uiHeadline({Color color = AppColors.textPrimary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 15,
      height: 1.30,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: color,
    );
  }

  /// Body Reading: Plus Jakarta Sans 13pt (height: 1.45, w400, letterSpacing: 0.0)
  static TextStyle bodyReading({Color color = AppColors.textPrimary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 13,
      height: 1.45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.0,
      color: color,
    );
  }

  /// Body Small: Plus Jakarta Sans 12pt (height: 1.4, w400, letterSpacing: 0.1)
  static TextStyle bodySmall({Color color = AppColors.textSecondary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 12,
      height: 1.4,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      color: color,
    );
  }

  /// Metadados & Badges: Plus Jakarta Sans 11pt (height: 1.30, w600, letterSpacing: +0.8, CAIXA ALTA)
  static TextStyle metadataBadge({Color color = AppColors.textSecondary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 11,
      height: 1.30,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: color,
    );
  }

  /// Selos ESG & Moda Consciente: Plus Jakarta Sans 10pt (w600, letterSpacing: 0.4)
  static TextStyle esgTag({Color color = AppColors.accentOlive}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 10,
      height: 1.30,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: color,
    );
  }
}

/// ThemeData Global do HarmonIA
ThemeData get appThemeData {
  return ThemeData(
    scaffoldBackgroundColor: AppColors.surfaceCanvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accentTerracotta,
      primary: AppColors.accentTerracotta,
      surface: AppColors.surfaceCanvas,
    ),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );
}
