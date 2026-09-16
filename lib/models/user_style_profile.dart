import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Mapeamento dos 5 Biótipos Corporais Principais (RF02)
enum BodySilhouetteType {
  ampulheta,
  retangulo,
  triangulo,
  trianguloInvertido,
  oval,
}

extension BodySilhouetteExtension on BodySilhouetteType {
  String get displayName {
    switch (this) {
      case BodySilhouetteType.ampulheta:
        return 'Ampulheta';
      case BodySilhouetteType.retangulo:
        return 'Retângulo';
      case BodySilhouetteType.triangulo:
        return 'Triângulo';
      case BodySilhouetteType.trianguloInvertido:
        return 'Triângulo Invertido';
      case BodySilhouetteType.oval:
        return 'Oval';
    }
  }

  String get description {
    switch (this) {
      case BodySilhouetteType.ampulheta:
        return 'Ombros e quadris alinhados com cintura destacada e harmoniosa.';
      case BodySilhouetteType.retangulo:
        return 'Ombros, cintura e quadris com proporções similares e linhas retas.';
      case BodySilhouetteType.triangulo:
        return 'Quadris mais largos que os ombros, criando um ponto focal inferior.';
      case BodySilhouetteType.trianguloInvertido:
        return 'Ombros mais largos que os quadris, trazendo estrutura superior.';
      case BodySilhouetteType.oval:
        return 'Linhas suaves e arredondadas com foco na região central do corpo.';
    }
  }

  String get recommendationNote {
    switch (this) {
      case BodySilhouetteType.ampulheta:
        return 'Valorize a cintura com peças acinturadas, regatas fluidas e alfaiataria ajustada.';
      case BodySilhouetteType.retangulo:
        return 'Crie ilusão de curvas usando sobreposições, cintos finos e pantalonas estruturadas.';
      case BodySilhouetteType.triangulo:
        return 'Destaque a parte superior com blazers desestruturados e golas trabalhadas.';
      case BodySilhouetteType.trianguloInvertido:
        return 'Equilibre a silhueta com calças pantalonas fluidas, saias plissadas e decotes V.';
      case BodySilhouetteType.oval:
        return 'Aposte em linhas verticais alongadas, trench coats abertos e decotes em U ou V.';
    }
  }
}

/// Mapeamento das 12 Cartelas Sazonais Expandidas de Colorimetria Pessoal
enum SeasonalPaletteType {
  outonoQuente,
  outonoSuave,
  outonoEscuro,
  invernoFrio,
  invernoVivo,
  invernoEscuro,
  primaveraClara,
  primaveraQuente,
  primaveraVibrante,
  veraoSuave,
  veraoFrio,
  veraoClaro,
}

extension SeasonalPaletteExtension on SeasonalPaletteType {
  String get displayName {
    switch (this) {
      case SeasonalPaletteType.outonoQuente:
        return 'Outono Quente';
      case SeasonalPaletteType.outonoSuave:
        return 'Outono Suave';
      case SeasonalPaletteType.outonoEscuro:
        return 'Outono Escuro';
      case SeasonalPaletteType.invernoFrio:
        return 'Inverno Frio';
      case SeasonalPaletteType.invernoVivo:
        return 'Inverno Vivo';
      case SeasonalPaletteType.invernoEscuro:
        return 'Inverno Escuro';
      case SeasonalPaletteType.primaveraClara:
        return 'Primavera Clara';
      case SeasonalPaletteType.primaveraQuente:
        return 'Primavera Quente';
      case SeasonalPaletteType.primaveraVibrante:
        return 'Primavera Vibrante';
      case SeasonalPaletteType.veraoSuave:
        return 'Verão Suave';
      case SeasonalPaletteType.veraoFrio:
        return 'Verão Frio';
      case SeasonalPaletteType.veraoClaro:
        return 'Verão Claro';
    }
  }

