import 'clothing_item.dart';

/// Peça do acervo e o IHE do melhor look que ela forma com a peça da loja (RF09)
class ParityMatchItem {
  final ClothingItem closetItem;
  final int ihePercentage;
  final double chromaticScore;
  final double morphologicalScore;
  final bool isStronglyRecommended;
  final String rationale;

  const ParityMatchItem({
    required this.closetItem,
    required this.ihePercentage,
    required this.chromaticScore,
    required this.morphologicalScore,
    required this.isStronglyRecommended,
    required this.rationale,
  });

  factory ParityMatchItem.fromJson(Map<String, dynamic> json) {
    return ParityMatchItem(
      closetItem: ClothingItem.fromJson(json['item'] as Map<String, dynamic>),
      ihePercentage: (json['ihe_percentage'] as num).round(),
      chromaticScore: (json['s_cor'] as num).toDouble(),
      morphologicalScore: (json['s_bio'] as num).toDouble(),
      isStronglyRecommended: json['is_strongly_recommended'] as bool,
      rationale: json['rationale'] as String,
    );
  }

  String get formattedPercentage => '$ihePercentage%';
  String get matchReason => rationale;
}

/// Paridade de uma peça vista na loja com o acervo do usuário (RF08, RF09)
class StoreParityResult {
  final ClothingItem storeGarment;

  /// IHE do melhor look possível com a peça da loja; 0 quando o acervo não forma nenhum
  final int ihePercentage;
  final bool isStronglyRecommended;

  /// Harmonia da cor da peça com a cartela do usuário (0 a 1); nula sem cartela
  final double? paletteHarmony;
  final String? stylingAdvice;
  final int looksEvaluated;
  final int strongLooks;
  final List<ParityMatchItem> matches;

  const StoreParityResult({
    required this.storeGarment,
    required this.ihePercentage,
    required this.isStronglyRecommended,
    this.paletteHarmony,
    this.stylingAdvice,
    required this.looksEvaluated,
    required this.strongLooks,
    required this.matches,
  });

  factory StoreParityResult.fromJson(Map<String, dynamic> json, {required ClothingItem storeGarment}) {
    return StoreParityResult(
      storeGarment: storeGarment,
      ihePercentage: (json['ihe_percentage'] as num).round(),
      isStronglyRecommended: json['is_strongly_recommended'] as bool,
      paletteHarmony: (json['palette_harmony'] as num?)?.toDouble(),
      stylingAdvice: json['styling_advice'] as String?,
      looksEvaluated: json['looks_evaluated'] as int,
      strongLooks: json['strong_looks'] as int,
      matches: [
        for (final match in json['matches'] as List<dynamic>) ParityMatchItem.fromJson(match as Map<String, dynamic>),
      ],
    );
  }

  List<ParityMatchItem> get compatibleMatches => matches;
  String get formattedOverallScore => '$ihePercentage%';

  /// Resumo em texto corrido, montado só com o que o motor calculou
  String get editorialSummary {
    final palette = paletteHarmony == null
        ? ''
        : ' A cor tem ${(paletteHarmony! * 100).round()}% de harmonia com a sua cartela.';
    if (looksEvaluated == 0) {
      return 'Seu acervo ainda não tem peças que formem um look com esta.$palette';
    }
    final looks = looksEvaluated == 1 ? '1 look' : '$looksEvaluated looks';
    final strong = strongLooks == 0
        ? 'nenhum deles com IHE de 75% ou mais'
        : strongLooks == 1
            ? '1 com IHE de 75% ou mais'
            : '$strongLooks com IHE de 75% ou mais';
    return 'Forma $looks com o seu acervo, $strong.$palette';
  }
}
