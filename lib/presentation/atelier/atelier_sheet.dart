import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'atelier_room.dart';

export 'atelier_widgets.dart' show AtelierSheet;

/// Chancela de Alta Compatibilidade em folha de ouro (AGENTS.md 3 e 7.2).
/// Mantém o símbolo '✦ ' e o rótulo separados em Row para busca textual limpa em testes.
class GoldSeal extends StatelessWidget {
  final String label;
  final AtelierRoom? room;
  final bool onPaper;

  const GoldSeal({
    super.key,
    this.label = 'LOOK FORTEMENTE RECOMENDADO',
    this.room,
    this.onPaper = false,
  });

  @override
  Widget build(BuildContext context) {
    final allowSmallGold = room == null || room!.allowsSmallGoldText;
    final textColor = onPaper
        ? AppColors.gildedInk
        : (allowSmallGold ? AppColors.gildedLeaf : AppColors.ivoryText);
    final borderColor = onPaper
        ? AppColors.gildedInk.withValues(alpha: 0.35)
        : AppColors.gildedLeaf.withValues(alpha: 0.55);
    final fillColor = onPaper
        ? AppColors.gildedInk.withValues(alpha: 0.08)
        : AppColors.gildedLeaf.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '✦ ',
            style: AppTypography.atelierMeta(
              color: onPaper ? AppColors.gildedInk : AppColors.gildedLeaf,
            ),
          ),
          Flexible(
            child: Text(
              label.toUpperCase(),
              style: AppTypography.atelierMeta(color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Abre uma folha modal em papel cor de osso (`paperBone`) com cantos `radiusLarge` (AGENTS.md 7.5).
Future<T?> showPaperModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.paperBone,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLarge)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairlineInk,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(child: builder(ctx)),
          ],
        ),
      ),
    ),
  );
}
