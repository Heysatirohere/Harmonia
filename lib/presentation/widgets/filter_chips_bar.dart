import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// Barra Horizontal de Sub-Abas sobre a Sala (inspirada no app mobile do X)
///
/// Substitui pílulas pesadas por uma faixa contínua com linha capilar inferior
/// (`hairlineIvory`) e indicador deslizante em folha de ouro (`gildedLeaf`).
class FilterChipsBar extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  const FilterChipsBar({
    super.key,
    this.categories = const [
      'Todos',
      'Partes de cima',
      'Partes de baixo',
      'Calçados',
      'Peças únicas',
    ],
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.hairlineIvory, width: 0.6),
        ),
      ),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (context, index) => const SizedBox(width: 24),
          itemBuilder: (context, index) {
            final isSelected = index == selectedIndex;
            final categoryName = categories[index];

            return _FilterChipItem(
              label: categoryName,
              isSelected: isSelected,
              onTap: () {
                if (index != selectedIndex) {
                  HapticFeedback.selectionClick();
                  onCategorySelected(index);
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.fast,
                curve: AppMotion.editorialDecel,
                style: AppTypography.uiHeadline(
                  color: isSelected ? AppColors.ivoryText : AppColors.ivoryMuted,
                ).copyWith(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(label),
              ),
            ),
          ),
          AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.editorialDecel,
            height: 2.5,
            width: isSelected ? 28 : 0,
            decoration: BoxDecoration(
              color: AppColors.gildedLeaf,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
