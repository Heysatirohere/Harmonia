import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// Barra Horizontal Minimalista de Filtros por Categoria, desenhada para ficar sobre uma Sala
/// Conforme AGENTS.md:
/// - Linhas capilares (hairlineIvory)
/// - Resposta tátil refinada (HapticFeedback.selectionClick())
/// - Animação suave entre estados ativo e inativo com AppMotion.editorialDecel
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
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.tightGap),
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
    // Sobre a Sala: ativo em marfim sólido, inativos só com contorno capilar
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.editorialDecel,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ivoryText : const Color(0x00000000),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? AppColors.ivoryText : AppColors.hairlineIvory,
            width: 0.8,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.uiHeadline(
              color: isSelected ? AppColors.inkText : AppColors.ivoryText,
            ).copyWith(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
