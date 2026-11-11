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

/// Barra inferior minimalista do HarmonIA (inspirada no app mobile do X)
///
/// Exibe apenas os fluxos primários em ícones lineares marfim sobre tapeçaria
/// noir, sem botões de ação embutidos que poluam a faixa inferior.
class EditorialNavBar extends StatelessWidget {
  final List<EditorialNavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onCapture;

  const EditorialNavBar({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
    this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.tapestryNoir,
        border: Border(top: BorderSide(color: AppColors.hairlineIvory, width: 0.6)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavItem(
                    destination: destinations[i],
                    selected: i == currentIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
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
                  size: 23,
                  color: selected ? AppColors.ivoryText : AppColors.ivoryMuted,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: AppMotion.medium,
                curve: AppMotion.editorialDecel,
                width: selected ? 4 : 0,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.gildedLeaf,
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

/// Botão flutuante de criação/captura no canto inferior direito (estilo X mobile)
///
/// Concentra as ações de câmera (Digitalizar peça, Modo Provador, Publicar look)
/// fora da barra inferior e dos cabeçalhos, mantendo alcance em até 2 toques (RNF06).
class AtelierCaptureFab extends StatelessWidget {
  final VoidCallback onTap;

  const AtelierCaptureFab({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Capturar peça ou abrir provador',
      button: true,
      excludeSemantics: true,
      child: Tooltip(
        message: 'Capturar',
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.accentCinnabar,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ivoryText.withValues(alpha: 0.85), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, size: 26, color: AppColors.ivoryText),
          ),
        ),
      ),
    );
  }
}
