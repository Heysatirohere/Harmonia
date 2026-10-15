import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/clothing_item.dart';
import '../../theme/app_theme.dart';

/// Peça flutuante sobre a Sala ("The Floating Canvas", AGENTS.md 7.1)
/// - Sem cartão atrás: a peça recortada paira direto sobre a cenografia
/// - Halo de luz desenhado a partir do próprio canal alfa (nunca BoxShadow na caixa)
/// - FilterQuality.medium e decodificação limitada ao tamanho exibido
/// - Shimmer tingido pela Sala enquanto a imagem carrega
/// - Pressão com editorialDecel e retorno com o Gesto Teatral
class ClothingCard extends StatefulWidget {
  final ClothingItem item;
  final VoidCallback? onTap;

  const ClothingCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  State<ClothingCard> createState() => _ClothingCardState();
}

class _ClothingCardState extends State<ClothingCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
    reverseDuration: AppMotion.medium,
  );
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
    CurvedAnimation(
      parent: _pressController,
      curve: AppMotion.editorialDecel,
      reverseCurve: AppMotion.theatricalGesture.flipped,
    ),
  );

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _FloatingGarment(imageUrl: item.imageUrl)),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.dominantColor,
                    border: Border.all(color: AppColors.hairlineIvory, width: 0.8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    style: AppTypography.uiHeadline(color: AppColors.ivoryText).copyWith(
                      fontSize: 13.5,
                      height: 1.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.isConsciousFashion) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.eco_outlined, size: 13, color: AppColors.verdigrisLight),
                ],
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.brandOrProvenance,
                    style: AppTypography.bodySmall(color: AppColors.ivoryMuted).copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.usageRate}× USADA',
                  style: AppTypography.atelierMeta().copyWith(fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Imagem da peça com halo de luz derivado do canal alfa
class _FloatingGarment extends StatelessWidget {
  final String imageUrl;

  const _FloatingGarment({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cacheWidth = (constraints.maxWidth * dpr).round();
        final cacheHeight = (constraints.maxHeight * dpr).round();

        // Mesmo cacheWidth/cacheHeight nas duas camadas: a imagem é decodificada uma vez só
        Widget garment({bool placeholders = true}) => Image.network(
              imageUrl,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              cacheWidth: cacheWidth > 0 ? cacheWidth : null,
              cacheHeight: cacheHeight > 0 ? cacheHeight : null,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedSwitcher(
                  duration: AppMotion.medium,
                  switchInCurve: AppMotion.editorialDecel,
                  child: frame != null
                      ? child
                      : (placeholders ? const _RoomTintedShimmer() : const SizedBox.expand()),
                );
              },
              errorBuilder: (context, error, stackTrace) => placeholders
                  ? const Center(
                      child: Icon(Icons.checkroom_outlined, color: AppColors.ivoryMuted, size: 32),
                    )
                  : const SizedBox.expand(),
            );

        return Stack(
          fit: StackFit.expand,
          children: [
            // Halo: a silhueta da peça, clareada em marfim e desfocada
            IgnorePointer(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14, tileMode: TileMode.decal),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(Color(0x38F4EEE1), BlendMode.srcIn),
                  child: garment(placeholders: false),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              child: garment(),
            ),
          ],
        );
      },
    );
  }
}

/// Shimmer translúcido: sobre a Sala, ganha a cor dela (AGENTS.md 6.2)
class _RoomTintedShimmer extends StatefulWidget {
  const _RoomTintedShimmer();

  @override
  State<_RoomTintedShimmer> createState() => _RoomTintedShimmerState();
}

class _RoomTintedShimmerState extends State<_RoomTintedShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  late final Animation<Color?> _color = ColorTween(
    begin: const Color(0x0FF4EEE1),
    end: const Color(0x24F4EEE1),
  ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.editorialDecel));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _color,
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: _color.value,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
      ),
    );
  }
}
