import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../mocks/mock_store_parity.dart';
import '../../models/store_parity_result.dart';
import '../widgets/store_parity_sheet.dart';

/// Tela do Provador em Loja (Mirror Mode - RF08 & RF09)
///
/// Interface com simulação de visor de câmera fotográfica com linhas ultrafinas
/// douradas (iheGold), botão obturador autoral via CustomPainter e abertura
/// automática da bandeja de paridade com o acervo residencial.
class StoreMirrorScreen extends StatefulWidget {
  final StoreParityResult? initialParityMock;

  const StoreMirrorScreen({
    super.key,
    this.initialParityMock,
  });

  @override
  State<StoreMirrorScreen> createState() => _StoreMirrorScreenState();
}

class _StoreMirrorScreenState extends State<StoreMirrorScreen> {
  late StoreParityResult _currentParityResult;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  bool _hasCaptured = false;

  @override
  void initState() {
    super.initState();
    _currentParityResult =
        widget.initialParityMock ?? MockStoreParity.blazerTerracotaRenner;
  }

  void _handleShutterPress() async {
    HapticFeedback.mediumImpact();

    setState(() {
      _isCapturing = true;
    });

    // Simulação do tempo de disparo e inferência de visão computacional
    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;

    setState(() {
      _isCapturing = false;
      _hasCaptured = true;
    });

    // Abertura automática da Bandeja de Paridade (RF09)
    _openParitySheet();
  }

  void _openParitySheet() {
    StoreParitySheet.show(
      context,
      parityResult: _currentParityResult,
    );
  }

  void _toggleMockScenario() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_currentParityResult.storeGarment.id == 'store_01') {
        _currentParityResult = MockStoreParity.calcaAreiaCA;
      } else {
        _currentParityResult = MockStoreParity.blazerTerracotaRenner;
      }
      _hasCaptured = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final storeGarment = _currentParityResult.storeGarment;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. SIMULAÇÃO DO FEED DE CÂMERA DO PROVADOR
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  AppColors.textPrimary.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.9),
                ],
              ),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 220,
                height: 280,
                decoration: BoxDecoration(
                  color: storeGarment.dominantColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.iheGold.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.checkroom_outlined,
                      size: 48,
                      color: storeGarment.dominantColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      storeGarment.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${storeGarment.storeName} • Peça Detectada',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.accentSand,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. HUD DE ENQUADRAMENTO DA CÂMERA (LINHAS ULTRAFINAS DOURADAS)
          const Positioned.fill(
            child: IgnorePointer(
              child: _CameraViewfinderOverlay(),
            ),
          ),

          // 3. BARRA SUPERIOR DO HUD (CONTROLES MINIMALISTAS)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botão Fechar (Voltar)
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    // Title Badge Minimalista
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.borderGold,
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('✦ ',
                              style: TextStyle(
                                  color: AppColors.iheGold, fontSize: 10)),
                          Text(
                            'PROVADOR AR • MIRROR MODE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.iheGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Toggle Flash
                    IconButton(
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off_outlined,
                        color: _isFlashOn ? AppColors.iheGold : Colors.white,
                        size: 22,
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _isFlashOn = !_isFlashOn;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. PAINEL INFERIOR DO HUD (OBTURADOR + SELETOR DE LOJA)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Seletor do Mock de Peça em Loja (Renner vs C&A)
                    GestureDetector(
                      onTap: _toggleMockScenario,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.iheGold.withValues(alpha: 0.6),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.swap_horiz,
                                color: AppColors.iheGold, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Simular: ${storeGarment.title} (${storeGarment.storeName})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.surfaceCanvas,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Linha do Obturador CustomPainter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Botão de Reabrir Bandeja (se já capturou)
                        IconButton(
                          icon: Icon(
                            Icons.layers_outlined,
                            color: _hasCaptured
                                ? AppColors.iheGold
                                : Colors.white54,
                            size: 26,
                          ),
                          onPressed: _hasCaptured ? _openParitySheet : null,
                        ),

                        // OBTURADOR FOTOGRÁFICO CUSTOM PAINTER
                        GestureDetector(
                          key: const Key('shutter_button'),
                          onTap: _isCapturing ? null : _handleShutterPress,
                          child: SizedBox(
                            width: 76,
                            height: 76,
                            child: CustomPaint(
                              painter: _ShutterButtonPainter(
                                isPressed: _isCapturing,
                              ),
                            ),
                          ),
                        ),

                        // Botão Trocar Câmera
                        IconButton(
                          icon: const Icon(Icons.cameraswitch_outlined,
                              color: Colors.white, size: 26),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _hasCaptured
                          ? 'Toque nas camadas para ver a paridade ou fotografe outra peça'
                          : 'Toque no obturador para analisar a paridade com seu acervo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: Colors.white70,
                      ),
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

/// CustomPainter para as linhas ultrafinas douradas do visor (HUD Overlay)
class _CameraViewfinderOverlay extends StatelessWidget {
  const _CameraViewfinderOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ViewfinderPainter(
        color: AppColors.iheGold.withValues(alpha: 0.7),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  final Color color;

  _ViewfinderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    const boxWidth = 240.0;
    const boxHeight = 320.0;
    const cornerLength = 20.0;

    final left = center.dx - boxWidth / 2;
    final top = center.dy - boxHeight / 2;
    final right = center.dx + boxWidth / 2;
    final bottom = center.dy + boxHeight / 2;

    // Cantos Dourados do Visor
    // Top-Left
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), paint);

    // Top-Right
    canvas.drawLine(
        Offset(right, top), Offset(right - cornerLength, top), paint);
    canvas.drawLine(
        Offset(right, top), Offset(right, top + cornerLength), paint);

    // Bottom-Left
    canvas.drawLine(
        Offset(left, bottom), Offset(left + cornerLength, bottom), paint);
    canvas.drawLine(
        Offset(left, bottom), Offset(left, bottom - cornerLength), paint);

    // Bottom-Right
    canvas.drawLine(
        Offset(right, bottom), Offset(right - cornerLength, bottom), paint);
    canvas.drawLine(
        Offset(right, bottom), Offset(right, bottom - cornerLength), paint);

    // Retículo Central Ultrafino (Crosshair)
    const crossSize = 8.0;
    final finePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawLine(Offset(center.dx - crossSize, center.dy),
        Offset(center.dx + crossSize, center.dy), finePaint);
    canvas.drawLine(Offset(center.dx, center.dy - crossSize),
        Offset(center.dx, center.dy + crossSize), finePaint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// CustomPainter para o Botão do Obturador Minimalista
class _ShutterButtonPainter extends CustomPainter {
  final bool isPressed;

  _ShutterButtonPainter({this.isPressed = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 2;

    // Anel Externo Dourado
    final outerPaint = Paint()
      ..color = AppColors.iheGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(center, outerRadius, outerPaint);

    // Anel Interno de Respiro
    final gapPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, outerRadius - 3, gapPaint);

    // Centro Macio Creme/Dourado
    final innerPaint = Paint()
      ..color = isPressed ? AppColors.iheGold : AppColors.surfaceCanvas
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius - (isPressed ? 8 : 10), innerPaint);
  }

  @override
  bool shouldRepaint(covariant _ShutterButtonPainter oldDelegate) =>
      oldDelegate.isPressed != isPressed;
}
