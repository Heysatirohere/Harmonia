import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

/// Destino de navegação representado apenas por ícone linear
class EditorialNavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const EditorialNavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Barra de navegação minimalista do HarmonIA
///
/// Ícones lineares sem rótulo, ponto terracota sob o destino ativo e
/// uma ação central de captura (peça / provador) em carvão editorial.
class EditorialNavBar extends StatelessWidget {
  final List<EditorialNavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onCapture;

  const EditorialNavBar({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
    required this.onCapture,
  }) : assert(destinations.length % 2 == 0, 'A ação central exige número par de destinos.');

  @override
  Widget build(BuildContext context) {
    final half = destinations.length ~/ 2;

    Widget item(int index) => Expanded(
          child: _NavItem(
            destination: destinations[index],
            selected: index == currentIndex,
            onTap: () => onSelected(index),
          ),
        );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCanvas,
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 0.6)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < half; i++) item(i),
              Expanded(child: _CaptureAction(onTap: onCapture)),
              for (var i = half; i < destinations.length; i++) item(i),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final EditorialNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.destination, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: destination.label,
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: Tooltip(
        message: destination.label,
        waitDuration: const Duration(milliseconds: 600),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: AppMotion.fast,
                switchInCurve: AppMotion.editorialDecel,
                child: Icon(
                  selected ? destination.activeIcon : destination.icon,
                  key: ValueKey(selected),
                  size: 22,
                  color: selected ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: AppMotion.medium,
                curve: AppMotion.editorialDecel,
                width: selected ? 4 : 0,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.accentTerracotta,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptureAction extends StatelessWidget {
  final VoidCallback onTap;

  const _CaptureAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Capturar peça ou abrir provador',
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: const Icon(Icons.add, size: 22, color: AppColors.surfaceCanvas),
          ),
        ),
      ),
    );
  }
}
