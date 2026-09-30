import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tipografia Editorial do HarmonIA conforme AGENTS.md (seção 5)
/// - Títulos & Métricas: didone de altíssimo contraste (Bodoni Moda)
/// - Corpo & UI Operacional: grotesca neutra (Inter Tight)
class AppTypography {
  AppTypography._();

  // Títulos Editoriais (Serif)
  static TextStyle editorialTitleLarge({Color color = AppColors.textPrimary}) {
    return GoogleFonts.bodoniModa(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      height: 1.25,
      color: color,
    );
  }

  static TextStyle editorialTitleMedium({Color color = AppColors.textPrimary}) {
    return GoogleFonts.bodoniModa(
      fontSize: 19,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.3,
      color: color,
    );
  }

  static TextStyle editorialTitleSmall({Color color = AppColors.textPrimary}) {
    return GoogleFonts.bodoniModa(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      height: 1.3,
      color: color,
    );
  }

  // Métricas de IHE & Números de Destaque
  static TextStyle iheMetric({Color color = AppColors.iheGold}) {
    return GoogleFonts.bodoniModa(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.0,
      color: color,
    );
  }

  static TextStyle iheMetricLarge({Color color = AppColors.textPrimary}) {
    return GoogleFonts.bodoniModa(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.0,
      height: 1.0,
      color: color,
    );
  }

  // Corpo & Operacional (Sans-serif)
  static TextStyle bodyMedium({Color color = AppColors.textPrimary}) {
    return GoogleFonts.interTight(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.5,
      color: color,
    );
  }

  static TextStyle bodySmall({Color color = AppColors.textSecondary}) {
    return GoogleFonts.interTight(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.4,
      color: color,
    );
  }

  // Rótulos, Badges & Metadados
  static TextStyle authorName({Color color = AppColors.textPrimary}) {
    return GoogleFonts.interTight(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: color,
    );
  }

  static TextStyle metaLabel({Color color = AppColors.textSecondary}) {
    return GoogleFonts.interTight(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
      color: color,
    );
  }

  static TextStyle sealLabel({Color color = AppColors.iheGold}) {
    return GoogleFonts.interTight(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: color,
    );
  }

  static TextStyle esgTag({Color color = AppColors.accentOlive}) {
    return GoogleFonts.interTight(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: color,
    );
  }

  // Métodos de Suporte Editorial
  static TextStyle displayEditorial({Color color = AppColors.textPrimary}) {
    return GoogleFonts.bodoniModa(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.6,
      height: 1.15,
      color: color,
    );
  }

  static TextStyle subtitleCuratorial({Color color = AppColors.textSecondary}) {
    return GoogleFonts.bodoniModa(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      height: 1.25,
      color: color,
    );
  }

  static TextStyle uiHeadline({Color color = AppColors.textPrimary}) {
    return GoogleFonts.interTight(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.3,
      color: color,
    );
  }

  static TextStyle bodyReading({Color color = AppColors.textPrimary}) {
    return GoogleFonts.interTight(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: color,
    );
  }

  static TextStyle metadataBadge({Color color = AppColors.textSecondary}) {
    return GoogleFonts.interTight(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      height: 1.3,
      color: color,
    );
  }

  // ── Renascença do Ateliê: escala de revista sobre Sala ───────────────────
  static TextStyle heroDisplay({Color color = AppColors.ivoryText}) {
    return GoogleFonts.bodoniModa(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.4,
      height: 1.0,
      color: color,
    );
  }

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
      height: 1.3,
      color: color,
    );
  }
}
