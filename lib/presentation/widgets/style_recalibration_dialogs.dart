import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user_style_profile.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_widgets.dart';
import 'color_palette_preview.dart';

/// Folhas de recalibração do perfil morfocromático (RF18)
class StyleRecalibrationDialogs {
  static void showColorimetryRecalibration(
    BuildContext context, {
    SeasonalPaletteType? current,
    required ValueChanged<SeasonalPaletteType> onSelected,
  }) {
    HapticFeedback.lightImpact();
    var selected = current ?? SeasonalPaletteType.outonoQuente;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _ReadingSheet(
          title: 'Recalibrar Colorimetria',
          subtitle: 'Escolha a cartela sazonal que melhor harmoniza com sua pele, olhos e cabelos.',
          children: [
            ColorPalettePreview(
              paletteType: selected,
              showCameraHud: false,
              onPaletteSelected: (palette) => setSheetState(() => selected = palette),
            ),
            const SizedBox(height: 20),
            CinnabarButton(
              label: 'Salvar cartela',
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.of(ctx).pop();
                onSelected(selected);
              },
            ),
          ],
        ),
      ),
    );
  }

  static void showBodyTypeAdjustment(
    BuildContext context, {
    BodySilhouetteType? current,
    required ValueChanged<BodySilhouetteType> onSelected,
  }) {
    HapticFeedback.lightImpact();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReadingSheet(
        title: 'Ajustar Biótipo Corporal',
        subtitle: 'Selecione a silhueta que melhor representa suas proporções atuais.',
        children: [
          for (final silhouette in BodySilhouetteType.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.accessibility_new, color: AppColors.gildedInk),
              title: Text(silhouette.displayName, style: AppTypography.uiHeadline(color: AppColors.inkText)),
              trailing: silhouette == current
                  ? const Icon(Icons.check, color: AppColors.inkText, size: 18)
                  : null,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(ctx).pop();
                if (silhouette != current) onSelected(silhouette);
              },
            ),
        ],
      ),
    );
  }
}

/// Folha de leitura em papel cor de osso que sobe sobre a Sala
class _ReadingSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _ReadingSheet({required this.title, required this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      // Material (e não Container) para as ListTiles pintarem o toque sobre o papel
      child: Material(
        color: AppColors.paperBone,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLarge)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin, 12, AppSpacing.pageMargin, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.hairlineInk,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(title, style: AppTypography.sectionDisplay(color: AppColors.inkText).copyWith(fontSize: 24)),
                const SizedBox(height: 6),
                Text(subtitle, style: AppTypography.bodySmall()),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
