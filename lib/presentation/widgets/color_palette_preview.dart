import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_style_profile.dart';
import '../../theme/app_theme.dart';

/// Visualizador da Cartela Sazonal de Colorimetria Pessoal com Visor de Câmera Minimalista
/// Conforme AGENTS.md:
/// - Visor minimalista de linhas finas douradas (iheGold)
/// - Exibição dos swatches tonais da cartela do usuário
/// - Transições de cor com curva AppMotion.editorialDecel
class ColorPalettePreview extends StatelessWidget {
  final SeasonalPaletteType paletteType;
  final ValueChanged<SeasonalPaletteType>? onPaletteSelected;
  final bool showCameraHud;

  const ColorPalettePreview({
    super.key,
    required this.paletteType,
    this.onPaletteSelected,
    this.showCameraHud = true,
  });

  @override
  Widget build(BuildContext context) {
    final swatches = paletteType.colorSwatches;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: AppColors.borderGold,
          width: 0.8,
        ),
        boxShadow: AppColors.editorialShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visor Minimalista de Câmera / Selfie com Linhas Finas Douradas
          if (showCameraHud) ...[
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceCanvas,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 0.6,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Moldura HUD de Câmera com Cantos Finos Dourados
                  CustomPaint(
                    size: Size.infinite,
                    painter: _CameraHudPainter(),
                  ),

                  // Ícone / Indicador da Análise Facial
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceRaised,
                          border: Border.all(color: AppColors.iheGold, width: 0.8),
                        ),
                        child: const Icon(
                          Icons.face_retouching_natural_outlined,
                          color: AppColors.iheGold,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ANÁLISE FACIAL & SUBTOM',
                        style: AppTypography.metadataBadge(
                          color: AppColors.iheGold,
                        ).copyWith(fontSize: 9.0, letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Cabeçalho da Cartela Sazonal Detectada
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARTELA SAZONAL EXPANDIDA',
                    style: AppTypography.metadataBadge(
                      color: AppColors.accentTerracotta,
                    ).copyWith(fontSize: 9.5, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    paletteType.displayName,
                    style: AppTypography.displayEditorial().copyWith(
                      fontSize: 22,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.iheGoldLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderGold, width: 0.6),
                ),
                child: Text(
                  paletteType.temperature,
                  style: AppTypography.metadataBadge(color: AppColors.iheGold)
                      .copyWith(fontSize: 9.0, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 14),

          // Swatches Tonais Circulares da Paleta
          Text(
            'PALETA HARMONIZADA DE REFERÊNCIA',
            style: AppTypography.metadataBadge(color: AppColors.textSecondary)
                .copyWith(fontSize: 9.0),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final color in swatches)
                AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.editorialDecel,
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: AppColors.surfaceCanvas,
                      width: 2.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F1A1817),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Seletor de Cartela Alternativa
          if (onPaletteSelected != null) ...[
            Text(
              'ALTERNAR CARTELA SAZONAL',
              style: AppTypography.metadataBadge(color: AppColors.textSecondary)
                  .copyWith(fontSize: 9.0),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (final p in SeasonalPaletteType.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onPaletteSelected!(p);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: p == paletteType
                                ? AppColors.textPrimary
                                : AppColors.surfaceCanvas,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: p == paletteType
                                  ? AppColors.textPrimary
                                  : AppColors.borderSubtle,
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            p.displayName,
                            style: AppTypography.metadataBadge(
                              color: p == paletteType
                                  ? AppColors.surfaceCanvas
                                  : AppColors.textPrimary,
                            ).copyWith(fontSize: 9.5),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Desenho dos Cantos Finos Dourados do Visor HUD de Câmera
class _CameraHudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.iheGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const cornerLength = 16.0;
    const margin = 12.0;

    // Canto Superior Esquerdo
    canvas.drawLine(
      const Offset(margin, margin),
      const Offset(margin + cornerLength, margin),
      paint,
    );
    canvas.drawLine(
      const Offset(margin, margin),
      const Offset(margin, margin + cornerLength),
      paint,
    );

    // Canto Superior Direito
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin - cornerLength, margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin, margin + cornerLength),
      paint,
    );

    // Canto Inferior Esquerdo
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin + cornerLength, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin, size.height - margin - cornerLength),
      paint,
    );

    // Canto Inferior Direito
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin - cornerLength, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin, size.height - margin - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
