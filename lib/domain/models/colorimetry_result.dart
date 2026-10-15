import 'dart:ui';

import '../../core/color/lab_color.dart';
import '../../models/user_style_profile.dart';

/// Resultado do teste de colorimetria por selfie (RF02): a cartela é sugestão, a pessoa confirma
class ColorimetryResult {
  final SeasonalPaletteType palette;
  final Color skinColor;

  /// QUENTE, NEUTRO ou FRIO
  final String undertone;

  /// CLARA, MEDIA ou PROFUNDA: a coloração inteira, pele e cabelo
  final String depth;

  /// BRILHANTE ou SUAVE
  final String intensity;

  const ColorimetryResult({
    required this.palette,
    required this.skinColor,
    required this.undertone,
    required this.depth,
    required this.intensity,
  });

  factory ColorimetryResult.fromJson(Map<String, dynamic> json) {
    final palette = SeasonalPaletteExtension.fromApiKey(json['palette'] as String?);
    if (palette == null) throw FormatException('Cartela desconhecida: ${json['palette']}');
    return ColorimetryResult(
      palette: palette,
      skinColor: hexToColor(json['skin_hex'] as String),
      undertone: json['undertone'] as String,
      depth: json['depth'] as String,
      intensity: json['intensity'] as String,
    );
  }

  /// Ex: "Subtom quente · coloração clara · brilhante"
  String get summary {
    final tone = switch (undertone) { 'QUENTE' => 'quente', 'FRIO' => 'frio', _ => 'neutro' };
    final value = switch (depth) { 'CLARA' => 'clara', 'PROFUNDA' => 'profunda', _ => 'média' };
    final glow = intensity == 'BRILHANTE' ? 'brilhante' : 'suave';
    return 'Subtom $tone · coloração $value · $glow';
  }
}
