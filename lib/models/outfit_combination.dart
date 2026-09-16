import 'package:flutter/material.dart';
import 'clothing_item.dart';

/// Decomposição Matemática e Perceptual dos 4 Pilares do IHE (Índice de Harmonia Estética)
class IheSubScores {
  final int overallScore; // Pontuação global de 0 a 100 (ex: 88)
  final double sColor; // S_cor: Harmonia Cromática CIE L*a*b* (0.0 a 1.0)
  final double sBio; // S_bio: Compensação Morfológica (0.0 a 1.0)
  final double sOcasion; // S_ocasion: Contexto & Clima (0.0 a 1.0)
  final double sCos; // S_cos: Ressonância Vetorial com o acervo (0.0 a 1.0)
  final String occasionContext; // Ex: "Casual Chic • 24°C Ensolarado"
  final Color dominantColor;
  final List<Color> paletteColors;

  const IheSubScores({
    required this.overallScore,
    required this.sColor,
    required this.sBio,
    required this.sOcasion,
    required this.sCos,
    required this.occasionContext,
    required this.dominantColor,
    required this.paletteColors,
  });

  /// Conforme AGENTS.md: IHE >= 75% recebe o selo de recomendação forte
  bool get isStronglyRecommended => overallScore >= 75;
}

/// Entidade do Look Harmonizado Completo ("Outfit Composition")
class OutfitCombination {
  final String id;
  final String title;
  final String editorialNote;
  final ClothingItem topItem;
  final ClothingItem bottomItem;
  final ClothingItem footwearItem;
  final ClothingItem? accessoryItem;
  final IheSubScores ihe;
  final String occasion;
  final bool isApproved;
  final bool isSaved;
  final bool isDiscarded;

  const OutfitCombination({
    required this.id,
    required this.title,
    required this.editorialNote,
    required this.topItem,
    required this.bottomItem,
    required this.footwearItem,
    this.accessoryItem,
    required this.ihe,
    required this.occasion,
    this.isApproved = false,
    this.isSaved = false,
    this.isDiscarded = false,
  });

  List<ClothingItem> get items => [
        topItem,
        bottomItem,
        footwearItem,
        if (accessoryItem != null) accessoryItem!,
      ];

  OutfitCombination copyWith({
    String? id,
    String? title,
    String? editorialNote,
    ClothingItem? topItem,
    ClothingItem? bottomItem,
    ClothingItem? footwearItem,
    ClothingItem? accessoryItem,
    IheSubScores? ihe,
    String? occasion,
    bool? isApproved,
    bool? isSaved,
    bool? isDiscarded,
  }) {
    return OutfitCombination(
      id: id ?? this.id,
      title: title ?? this.title,
      editorialNote: editorialNote ?? this.editorialNote,
      topItem: topItem ?? this.topItem,
      bottomItem: bottomItem ?? this.bottomItem,
      footwearItem: footwearItem ?? this.footwearItem,
      accessoryItem: accessoryItem ?? this.accessoryItem,
      ihe: ihe ?? this.ihe,
      occasion: occasion ?? this.occasion,
      isApproved: isApproved ?? this.isApproved,
      isSaved: isSaved ?? this.isSaved,
      isDiscarded: isDiscarded ?? this.isDiscarded,
    );
  }
}