  String get temperature {
    switch (this) {
      case SeasonalPaletteType.outonoQuente:
      case SeasonalPaletteType.outonoSuave:
      case SeasonalPaletteType.outonoEscuro:
      case SeasonalPaletteType.primaveraQuente:
      case SeasonalPaletteType.primaveraClara:
      case SeasonalPaletteType.primaveraVibrante:
        return 'Subtom Quente Térreo';
      case SeasonalPaletteType.invernoFrio:
      case SeasonalPaletteType.invernoVivo:
      case SeasonalPaletteType.invernoEscuro:
      case SeasonalPaletteType.veraoFrio:
      case SeasonalPaletteType.veraoSuave:
      case SeasonalPaletteType.veraoClaro:
        return 'Subtom Frio Rosado';
    }
  }

  List<Color> get colorSwatches {
    switch (this) {
      case SeasonalPaletteType.outonoQuente:
        return const [
          AppColors.accentTerracotta,
          AppColors.accentOlive,
          AppColors.iheGold,
          AppColors.accentSand,
          Color(0xFF8B4513),
          Color(0xFF2E8B57),
        ];
      case SeasonalPaletteType.outonoSuave:
        return const [
          AppColors.accentSand,
          AppColors.accentOlive,
          Color(0xFFC2B280),
          Color(0xFFB0C4DE),
          Color(0xFF808000),
          Color(0xFFD2B48C),
        ];
      case SeasonalPaletteType.outonoEscuro:
        return const [
          AppColors.textPrimary,
          AppColors.accentTerracotta,
          Color(0xFF4A0E17),
          Color(0xFF1B4D3E),
          AppColors.iheGold,
          Color(0xFF3B2F2F),
        ];
      case SeasonalPaletteType.invernoFrio:
      case SeasonalPaletteType.invernoVivo:
      case SeasonalPaletteType.invernoEscuro:
        return const [
          AppColors.textPrimary,
          Color(0xFF000080),
          Color(0xFF800020),
          Color(0xFF4B0082),
          AppColors.surfaceCanvas,
          Color(0xFF2F4F4F),
        ];
      case SeasonalPaletteType.primaveraClara:
      case SeasonalPaletteType.primaveraQuente:
      case SeasonalPaletteType.primaveraVibrante:
        return const [
          Color(0xFFFF7F50),
          Color(0xFFFFD700),
          Color(0xFF98FB98),
          AppColors.accentSand,
          Color(0xFFE6E6FA),
          Color(0xFFF4A460),
        ];
      case SeasonalPaletteType.veraoSuave:
      case SeasonalPaletteType.veraoFrio:
      case SeasonalPaletteType.veraoClaro:
        return const [
          Color(0xFF708090),
          Color(0xFFBC8F8F),
          Color(0xFFB0C4DE),
          Color(0xFFD8BFD8),
          AppColors.surfaceSubtle,
          Color(0xFF4682B4),
        ];
    }
  }
}

/// Modelo de Perfil de Estilo & Morfocromia do Usuário
class UserStyleProfile {
  final String userName;
  final BodySilhouetteType silhouette;
  final SeasonalPaletteType seasonalPalette;
  final String contrastLevel;
  final String styleArchetype;
  final bool isCompleted;

  const UserStyleProfile({
    required this.userName,
    required this.silhouette,
    required this.seasonalPalette,
    required this.contrastLevel,
    required this.styleArchetype,
    this.isCompleted = true,
  });

  /// Perfil Curatorial Padrão para Testes e Exibição Inicial
  factory UserStyleProfile.defaultProfile() {
    return const UserStyleProfile(
      userName: 'Helena Vasconcelos',
      silhouette: BodySilhouetteType.ampulheta,
      seasonalPalette: SeasonalPaletteType.outonoQuente,
      contrastLevel: 'Médio-Alto Contraste Quente',
      styleArchetype: 'Minimalismo Quente & Alfaiataria Desestruturada',
    );
  }

  UserStyleProfile copyWith({
    String? userName,
    BodySilhouetteType? silhouette,
    SeasonalPaletteType? seasonalPalette,
    String? contrastLevel,
    String? styleArchetype,
    bool? isCompleted,
  }) {
    return UserStyleProfile(
      userName: userName ?? this.userName,
      silhouette: silhouette ?? this.silhouette,
      seasonalPalette: seasonalPalette ?? this.seasonalPalette,
      contrastLevel: contrastLevel ?? this.contrastLevel,
      styleArchetype: styleArchetype ?? this.styleArchetype,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
