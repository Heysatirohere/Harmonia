import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/community_post.dart';

/// Camada de Hotspots circulares expansíveis sobre as peças do look
/// Conforme Seção 4.4 do AGENTS.md:
/// - Hotspots circulares expansíveis com resposta tátil (HapticFeedback.lightImpact()).
/// - Exibição editorial de proveniência de acervo, tecido e ESG / moda circular.
class GarmentHotspotsLayer extends StatefulWidget {
  final List<GarmentHotspot> garments;
  final bool isVisible;

  const GarmentHotspotsLayer({
    super.key,
    required this.garments,
    this.isVisible = true,
  });

  @override
  State<GarmentHotspotsLayer> createState() => _GarmentHotspotsLayerState();
}

class _GarmentHotspotsLayerState extends State<GarmentHotspotsLayer>
    with SingleTickerProviderStateMixin {
  String? _selectedGarmentId;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onSelectHotspot(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedGarmentId == id) {
        _selectedGarmentId = null;
      } else {
        _selectedGarmentId = id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible || widget.garments.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Hotspots interativos posicionados
            for (final garment in widget.garments) ...[
              _buildHotspotPin(
                garment: garment,
                left: garment.position.dx * width,
                top: garment.position.dy * height,
              ),
            ],

            // Card flutuante expansível do item selecionado
            if (_selectedGarmentId != null)
              _buildSelectedGarmentCard(
                garment: widget.garments.firstWhere(
                  (g) => g.id == _selectedGarmentId,
                  orElse: () => widget.garments.first,
                ),
                containerWidth: width,
                containerHeight: height,
              ),
          ],
        );
      },
    );
  }

  Widget _buildHotspotPin({
    required GarmentHotspot garment,
    required double left,
    required double top,
  }) {
    final isSelected = _selectedGarmentId == garment.id;

    return Positioned(
      left: left - 18,
      top: top - 18,
      child: GestureDetector(
        onTap: () => _onSelectHotspot(garment.id),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Anel de pulso editorial
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.35);
                  final opacity = (0.55 - (_pulseController.value * 0.35)).clamp(0.0, 1.0);
                  return Transform.scale(
                    scale: isSelected ? 1.4 : scale,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: garment.isConsciousFashion
                              ? AppColors.accentOlive.withValues(alpha: opacity)
                              : AppColors.iheGold.withValues(alpha: opacity),
                          width: 1.2,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Ponto central sólido com acabamento joalheiro
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceCanvas.withValues(alpha: 0.95),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentTerracotta
                        : garment.isConsciousFashion
                            ? AppColors.accentOlive
                            : AppColors.textPrimary,
                    width: 2.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2E000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.accentTerracotta
                          : garment.isConsciousFashion
                              ? AppColors.accentOlive
                              : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedGarmentCard({
    required GarmentHotspot garment,
    required double containerWidth,
    required double containerHeight,
  }) {
    // Calcula posição para não estourar os limites da imagem
    final pinX = garment.position.dx * containerWidth;
    final pinY = garment.position.dy * containerHeight;

    final isUpperHalf = pinY < (containerHeight * 0.5);
    final cardTop = isUpperHalf ? pinY + 24 : pinY - 96;
    final cardLeft = (pinX - 110).clamp(16.0, containerWidth - 236.0);

    return Positioned(
      left: cardLeft,
      top: cardTop,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0.85, end: 1.0),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: 220,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCanvas.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: garment.isConsciousFashion
                      ? AppColors.accentOlive.withValues(alpha: 0.4)
                      : AppColors.borderSubtle,
                  width: 0.8,
                ),
                boxShadow: AppColors.editorialShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: garment.dominantColor,
                          border: Border.all(color: AppColors.borderSubtle, width: 0.5),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          garment.category.toUpperCase(),
                          style: AppTypography.metaLabel().copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedGarmentId = null);
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    garment.name,
                    style: AppTypography.editorialTitleSmall().copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    garment.brandOrProvenance,
                    style: AppTypography.bodySmall(color: AppColors.textSecondary).copyWith(
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (garment.isConsciousFashion && garment.consciousNote != null) ...[
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentOlive.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.accentOlive.withValues(alpha: 0.2),
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.eco_outlined,
                            size: 11,
                            color: AppColors.accentOlive,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              garment.consciousNote!,
                              style: AppTypography.esgTag().copyWith(fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
