import '../../models/clothing_item.dart';

/// Look gerado pelo motor do IHE a partir do acervo real (RF07)
///
/// As peças vêm como o motor as combinou: parte de cima + parte de baixo (+ calçado)
/// ou peça única (+ calçado).
class RecommendedLook {
  final List<ClothingItem> items;
  final int ihePercentage;
  final double sCor;
  final double sBio;
  final double sOcasion;
  final double sCos;
  final bool isStronglyRecommended;
  final String stylingAdvice;
  final String occasion;

  const RecommendedLook({
    required this.items,
    required this.ihePercentage,
    required this.sCor,
    required this.sBio,
    required this.sOcasion,
    required this.sCos,
    required this.isStronglyRecommended,
    required this.stylingAdvice,
    required this.occasion,
  });

  factory RecommendedLook.fromJson(Map<String, dynamic> json) {
    return RecommendedLook(
      items: [
        for (final item in json['items'] as List<dynamic>) ClothingItem.fromJson(item as Map<String, dynamic>),
      ],
      ihePercentage: (json['ihe_percentage'] as num).round(),
      sCor: (json['s_cor'] as num).toDouble(),
      sBio: (json['s_bio'] as num).toDouble(),
      sOcasion: (json['s_ocasion'] as num).toDouble(),
      sCos: (json['s_cos'] as num).toDouble(),
      isStronglyRecommended: json['is_strongly_recommended'] as bool,
      stylingAdvice: json['styling_advice'] as String,
      occasion: json['occasion'] as String,
    );
  }
}
