import 'package:flutter/material.dart';

/// Autor da publicação de moda no Feed Comunitário
class PostAuthor {
  final String id;
  final String name;
  final String handle;
  final String avatarUrl;
  final String styleArchetype;
  final bool isVerifiedCurator;

  const PostAuthor({
    required this.id,
    required this.name,
    required this.handle,
    required this.avatarUrl,
    required this.styleArchetype,
    this.isVerifiedCurator = true,
  });
}

/// Hotspot circular interativo sobre cada peça do lookbook
class GarmentHotspot {
  final String id;
  final String name;
  final String brandOrProvenance;
  final String category;
  final Offset position; // Coordenadas normalizadas (0.0 a 1.0)
  final Color dominantColor;
  final bool isConsciousFashion;
  final String? consciousNote;

  const GarmentHotspot({
    required this.id,
    required this.name,
    required this.brandOrProvenance,
    required this.category,
    required this.position,
    required this.dominantColor,
    this.isConsciousFashion = false,
    this.consciousNote,
  });
}

/// Decomposição matemática e perceptual do IHE (Índice de Harmonia Estética)
class IheBreakdown {
  final int overallScore; // 0 - 100
  final double sColor;    // Harmonia Cromática CIE L*a*b* (0.0 - 1.0)
  final double sBio;      // Compensação Morfológica (0.0 - 1.0)
  final double sOcasion;  // Contexto & Clima (0.0 - 1.0)
  final double sCos;      // Similaridade Vetorial com estilo pessoal (0.0 - 1.0)
  final Color dominantColor;
  final List<Color> paletteColors;
  final String occasionContext;

  const IheBreakdown({
    required this.overallScore,
    required this.sColor,
    required this.sBio,
    required this.sOcasion,
    required this.sCos,
    required this.dominantColor,
    required this.paletteColors,
    required this.occasionContext,
  });

  /// Regra do AGENTS.md: IHE >= 75% recebe o selo de recomendação forte
  bool get isStronglyRecommended => overallScore >= 75;
}

/// Entidade de dados do Post no Feed Comunitário ("Editorial Frame")
class CommunityPost {
  final String id;
  final PostAuthor author;
  final String title;
  final String editorialDescription;
  final String imageUrl;
  final IheBreakdown ihe;
  final List<GarmentHotspot> garments;
  final int appreciationCount;
  final int savesCount;
  final bool isApplauded;
  final bool isSaved;
  final String publishedAtAgo;

  const CommunityPost({
    required this.id,
    required this.author,
    required this.title,
    required this.editorialDescription,
    required this.imageUrl,
    required this.ihe,
    required this.garments,
    required this.appreciationCount,
    required this.savesCount,
    this.isApplauded = false,
    this.isSaved = false,
    required this.publishedAtAgo,
  });

  CommunityPost copyWith({
    bool? isApplauded,
    int? appreciationCount,
    bool? isSaved,
    int? savesCount,
  }) {
    return CommunityPost(
      id: id,
      author: author,
      title: title,
      editorialDescription: editorialDescription,
      imageUrl: imageUrl,
      ihe: ihe,
      garments: garments,
      appreciationCount: appreciationCount ?? this.appreciationCount,
      savesCount: savesCount ?? this.savesCount,
      isApplauded: isApplauded ?? this.isApplauded,
      isSaved: isSaved ?? this.isSaved,
      publishedAtAgo: publishedAtAgo,
    );
  }
}
