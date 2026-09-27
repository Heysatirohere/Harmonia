import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/clothing_item.dart';
import '../../theme/app_theme.dart';

/// Card autoral de peça recortada flutuante ("The Floating Canvas")
/// Conforme AGENTS.md:
/// - Fundo transparente para peças recortadas (TOLERÂNCIA ZERO a BoxShadow retangular na imagem)
/// - Resampling com FilterQuality.medium e restrição memCacheWidth/Height
/// - Shimmer aquecido para estado de carregamento (zero CircularProgressIndicator cru)
/// - Selo minimalista com swatch morfocromático (CIE Lab*), taxa de uso e ESG
/// - Microinteração com HapticFeedback.selectionClick() e curva AppMotion.editorialDecel
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
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: AppMotion.editorialDecel,
      ),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _hoverController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _hoverController.reverse();
  }

  void _handleTapCancel() {
    _hoverController.reverse();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 0.8,
            ),
            boxShadow: AppColors.editorialShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Área Superior: Badge Categoria & Indicador ESG / Lab*
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge de Categoria em Caixa Alta
                    Flexible(
                      child: Text(
                        widget.item.category.toUpperCase(),
                        style: AppTypography.metadataBadge(
                          color: AppColors.textSecondary,
                        ).copyWith(fontSize: 9.5, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Swatch de cor dominante com borda hairline + Selo ESG
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.item.isConsciousFashion) ...[
                          const Icon(
                            Icons.eco_outlined,
                            size: 13,
                            color: AppColors.accentOlive,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.item.dominantColor,
                            border: Border.all(
                              color: AppColors.borderSubtle,
                              width: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Área Central: Canvas da Peça Recortada (PNG Alfa)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final targetWidth = (constraints.maxWidth * dpr).round();
                      final targetHeight = (constraints.maxHeight * dpr).round();

                      return Center(
                        child: Image.network(
                          widget.item.imageUrl,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium, // Reamostragem limpa conforme AGENTS.md
                          cacheWidth: targetWidth > 0 ? targetWidth : null,
                          cacheHeight: targetHeight > 0 ? targetHeight : null,
                          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded || frame != null) {
                              return AnimatedOpacity(
                                opacity: 1.0,
                                duration: AppMotion.fast,
                                curve: AppMotion.editorialDecel,
                                child: child,
                              );
                            }
                            return _WarmShimmerPlaceholder();
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.checkroom_outlined,
                                color: AppColors.textMuted,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Área Inferior: Metadados Curatoriais (Nome, Proveniência, Usos)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: AppTypography.uiHeadline().copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Proveniência ou Lab*
                        Expanded(
                          child: Text(
                            widget.item.brandOrProvenance,
                            style: AppTypography.bodySmall(color: AppColors.textSecondary).copyWith(
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Taxa de Uso
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCanvas,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.borderSubtle,
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            '${widget.item.usageRate}×',
                            style: AppTypography.metadataBadge(
                              color: AppColors.textPrimary,
                            ).copyWith(fontSize: 9.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer Aquecido para Estado de Carregamento Editorial
/// Conforme AGENTS.md Seção 5.2:
/// - Transição suave entre surfaceRaised e surfaceSubtle
/// - Evita CircularProgressIndicator cru
class _WarmShimmerPlaceholder extends StatefulWidget {
  @override
  State<_WarmShimmerPlaceholder> createState() => _WarmShimmerPlaceholderState();
}

class _WarmShimmerPlaceholderState extends State<_WarmShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: AppColors.surfaceRaised,
      end: AppColors.surfaceSubtle,
    ).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: AppMotion.editorialDecel,
      ),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) => Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: _colorAnimation.value,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
      ),
    );
  }
}
