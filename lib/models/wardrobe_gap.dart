import 'affiliated_product.dart';

/// Modelo de Análise de Lacunas de Armário (Gap Analysis - RF11 & RN03)
class WardrobeGap {
  final String id;
  final String missingCategory;
  final String rationale;
  final double estimatedIheGain; // Ex: 0.14 para +14% Δ IHE
  final List<AffiliatedProduct> suggestedProducts;

  const WardrobeGap({
    required this.id,
    required this.missingCategory,
    required this.rationale,
    required this.estimatedIheGain,
    required this.suggestedProducts,
  });

  int get gainPercentage => (estimatedIheGain * 100).round();
  String get formattedGain => '+$gainPercentage% IHE';

  /// Regra de Negócio RN03: Retorna estritamente produtos que possuem estoque ativo (inStock == true)
  List<AffiliatedProduct> get availableProducts =>
      suggestedProducts.where((p) => p.inStock).toList();

  /// Quantidade de produtos esgotados ocultados por RN03
  int get outOfStockCount =>
      suggestedProducts.where((p) => !p.inStock).length;
}
