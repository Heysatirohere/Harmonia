import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// Visualizador Interativo da Remoção de Fundo e Segmentação Semântica (Canal Alfa)
/// Conforme AGENTS.md Seção 5.1 e RNF06:
/// - Alternância visual suave estilo "Antes (Foto Bruta) / Depois (IA Segmentada)"
/// - Sem BoxShadow retangular no container da peça segmentada
/// - Reamostragem com FilterQuality.medium e restrição de memória (cacheWidth/Height)
/// - Transição com shimmer aquecido para simular o pipeline assíncrono de remoção de fundo
class SegmentationPreview extends StatefulWidget {
  final String rawImageUrl;
  final String croppedImageUrl;
  final ValueChanged<bool>? onSegmentedToggle;

  const SegmentationPreview({
    super.key,
    required this.rawImageUrl,
    required this.croppedImageUrl,
    this.onSegmentedToggle,
  });

  @override
  State<SegmentationPreview> createState() => _SegmentationPreviewState();
}

class _SegmentationPreviewState extends State<SegmentationPreview> {
  bool _isSegmented = true;
  bool _isProcessing = false;

  void _toggleSegmentation() async {
    HapticFeedback.selectionClick();

    setState(() {
      _isProcessing = true;
    });

    // Simula a inferência do pipeline de segmentação semântica (FastAPI / AWS)
    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _isSegmented = !_isSegmented;
    });

    widget.onSegmentedToggle?.call(_isSegmented);
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;

    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 0.8,
        ),
        boxShadow: AppColors.editorialShadow,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Grid Padrão de Fundo Alfa (Chequerboard sutil em estado transparente)
          if (_isSegmented && !_isProcessing)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                child: CustomPaint(
                  painter: _AlphaGridPainter(),
                ),
              ),
            ),

          // 2. Imagem (Foto Bruta ou Silhueta Segmentada PNG Alfa)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final targetWidth = (constraints.maxWidth * dpr).round();
                  final targetHeight = (constraints.maxHeight * dpr).round();

                  if (_isProcessing) {
                    return _WarmShimmerProcessingPlaceholder();
                  }

                  final imageUrl = _isSegmented ? widget.croppedImageUrl : widget.rawImageUrl;

                  return AnimatedSwitcher(
                    duration: AppMotion.medium,
                    switchInCurve: AppMotion.editorialDecel,
                    switchOutCurve: AppMotion.editorialDecel,
                    child: Center(
                      key: ValueKey<String>(imageUrl),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium, // Reamostragem limpa conforme AGENTS.md
                        cacheWidth: targetWidth > 0 ? targetWidth : null,
                        cacheHeight: targetHeight > 0 ? targetHeight : null,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.checkroom_outlined,
                              color: AppColors.textMuted,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Etiqueta Visual de Estado (Topo Esquerdo)
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceCanvas.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 0.6,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isSegmented ? AppColors.accentOlive : AppColors.accentTerracotta,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isSegmented ? 'IA SEGMENTADA • CANAL ALFA' : 'FOTO BRUTA (COM FUNDO)',
                    style: AppTypography.metadataBadge(
                      color: AppColors.textPrimary,
                    ).copyWith(fontSize: 8.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),

          // 4. Botão Flutuante de Alternância "Antes / Depois" (Base Centro)
          Positioned(
            bottom: 14,
            child: GestureDetector(
              onTap: _toggleSegmentation,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.editorialDecel,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2E1A1817),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_fix_high_rounded,
                      color: AppColors.iheGold,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isSegmented ? 'VER FOTO ORIGINAL' : 'REMOVER FUNDO COM IA',
                      style: AppTypography.metadataBadge(
                        color: AppColors.surfaceCanvas,
                      ).copyWith(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer Aquecido para o Estado Intermediário de Remoção de Fundo
class _WarmShimmerProcessingPlaceholder extends StatefulWidget {
  @override
  State<_WarmShimmerProcessingPlaceholder> createState() =>
      __WarmShimmerProcessingPlaceholderState();
}

class __WarmShimmerProcessingPlaceholderState
    extends State<_WarmShimmerProcessingPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
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
      builder: (context, child) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'REMOVENDO FUNDO E ISOLANDO CANAL ALFA...',
              style: AppTypography.metadataBadge(color: AppColors.accentTerracotta)
                  .copyWith(fontSize: 8.5, letterSpacing: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

/// Padrão Sutil de Malha Transparente (Chequerboard Alfa)
class _AlphaGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = AppColors.surfaceRaised.withValues(alpha: 0.4);
    final paint2 = Paint()..color = AppColors.surfaceSubtle.withValues(alpha: 0.3);

    const checkSize = 12.0;

    for (double x = 0; x < size.width; x += checkSize) {
      for (double y = 0; y < size.height; y += checkSize) {
        final isEven = ((x / checkSize).floor() + (y / checkSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkSize, checkSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
