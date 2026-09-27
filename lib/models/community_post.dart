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

  bool get isStronglyRecommended => overallScore >= 75;
}

/// Entidade de dados do Post no Feed Comunitário ("Editorial Gallery" - RF14 / RF15 / RN05)
class CommunityPost {
  final String id;
  final PostAuthor author;
  final String title;
  final String editorialDescription;
  final String imageUrl;
  final IheBreakdown ihe;
  final List<GarmentHotspot> garments;
  final String bodyType;        // Ex: 'Ampulheta', 'Retângulo', 'Triângulo Invertido'
  final String colorPalette;    // Ex: 'Outono Quente', 'Outono Suave', 'Inverno Frio'
  final String occasionTag;     // Ex: 'Trabalho & Ateliê', 'Gala & Eventos', 'Lazer Casual'
  final int appreciationCount;
  final int savesCount;
  final bool isApplauded;
  final bool isSaved;
  final bool isPublic;          // Regra de Negócio RN05: Privacidade Pública / Privada
  final String publishedAtAgo;

  const CommunityPost({
    required this.id,
    required this.author,
    required this.title,
    required this.editorialDescription,
    required this.imageUrl,
    required this.ihe,
    required this.garments,
    this.bodyType = 'Ampulheta',
    this.colorPalette = 'Outono Suave',
    this.occasionTag = 'Trabalho & Ateliê',
    required this.appreciationCount,
    required this.savesCount,
    this.isApplauded = false,
    this.isSaved = false,
    this.isPublic = true,
    required this.publishedAtAgo,
  });

  CommunityPost copyWith({
    bool? isApplauded,
    int? appreciationCount,
    bool? isSaved,
    int? savesCount,
    bool? isPublic,
    String? bodyType,
    String? colorPalette,
    String? occasionTag,
    String? editorialDescription,
  }) {
    return CommunityPost(
      id: id,
      author: author,
      title: title,
      editorialDescription: editorialDescription ?? this.editorialDescription,
      imageUrl: imageUrl,
      ihe: ihe,
      garments: garments,
      bodyType: bodyType ?? this.bodyType,
      colorPalette: colorPalette ?? this.colorPalette,
      occasionTag: occasionTag ?? this.occasionTag,
      appreciationCount: appreciationCount ?? this.appreciationCount,
      savesCount: savesCount ?? this.savesCount,
      isApplauded: isApplauded ?? this.isApplauded,
      isSaved: isSaved ?? this.isSaved,
      isPublic: isPublic ?? this.isPublic,
      publishedAtAgo: publishedAtAgo,
    );
  }
}
