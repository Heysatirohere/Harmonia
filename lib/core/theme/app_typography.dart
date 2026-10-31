import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tipografia Editorial do HarmonIA conforme AGENTS.md (seção 5)
/// - Títulos & Métricas: didone de altíssimo contraste (Bodoni Moda)
/// - Corpo & UI Operacional: grotesca neutra (Inter Tight)
/// Cor padrão = tinta (para folhas paperBone); sobre uma Sala, passe as cores ivory explicitamente.
class AppTypography {
  AppTypography._();

  // Títulos Editoriais (Serif)
  static TextStyle editorialTitleLarge({Color color = AppColors.inkText}) {
    return GoogleFonts.bodoniModa(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      height: 1.25,
      color: color,
    );
  }

  static TextStyle editorialTitleMedium({Color color = AppColors.inkText}) {
    return GoogleFonts.bodoniModa(
      fontSize: 19,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.3,
      color: color,
    );
  }

  static TextStyle editorialTitleSmall({Color color = AppColors.inkText}) {
    return GoogleFonts.bodoniModa(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      height: 1.3,
      color: color,
    );
  }

  // Métricas de IHE & Números de Destaque
  static TextStyle iheMetric({Color color = AppColors.gildedInk}) {
    return GoogleFonts.bodoniModa(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.0,
      color: color,
    );
  }

  static TextStyle iheMetricLarge({Color color = AppColors.inkText}) {
    return GoogleFonts.bodoniModa(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.0,
      height: 1.0,
      color: color,
    );
  }

  // Corpo & Operacional (Sans-serif)
  static TextStyle bodyMedium({Color color = AppColors.inkText}) {
    return GoogleFonts.interTight(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.5,
      color: color,
    );
  }

  static TextStyle bodySmall({Color color = AppColors.inkSecondary}) {
    return GoogleFonts.interTight(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.4,
      color: color,
    );
  }

  // Rótulos, Badges & Metadados
  static TextStyle authorName({Color color = AppColors.inkText}) {
    return GoogleFonts.interTight(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: color,
    );
  }

  static TextStyle metaLabel({Color color = AppColors.inkSecondary}) {
    return GoogleFonts.interTight(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
      color: color,
    );
  }

  static TextStyle sealLabel({Color color = AppColors.gildedInk}) {
    return GoogleFonts.interTight(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: color,
    );
  }

  static TextStyle esgTag({Color color = AppColors.verdigrisInk}) {
    return GoogleFonts.interTight(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: color,
    );
  }

  // Métodos de Suporte Editorial (AGENTS.md Seção 5)
  static TextStyle displayEditorial({Color color = AppColors.inkText}) {
    return GoogleFonts.bodoniModa(
      fontSize: 40,
      fontWeight: FontWeight.w600,
      letterSpacing: -1.0,
      height: 1.05,
      color: color,
    );
  }

  static TextStyle subtitleCuratorial({Color color = AppColors.inkSecondary}) {
    return GoogleFonts.bodoniModa(
      fontSize: 20,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      letterSpacing: -0.2,
      height: 1.2,
      color: color,
    );
  }

  static TextStyle uiHeadline({Color color = AppColors.inkText}) {
    return GoogleFonts.interTight(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.30,
      color: color,
    );
  }

  static TextStyle bodyReading({Color color = AppColors.inkText}) {
    return GoogleFonts.interTight(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.0,
      height: 1.45,
      color: color,
    );
  }

  static TextStyle metadataBadge({Color color = AppColors.inkSecondary}) {
    return GoogleFonts.interTight(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
      height: 1.30,
      color: color,
    );
  }

  // ── Renascença do Ateliê: escala de revista sobre Sala (AGENTS.md Seção 5) ──
  static TextStyle heroDisplay({Color color = AppColors.ivoryText, double fontSize = 56}) {
    return GoogleFonts.bodoniModa(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.0,
      height: 1.05,
      color: color,
    );
  }

  static TextStyle atelierHero({Color color = AppColors.ivoryText}) =>
      heroDisplay(color: color, fontSize: 56);

  static TextStyle atelierDisplay({Color color = AppColors.ivoryText, double fontSize = 40}) {
    return GoogleFonts.bodoniModa(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: -1.0,
      height: 1.05,
      color: color,
    );
  }

  static TextStyle atelierSubtitle({Color color = AppColors.ivoryMuted}) =>
      subtitleCuratorial(color: color);

  static TextStyle atelierHeadline({Color color = AppColors.ivoryText}) =>
      uiHeadline(color: color);

  static TextStyle atelierBody({Color color = AppColors.ivoryText}) =>
      bodyReading(color: color);

  static TextStyle atelierBadge({Color color = AppColors.ivoryMuted}) =>
      metadataBadge(color: color);

  static TextStyle sectionDisplay({Color color = AppColors.ivoryText}) {
    return GoogleFonts.bodoniModa(
      fontSize: 30,
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
      letterSpacing: -0.6,
      height: 1.1,
      color: color,
    );
  }

  static TextStyle atelierMeta({Color color = AppColors.ivoryMuted}) {
    return GoogleFonts.interTight(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
      height: 1.30,
      color: color,
    );
  }
}
