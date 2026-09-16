import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tipografia Editorial do HarmonIA conforme AGENTS.md
/// - Títulos & Métricas: Serifadas elegantes (Playfair Display / Fraunces)
/// - Corpo & UI Operacional: Sans-serif geométrica neutra (Plus Jakarta Sans / Inter)
class AppTypography {
  AppTypography._();

  // Títulos Editoriais (Serif)
  static TextStyle editorialTitleLarge({Color color = AppColors.textPrimary}) {
    return GoogleFonts.playfairDisplay(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      height: 1.25,
      color: color,
    );
  }

  static TextStyle editorialTitleMedium({Color color = AppColors.textPrimary}) {
    return GoogleFonts.playfairDisplay(
      fontSize: 19,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.3,
      color: color,
    );
  }

  static TextStyle editorialTitleSmall({Color color = AppColors.textPrimary}) {
    return GoogleFonts.playfairDisplay(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      height: 1.3,
      color: color,
    );
  }

  // Métricas de IHE & Números de Destaque
  static TextStyle iheMetric({Color color = AppColors.iheGold}) {
    return GoogleFonts.playfairDisplay(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.0,
      color: color,
    );
  }

  static TextStyle iheMetricLarge({Color color = AppColors.textPrimary}) {
    return GoogleFonts.playfairDisplay(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.0,
      height: 1.0,
      color: color,
    );
  }

  // Corpo & Operacional (Sans-serif)
  static TextStyle bodyMedium({Color color = AppColors.textPrimary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.5,
      color: color,
    );
  }

  static TextStyle bodySmall({Color color = AppColors.textSecondary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.4,
      color: color,
    );
  }

  // Rótulos, Badges & Metadados
  static TextStyle authorName({Color color = AppColors.textPrimary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: color,
    );
  }

  static TextStyle metaLabel({Color color = AppColors.textSecondary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
      color: color,
    );
  }

  static TextStyle sealLabel({Color color = AppColors.iheGold}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: color,
    );
  }

  static TextStyle esgTag({Color color = AppColors.accentOlive}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: color,
    );
  }
}
