import 'package:flutter/material.dart';
import 'clothing_item.dart';

/// Peça fotografada em loja física (RF08)
class StoreGarment {
  final String id;
  final String title;
  final String storeName;
  final double? price;
  final String category;
  final Color dominantColor;
  final String? tag;
  final String? imageUrl;

  const StoreGarment({
    required this.id,
    required this.title,
    required this.storeName,
    this.price,
    required this.category,
    required this.dominantColor,
    this.tag,
    this.imageUrl,
  });

  String get formattedPrice =>
      price != null ? 'R\$ ${price!.toStringAsFixed(2).replaceAll('.', ',')}' : '';
}

/// Item do acervo com match individual de paridade (RF09)
class ParityMatchItem {
  final ClothingItem closetItem;
  final double parityScore; // Ex: 0.92 para 92%
  final String matchReason;
  final double chromaticScore;
  final double morphologicalScore;

  const ParityMatchItem({
    required this.closetItem,
    required this.parityScore,
    required this.matchReason,
    this.chromaticScore = 0.90,
    this.morphologicalScore = 0.88,
  });

  int get parityPercentage => (parityScore * 100).round();
  String get formattedPercentage => '$parityPercentage%';
  bool get isHighMatch => parityScore >= 0.75;
}

/// Modelo de Resultado da Análise de Paridade do Provador (RF08 & RF09)
class StoreParityResult {
  final StoreGarment storeGarment;
  final double overallParityScore; // Ex: 0.86 para 86%
  final List<ParityMatchItem> compatibleMatches;
  final String editorialSummary;

  const StoreParityResult({
    required this.storeGarment,
    required this.overallParityScore,
    required this.compatibleMatches,
    required this.editorialSummary,
  });

  int get overallPercentage => (overallParityScore * 100).round();
  String get formattedOverallScore => '$overallPercentage%';
  bool get isStronglyRecommended => overallParityScore >= 0.75;
}
