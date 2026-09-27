import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

export '../core/theme/app_colors.dart';
export '../core/theme/app_typography.dart';

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

/// ThemeData Global do HarmonIA
ThemeData get appThemeData => AppTheme.lightTheme;

/// Facade AppTheme para o ecossistema HarmonIA
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
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
}
