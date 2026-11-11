import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import 'atelier_room.dart';

export 'atelier_sheet.dart' show GoldSeal, showPaperModalSheet;

/// Folha de leitura em papel cor de osso sobre a Sala (AGENTS.md 7.5).
/// Dentro dela valem as cores de tinta (inkText, inkSecondary, gildedInk, verdigrisInk).
class AtelierSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;

  const AtelierSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = AppColors.paperBone,
    this.radius = AppSpacing.radiusLarge,
  });

  @override
  Widget build(BuildContext context) {
    // Material (e não Container colorido) para que ListTile e InkWell mostrem o toque sobre o papel
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppColors.paperShadow,
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Escopo do shell principal de navegação (inspirado no app mobile do X):
/// permite que qualquer cabeçalho de aba abra a gaveta lateral do Ateliê em 1 toque.
class AtelierShellScope extends InheritedWidget {
  final VoidCallback openDrawer;
  final String monogram;

  const AtelierShellScope({
    super.key,
    required this.openDrawer,
    this.monogram = 'H',
    required super.child,
  });

  static AtelierShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AtelierShellScope>();

  @override
  bool updateShouldNotify(AtelierShellScope oldWidget) =>
      oldWidget.monogram != monogram || oldWidget.openDrawer != openDrawer;
}

/// Cabeçalho unificado de tela sobre a Sala (arquitetura inspirada no app mobile do X):
///
/// Linha superior de navegação (avatar/gaveta à esquerda ou botão voltar, sobrelinha
/// editorial alinhada e ações contextuais discretas à direita) + título Bodoni abaixo.
class RoomHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final AtelierRoom room;
  final VoidCallback? onBack;

  const RoomHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.room,
    this.subtitle,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final shell = AtelierShellScope.maybeOf(context);
    final Widget? leading = onBack != null
        ? RoomIconButton(icon: Icons.arrow_back_ios_new_rounded, label: 'Voltar', onTap: onBack!)
        : (shell != null
            ? _AtelierDrawerAvatarButton(
                monogram: shell.monogram,
                onTap: shell.openDrawer,
              )
            : null);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageMargin,
        MediaQuery.paddingOf(context).top + 12,
        AppSpacing.pageMargin,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra superior contínua (estilo X mobile: Avatar/Voltar · Eyebrow · Ação contextual)
          SizedBox(
            height: 40,
            child: Row(
              children: [
                if (leading != null) ...[
                  leading,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    eyebrow.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.atelierMeta(
                      color: room.allowsSmallGoldText ? AppColors.gildedLeaf : AppColors.ivoryText,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 10),
                  trailing!,
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: AppTypography.heroDisplay().copyWith(fontSize: 34)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppTypography.subtitleCuratorial(color: AppColors.ivoryMuted)),
          ],
        ],
      ),
    );
  }
}

/// Avatar/monograma no canto superior esquerdo (estilo X mobile) que abre a gaveta do Ateliê.
class _AtelierDrawerAvatarButton extends StatelessWidget {
  final String monogram;
  final VoidCallback onTap;

  const _AtelierDrawerAvatarButton({
    required this.monogram,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Abrir menu do Ateliê',
      button: true,
      excludeSemantics: true,
      child: Tooltip(
        message: 'Ateliê',
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tapestryNoir.withValues(alpha: 0.45),
                  border: Border.all(color: AppColors.gildedLeaf, width: 1.1),
                ),
                child: Text(
                  monogram,
                  style: AppTypography.displayEditorial(color: AppColors.ivoryText).copyWith(
                    fontSize: 15,
                    height: 1.0,
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.tapestryNoir,
                    border: Border.all(color: AppColors.hairlineIvory, width: 0.8),
                  ),
                  child: const Icon(Icons.menu_rounded, size: 9, color: AppColors.gildedLeaf),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão circular de ícone sobre a Sala (contorno capilar marfim)
class RoomIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const RoomIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: filled ? 52 : 40,
          height: filled ? 52 : 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.accentCinnabar : const Color(0x00000000),
            border: Border.all(
              color: filled ? AppColors.ivoryText.withValues(alpha: 0.6) : AppColors.hairlineIvory,
              width: 1.0,
            ),
          ),
          child: Icon(icon, color: AppColors.ivoryText, size: filled ? 21 : 17),
        ),
      ),
    );
  }
}

