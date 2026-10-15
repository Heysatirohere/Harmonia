import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

/// Chip de escolha em tinta sobre o papel
class InkChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const InkChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.editorialDecel,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.inkText : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(color: selected ? AppColors.inkText : AppColors.inkSecondary, width: 1.0),
          ),
          child: Text(
            label,
            style: AppTypography.uiHeadline(color: selected ? AppColors.paperBone : AppColors.inkText).copyWith(fontSize: 13),
          ),
        ),
      ),
    );
  }
}
