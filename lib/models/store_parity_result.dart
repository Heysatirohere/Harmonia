import 'dart:ui';
import 'clothing_item.dart';

class ParityMatchItem {
  final ClothingItem closetItem;
  final double harmonyScore;
  final String rationale;
  final List<Color> swatchColors;
  final double chromaticScore;
  final double morphologicalScore;

  const ParityMatchItem({
    required this.closetItem,
    required this.harmonyScore,
    required this.rationale,
    required this.swatchColors,
    this.chromaticScore = 0.90,
    this.morphologicalScore = 0.88,
  });

  String get formattedHarmonyScore => '${(harmonyScore * (harmonyScore <= 1.0 ? 100 : 1)).round()}%';
  String get formattedPercentage => formattedHarmonyScore;
  String get matchReason => rationale;
}

class StoreParityResult {
  final ClothingItem storeGarment;
  final double overallScore;
  final String editorialSummary;
  final List<ParityMatchItem> compatibleMatches;

  const StoreParityResult({
    required this.storeGarment,
    required this.overallScore,
    required this.editorialSummary,
    required this.compatibleMatches,
  });

  List<ParityMatchItem> get matches => compatibleMatches;
  double get globalParityScore => overallScore;
  String get formattedOverallScore => '${(overallScore * (overallScore <= 1.0 ? 100 : 1)).round()}%';
  bool get isStronglyRecommended => (overallScore >= 0.75 && overallScore <= 1.0) || overallScore >= 75;
}
