import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

export '../core/theme/app_colors.dart';
export '../core/theme/app_typography.dart';

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
