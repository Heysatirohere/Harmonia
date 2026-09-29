import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

import 'dart:typed_data';

/// Visualizador da Remoção de Fundo e Segmentação Semântica (Canal Alfa)
/// Conforme AGENTS.md Seção 5.1 e RNF06:
/// - Alternância "Foto Original / Recorte" entre os bytes reais devolvidos pelo pipeline (RF04)
/// - Sem BoxShadow no PNG recortado; sombra só na bandeja
/// - Reamostragem com FilterQuality.medium e decodificação limitada via cacheWidth
/// - Shimmer aquecido enquanto o servidor processa a foto
class SegmentationPreview extends StatefulWidget {
  final Uint8List? originalBytes;
  final Uint8List? cutoutBytes;
  final bool isProcessing;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onChangePhoto;

  const SegmentationPreview({
    super.key,
    this.originalBytes,
    this.cutoutBytes,
    this.isProcessing = false,
    this.errorMessage,
    this.onRetry,
    this.onChangePhoto,
  });

  @override
  State<SegmentationPreview> createState() => _SegmentationPreviewState();
}

class _SegmentationPreviewState extends State<SegmentationPreview> {
  bool _showOriginal = false;

  @override
  void didUpdateWidget(covariant SegmentationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Novo recorte chegou: volta a exibi-lo por padrão
    if (widget.cutoutBytes != oldWidget.cutoutBytes) _showOriginal = false;
  }

  bool get _hasCutout => widget.cutoutBytes != null && !widget.isProcessing;
  bool get _showingCutout => _hasCutout && !_showOriginal;

  void _toggleView() {
    HapticFeedback.selectionClick();
    setState(() => _showOriginal = !_showOriginal);
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final hasPhoto = widget.originalBytes != null;

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
          if (_showingCutout)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                child: CustomPaint(
                  painter: _AlphaGridPainter(),
                ),
              ),
            ),

          // 2. Conteúdo: convite à captura, shimmer, foto original ou recorte PNG alfa
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (!hasPhoto) {
                    return _CapturePrompt(onTap: widget.onChangePhoto);
                  }
                  if (widget.isProcessing) {
                    return _WarmShimmerProcessingPlaceholder();
                  }

                  final bytes = _showingCutout ? widget.cutoutBytes! : widget.originalBytes!;
                  final targetWidth = (constraints.maxWidth * dpr).round();

                  return AnimatedSwitcher(
                    duration: AppMotion.medium,
                    switchInCurve: AppMotion.editorialDecel,
                    switchOutCurve: AppMotion.editorialDecel,
                    child: Center(
                      key: ValueKey<bool>(_showingCutout),
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        cacheWidth: targetWidth > 0 ? targetWidth : null,
                        gaplessPlayback: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Botão de Trocar Foto (Topo Direito)
          if (hasPhoto && widget.onChangePhoto != null && !widget.isProcessing)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: widget.onChangePhoto,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCanvas.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      width: 0.6,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_camera_outlined, size: 14, color: AppColors.textPrimary),
                      const SizedBox(width: 4),
                      Text(
                        'TROCAR FOTO',
                        style: AppTypography.metadataBadge(color: AppColors.textPrimary)
                            .copyWith(fontSize: 8.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 4. Etiqueta Visual de Estado (Topo Esquerdo)
          if (hasPhoto && !widget.isProcessing && widget.errorMessage == null)
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
                        color: _showingCutout ? AppColors.accentOlive : AppColors.accentTerracotta,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _showingCutout ? 'IA SEGMENTADA • CANAL ALFA' : 'FOTO ORIGINAL (COM FUNDO)',
                      style: AppTypography.metadataBadge(
                        color: AppColors.textPrimary,
                      ).copyWith(fontSize: 8.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Falha na análise: mensagem e nova tentativa (Base)
          if (hasPhoto && !widget.isProcessing && widget.errorMessage != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: _ErrorBanner(message: widget.errorMessage!, onRetry: widget.onRetry),
            ),

          // 6. Alternância "Foto Original / Recorte" (Base Centro)
          if (_hasCutout && widget.errorMessage == null)
            Positioned(
              bottom: 14,
              child: GestureDetector(
                onTap: _toggleView,
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
                        _showingCutout ? 'VER FOTO ORIGINAL' : 'VER RECORTE',
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

/// Estado inicial: convite à captura da peça (Toque 1 do RNF06)
class _CapturePrompt extends StatelessWidget {
  final VoidCallback? onTap;

  const _CapturePrompt({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.checkroom_outlined, color: AppColors.textMuted, size: 44),
            const SizedBox(height: 14),
            Text(
              'Fotografe a peça',
              style: AppTypography.subtitleCuratorial(),
            ),
            const SizedBox(height: 6),
            Text(
              'NO CABIDE OU SOBRE UMA SUPERFÍCIE LISA',
              style: AppTypography.metadataBadge(color: AppColors.textSecondary)
                  .copyWith(fontSize: 8.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorBanner({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.accentTerracotta.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall(color: AppColors.textPrimary).copyWith(fontSize: 11.5),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onRetry!();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.accentTerracotta),
              child: Text(
                'TENTAR DE NOVO',
                style: AppTypography.metadataBadge(color: AppColors.accentTerracotta)
                    .copyWith(fontSize: 9, fontWeight: FontWeight.w700),
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
