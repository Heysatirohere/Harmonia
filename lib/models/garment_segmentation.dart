import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import '../core/color/lab_color.dart';

/// Falha no pipeline de segmentação, com mensagem pronta para exibir ao usuário
class SegmentationException implements Exception {
  final String message;
  const SegmentationException(this.message);

  @override
  String toString() => message;
}

/// Cor dominante extraída da peça recortada, no espaço CIE L*a*b* (RF05)
class GarmentColor {
  final double l;
  final double a;
  final double b;
  final String hex;
  final int percentage;
  final String name;

  const GarmentColor({
    required this.l,
    required this.a,
    required this.b,
    required this.hex,
    required this.percentage,
    required this.name,
  });

  Color get color => hexToColor(hex);
  String get labLabel => formatLab(l, a, b);

  factory GarmentColor.fromJson(Map<String, dynamic> json) {
    return GarmentColor(
      l: (json['L'] as num).toDouble(),
      a: (json['a'] as num).toDouble(),
      b: (json['b'] as num).toDouble(),
      hex: json['hex'] as String,
      percentage: json['percentage'] as int,
      name: json['name'] as String,
    );
  }
}

/// Atributos que a IA sugere para a peça (RF05); a pessoa confirma ou corrige no formulário
class GarmentSuggestion {
  /// Categoria do app ('Partes de cima'…); nula quando a IA não tem confiança
  final String? category;

  /// Nome com a estampa, ex: 'Camisa com listras'; nulo sem confiança
  final String? name;
  final String? pattern;
  final double formality;
  final double confidence;

  const GarmentSuggestion({this.category, this.name, this.pattern, required this.formality, required this.confidence});

  factory GarmentSuggestion.fromJson(Map<String, dynamic> json) => GarmentSuggestion(
        category: json['category'] as String?,
        name: json['name'] as String?,
        pattern: json['pattern'] as String?,
        formality: (json['formality'] as num).toDouble(),
        confidence: (json['confidence'] as num).toDouble(),
      );
}

/// Resultado do pipeline de recorte de fundo e extração cromática (RF04, RF05)
class GarmentSegmentation {
  final Uint8List cutoutPng;
  final int width;
  final int height;
  final List<GarmentColor> colors;
  final int processingMs;

  /// Vetor de estilo da peça (512d) para o pilar S_cos; nulo se o servidor estiver sem o modelo
  final List<double>? styleEmbedding;

  /// Categoria, nome e formalidade sugeridos; nulo se o servidor estiver sem o modelo
  final GarmentSuggestion? suggestion;

  const GarmentSegmentation({
    required this.cutoutPng,
    required this.width,
    required this.height,
    required this.colors,
    required this.processingMs,
    this.styleEmbedding,
    this.suggestion,
  });

  factory GarmentSegmentation.fromJson(Map<String, dynamic> json) {
    return GarmentSegmentation(
      cutoutPng: base64Decode(json['image_png_base64'] as String),
      width: json['width'] as int,
      height: json['height'] as int,
      colors: (json['colors'] as List)
          .map((c) => GarmentColor.fromJson(c as Map<String, dynamic>))
          .toList(),
      processingMs: json['processing_ms'] as int,
      styleEmbedding: (json['style_embedding'] as List?)?.map((v) => (v as num).toDouble()).toList(),
      suggestion: json['suggestion'] == null
          ? null
          : GarmentSuggestion.fromJson(json['suggestion'] as Map<String, dynamic>),
    );
  }
}
