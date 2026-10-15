import 'dart:ui';

import '../core/color/lab_color.dart';
import 'affiliated_product.dart';

/// Peça-chave que falta no acervo e os looks que ela destravaria (RF11)
class WardrobeGap {
  final String id;
  final String title;

  /// Família da peça no motor: top, bottom, shoes ou one_piece
  final String category;
  final String stylisticRationale;
  final Color color;
  final int looksEvaluated;
  final int strongLooks;
  final double bestIhe;

  /// Pontos percentuais do melhor look novo sobre a média dos looks de hoje
  final double deltaIhe;
  final List<AffiliatedProduct> suggestedProducts;

  const WardrobeGap({
    required this.id,
    required this.title,
    required this.category,
    required this.stylisticRationale,
    required this.color,
    required this.looksEvaluated,
    required this.strongLooks,
    required this.bestIhe,
    required this.deltaIhe,
    required this.suggestedProducts,
  });

  factory WardrobeGap.fromJson(Map<String, dynamic> json) => WardrobeGap(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        stylisticRationale: json['rationale'] as String,
        color: hexToColor(json['color_hex'] as String),
        looksEvaluated: json['looks_evaluated'] as int,
        strongLooks: json['strong_looks'] as int,
        bestIhe: (json['best_ihe_percentage'] as num).toDouble(),
        deltaIhe: (json['delta_ihe'] as num).toDouble(),
        suggestedProducts: [
          for (final product in json['products'] as List<dynamic>)
            AffiliatedProduct.fromJson(product as Map<String, dynamic>),
        ],
      );

  /// RN03: a API já remove os esgotados; a tela ainda filtra por garantia
  List<AffiliatedProduct> get availableProducts => suggestedProducts.where((product) => product.inStock).toList();
}

/// Lacunas ranqueadas para a ocasião pedida
class WardrobeGapReport {
  final String occasion;

  /// Média do IHE dos looks possíveis hoje; nula quando o acervo ainda não forma looks
  final double? baselineIhe;
  final List<WardrobeGap> gaps;

  const WardrobeGapReport({required this.occasion, required this.baselineIhe, required this.gaps});

  factory WardrobeGapReport.fromJson(Map<String, dynamic> json) => WardrobeGapReport(
        occasion: json['occasion'] as String,
        baselineIhe: (json['baseline_ihe_percentage'] as num?)?.toDouble(),
        gaps: [
          for (final gap in json['gaps'] as List<dynamic>) WardrobeGap.fromJson(gap as Map<String, dynamic>),
        ],
      );
}
