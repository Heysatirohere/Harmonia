import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Fita minimalista com a paleta cromática identificada no look ($CIE\ L^*a^*b^*$)
class PaletteRibbon extends StatelessWidget {
  final List<Color> colors;
  final String? occasionContext;

  const PaletteRibbon({
    super.key,
    required this.colors,
    this.occasionContext,
  });

  @override
  Widget build(BuildContext context) {
    if (colors.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        // Swatches tonais minimalistas
        SizedBox(
          height: 18,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < colors.length; i++) ...[
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: colors[i],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceCanvas,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                if (i < colors.length - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ),

        if (occasionContext != null && occasionContext!.isNotEmpty) ...[
          const SizedBox(width: 10),
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              occasionContext!,
              style: AppTypography.metaLabel(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
