import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// Centróide Cromático Extraído pela Análise Morfocromática (CIE L*a*b*)
class ExtractedColorCentroid {
  final Color color;
  final String hexCode;
  final String nuanceName;
  final String labCoordinates;
  final int percentage;

  const ExtractedColorCentroid({
    required this.color,
    required this.hexCode,
    required this.nuanceName,
    required this.labCoordinates,
    required this.percentage,
  });
}

/// Exibição Visual dos Centróides Cromáticos Extraídos no Espaço CIE L*a*b*
/// Conforme AGENTS.md:
/// - Swatches circulares minimalistas com bordas capilares (borderSubtle)
/// - Exibição de Nuance, Código Hexadecimal e Coordenadas L*a*b*
/// - Seleção háptica do tom dominante primário
class ColorExtractorChips extends StatelessWidget {
  final List<ExtractedColorCentroid> centroids;
  final int selectedIndex;
  final ValueChanged<int> onSelectCentroid;

  const ColorExtractorChips({
    super.key,
    required this.centroids,
    required this.selectedIndex,
    required this.onSelectCentroid,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CENTROIDES CROMÁTICOS (CIE L*a*b*)',
              style: AppTypography.metadataBadge(
                color: AppColors.textSecondary,
              ).copyWith(fontSize: 9.5, letterSpacing: 1.0),
            ),
            if (centroids.isNotEmpty)
              Text(
                centroids[selectedIndex.clamp(0, centroids.length - 1)].labCoordinates,
                style: AppTypography.metadataBadge(
                  color: AppColors.iheGold,
                ).copyWith(fontSize: 9.0, fontWeight: FontWeight.w700),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: centroids.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final centroid = centroids[index];
              final isSelected = index == selectedIndex;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelectCentroid(index);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.editorialDecel,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.surfaceRaised : AppColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.accentTerracotta : AppColors.borderSubtle,
                      width: isSelected ? 1.2 : 0.6,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.accentTerracotta.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Swatch Circular com Borda Capilar
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: centroid.color,
                          border: Border.all(
                            color: AppColors.borderSubtle,
                            width: 0.8,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceCanvas,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            centroid.nuanceName,
                            style: AppTypography.uiHeadline().copyWith(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                centroid.hexCode,
                                style: AppTypography.metadataBadge(
                                  color: AppColors.textSecondary,
                                ).copyWith(fontSize: 8.5),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${centroid.percentage}%',
                                style: AppTypography.metadataBadge(
                                  color: AppColors.accentTerracotta,
                                ).copyWith(fontSize: 8.5, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
