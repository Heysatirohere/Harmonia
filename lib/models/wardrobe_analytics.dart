import 'package:flutter/material.dart';

import '../core/color/lab_color.dart';
import 'clothing_item.dart';

/// Família cromática do acervo com a cor média das peças dela (CIE L*a*b*)
class DominantColorShare {
  final String colorName;
  final Color color;
  final double percentage; // 0.0 a 100.0
  final int count;
  final String labCoordinates;

  const DominantColorShare({
    required this.colorName,
    required this.color,
    required this.percentage,
    required this.count,
    required this.labCoordinates,
  });

  factory DominantColorShare.fromJson(Map<String, dynamic> json) {
    final l = (json['L'] as num).toDouble();
    final a = (json['a'] as num).toDouble();
    final b = (json['b'] as num).toDouble();
    return DominantColorShare(
      colorName: json['family'] as String,
      color: labToColor(l, a, b),
      percentage: (json['percentage'] as num).toDouble(),
      count: json['count'] as int,
      labCoordinates: formatLab(l, a, b),
    );
  }
}

/// Peça sem uso há 90 dias ou mais, com o uso registrado pelas aprovações de looks
class DormantGarment {
  final ClothingItem item;
  final int daysIdle;
  final int wearCount;

  const DormantGarment({required this.item, required this.daysIdle, required this.wearCount});

  factory DormantGarment.fromJson(Map<String, dynamic> json) {
    return DormantGarment(
      item: ClothingItem.fromJson(json['item'] as Map<String, dynamic>),
      daysIdle: json['days_idle'] as int,
      wearCount: json['wear_count'] as int,
    );
  }

  /// Ex.: "Nunca usada · 120 dias no acervo" ou "Último uso há 95 dias"
  String get idleLabel =>
      wearCount == 0 ? 'Nunca usada · $daysIdle dias no acervo' : 'Último uso há $daysIdle dias';
}

/// Saúde do acervo calculada pela API (Seção 3.2.2): rotação em janelas de 30, 60 e 90 dias
/// a partir dos looks aprovados, e proporção cromática a partir das cores L*a*b* das peças.
class WardrobeAnalytics {
  final int totalPieces;
  final int activePiecesCount; // Usadas (ou cadastradas) há menos de 30 dias
  final int idle30DaysCount; // Sem uso de 30 a 60 dias
  final int idle60DaysCount; // Sem uso de 60 a 90 dias
  final int idle90DaysCount; // Sem uso há 90 dias ou mais (dormindo no armário)
  final int neverWornCount;
  final int totalWears;
  final List<DominantColorShare> colorDistribution;
  final List<DormantGarment> dormantItems;

  const WardrobeAnalytics({
    required this.totalPieces,
    required this.activePiecesCount,
    required this.idle30DaysCount,
    required this.idle60DaysCount,
    required this.idle90DaysCount,
    required this.neverWornCount,
    required this.totalWears,
    required this.colorDistribution,
    required this.dormantItems,
  });

  factory WardrobeAnalytics.fromJson(Map<String, dynamic> json) {
    return WardrobeAnalytics(
      totalPieces: json['total_pieces'] as int,
      activePiecesCount: json['active_count'] as int,
      idle30DaysCount: json['idle_30_count'] as int,
      idle60DaysCount: json['idle_60_count'] as int,
      idle90DaysCount: json['dormant_count'] as int,
      neverWornCount: json['never_worn_count'] as int,
      totalWears: json['total_wears'] as int,
      colorDistribution: (json['color_distribution'] as List<dynamic>)
          .map((c) => DominantColorShare.fromJson(c as Map<String, dynamic>))
          .toList(),
      dormantItems: (json['dormant_items'] as List<dynamic>)
          .map((d) => DormantGarment.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Taxa percentual de peças ativas
  double get activePercentage =>
      totalPieces > 0 ? (activePiecesCount / totalPieces) * 100.0 : 0.0;
}
