import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'clothing_item.dart';

/// Distribuição Cromática Dominante do Guarda-Roupa (CIE L*a*b*)
class DominantColorShare {
  final String colorName;
  final Color color;
  final double percentage; // 0.0 a 100.0
  final String labCoordinates;

  const DominantColorShare({
    required this.colorName,
    required this.color,
    required this.percentage,
    required this.labCoordinates,
  });
}

/// Modelo de Inteligência Patrimonial e Rotação de Acervo (Seção 3.2.2 do HarmonIA)
class WardrobeAnalytics {
  final int totalPieces;
  final int activePiecesCount; // Usadas nos últimos 30 dias
  final int idle30DaysCount; // Ociosas de 30 a 60 dias
  final int idle60DaysCount; // Ociosas de 60 a 90 dias
  final int idle90DaysCount; // Sem uso há mais de 90 dias (dormindo no armário)
  final double averageCostPerWear; // Custo médio por uso em R$
  final double estimatedIdleCapital; // Capital estimado ocioso em R$
  final double esgConsciousPercentage; // Porcentagem de peças sustentáveis/circulares
  final List<DominantColorShare> colorDistribution;
  final List<ClothingItem> dormantItems; // Peças recomendadas para reativação

  const WardrobeAnalytics({
    required this.totalPieces,
    required this.activePiecesCount,
    required this.idle30DaysCount,
    required this.idle60DaysCount,
    required this.idle90DaysCount,
    required this.averageCostPerWear,
    required this.estimatedIdleCapital,
    required this.esgConsciousPercentage,
    required this.colorDistribution,
    required this.dormantItems,
  });

  /// Taxa percentual de peças ativas
  double get activePercentage =>
      totalPieces > 0 ? (activePiecesCount / totalPieces) * 100.0 : 0.0;

  /// Taxa percentual de peças em risco de ociosidade (>30 dias)
  double get idlePercentage =>
      totalPieces > 0 ? ((totalPieces - activePiecesCount) / totalPieces) * 100.0 : 0.0;

  /// Gera métricas analíticas calculadas a partir de uma lista de peças
  factory WardrobeAnalytics.fromItems(List<ClothingItem> items) {
    if (items.isEmpty) {
      return const WardrobeAnalytics(
        totalPieces: 0,
        activePiecesCount: 0,
        idle30DaysCount: 0,
        idle60DaysCount: 0,
        idle90DaysCount: 0,
        averageCostPerWear: 0.0,
        estimatedIdleCapital: 0.0,
        esgConsciousPercentage: 0.0,
        colorDistribution: [],
        dormantItems: [],
      );
    }

    final total = items.length;
    final esgCount = items.where((i) => i.isConsciousFashion).length;

    final sortedByUsage = List<ClothingItem>.from(items)
      ..sort((a, b) => a.usageRate.compareTo(b.usageRate));

    final active = items.where((i) => i.usageRate >= 20).length;
    final idle30 = items.where((i) => i.usageRate >= 12 && i.usageRate < 20).length;
    final idle60 = items.where((i) => i.usageRate >= 5 && i.usageRate < 12).length;
    final idle90 = items.where((i) => i.usageRate < 5).length;

    // Peças menos utilizadas sugeridas para reativação patrimonial
    final dormant = sortedByUsage.where((i) => i.usageRate <= 15).take(4).toList();
    final effectiveDormant = dormant.isNotEmpty ? dormant : sortedByUsage.take(3).toList();

    // Estimativa de custo por uso e capital ocioso
    const avgPieceValue = 189.0;
    final idlePiecesCount = idle60 + idle90;
    final estimatedCapital = idlePiecesCount * avgPieceValue;
    final totalUses = items.fold<int>(0, (sum, i) => sum + (i.usageRate > 0 ? i.usageRate : 1));
    final costPerWear = (total * avgPieceValue) / (totalUses > 0 ? totalUses : 1);

    // Distribuição de cores do acervo
    final colors = [
      const DominantColorShare(
        colorName: 'Terracota Ateliê',
        color: AppColors.accentTerracotta,
        percentage: 34.0,
        labCoordinates: 'L* 58.4, a* 28.2, b* 24.1',
      ),
      const DominantColorShare(
        colorName: 'Areia Suave & Linho',
        color: AppColors.accentSand,
        percentage: 26.0,
        labCoordinates: 'L* 82.1, a* 4.3, b* 11.8',
      ),
      const DominantColorShare(
        colorName: 'Verde Oliva Botânico',
        color: AppColors.accentOlive,
        percentage: 22.0,
        labCoordinates: 'L* 44.2, a* -6.1, b* 18.5',
      ),
      const DominantColorShare(
        colorName: 'Carvão Editorial',
        color: AppColors.textPrimary,
        percentage: 18.0,
        labCoordinates: 'L* 21.0, a* 0.5, b* 1.2',
      ),
    ];

    return WardrobeAnalytics(
      totalPieces: total,
      activePiecesCount: active,
      idle30DaysCount: idle30,
      idle60DaysCount: idle60,
      idle90DaysCount: idle90,
      averageCostPerWear: double.parse(costPerWear.toStringAsFixed(2)),
      estimatedIdleCapital: estimatedCapital,
      esgConsciousPercentage: (esgCount / total) * 100.0,
      colorDistribution: colors,
      dormantItems: effectiveDormant,
    );
  }
}