/// Título de seção sobre a Sala, em itálico de revista, com metadado opcional à direita
class RoomSectionTitle extends StatelessWidget {
  final String title;
  final String? meta;
  final EdgeInsetsGeometry padding;

  const RoomSectionTitle({
    super.key,
    required this.title,
    this.meta,
    this.padding = const EdgeInsets.fromLTRB(AppSpacing.pageMargin, AppSpacing.sectionGap, AppSpacing.pageMargin, 16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(title, style: AppTypography.sectionDisplay())),
          if (meta != null) Text(meta!.toUpperCase(), style: AppTypography.atelierMeta()),
        ],
      ),
    );
  }
}

/// Botão primário em cinábrio (rótulo marfim, 5,1:1) ou variante marfim (AGENTS.md seção 3).
/// Recebe contorno capilar `ivoryText` de 1.0px para garantir contraste >= 3:1 sobre Salas escuras.
class CinnabarButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool ivoryVariant;

  const CinnabarButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.busy = false,
    this.ivoryVariant = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final bgColor = ivoryVariant ? AppColors.ivoryText : AppColors.accentCinnabar;
    final fgColor = ivoryVariant ? AppColors.inkText : AppColors.ivoryText;
    final disabledFgColor = ivoryVariant ? AppColors.inkSecondary : AppColors.ivoryMuted;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled
            ? () {
                HapticFeedback.mediumImpact();
                onPressed!();
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          // Desabilitado sobre a Sala: véu marfim, rótulo em marfim atenuado
          disabledBackgroundColor: busy ? bgColor : const Color(0x1FF4EEE1),
          foregroundColor: fgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            side: BorderSide(
              color: enabled
                  ? (ivoryVariant ? AppColors.hairlineInk : AppColors.ivoryText)
                  : AppColors.hairlineIvory,
              width: 1.0,
            ),
          ),
        ),
        child: AnimatedSwitcher(
          duration: AppMotion.fast,
          child: busy
              ? _BusyDots(key: const ValueKey('busy'), color: fgColor)
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 19, color: enabled ? fgColor : disabledFgColor),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: AppTypography.uiHeadline(
                        color: enabled ? fgColor : disabledFgColor,
                      ).copyWith(fontSize: 14.5),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Espera sem spinner: três pontos com opacidade modulada (AGENTS.md seção 2)
class _BusyDots extends StatefulWidget {
  final Color color;

  const _BusyDots({super.key, this.color = AppColors.ivoryText});

  @override
  State<_BusyDots> createState() => _BusyDotsState();
}

class _BusyDotsState extends State<_BusyDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(
                  alpha: 0.35 + 0.65 * (1 - ((_controller.value * 3 - i) % 3).clamp(0.0, 1.0)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shimmer Tingido (AGENTS.md 6.2):
/// Varredura linear lenta (1350ms, entre 1200ms e 1500ms) entre a cor da Sala atual
/// e a mesma cor clareada ~12%. Sobre `paperBone`, entre `paperBone` e `paperBoneRaised`.
class AtelierShimmer extends StatefulWidget {
  final AtelierRoom? room;
  final bool onPaper;
  final double? width;
  final double? height;
  final double borderRadius;
  final Widget? child;

  const AtelierShimmer({
    super.key,
    this.room,
    this.onPaper = false,
    this.width,
    this.height,
    this.borderRadius = AppSpacing.radiusMedium,
    this.child,
  });

  @override
  State<AtelierShimmer> createState() => _AtelierShimmerState();
}

class _AtelierShimmerState extends State<AtelierShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1350),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.onPaper
        ? AppColors.paperBone
        : (widget.room ?? AtelierRoom.silkEmerald).baseColor.withValues(alpha: 0.55);
    final highlightColor = widget.onPaper
        ? AppColors.paperBoneRaised
        : Color.lerp((widget.room ?? AtelierRoom.silkEmerald).baseColor, AppColors.ivoryText, 0.12)!
            .withValues(alpha: 0.85);

    if (MediaQuery.disableAnimationsOf(context)) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final slide = -1.0 + 2.0 * _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(slide - 1.0, -0.2),
              end: Alignment(slide + 1.0, 0.2),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.15, 0.5, 0.85],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
