import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../mocks/mock_store_parity.dart';
import '../widgets/store_parity_sheet.dart';

/// Screen for Mirror Mode / Store Garment Parity Analysis (RF08)
class StoreMirrorScreen extends StatefulWidget {
  const StoreMirrorScreen({super.key});

  @override
  State<StoreMirrorScreen> createState() => _StoreMirrorScreenState();
}

class _StoreMirrorScreenState extends State<StoreMirrorScreen> {
  String _selectedStore = 'Lojas Renner';
  bool _isCapturing = false;

  void _onCaptureGarment() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isCapturing = true;
    });

    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;
    setState(() {
      _isCapturing = false;
    });

    StoreParitySheet.show(
      context,
      parityResult: MockStoreParity.sample,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvasDark,
      body: Stack(
        children: [
          // Camera Simulation Background with error handling
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=1000',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.surfaceCanvasDark,
                  child: const Center(
                    child: Icon(Icons.camera_alt_outlined, color: Colors.white30, size: 64),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),

          // Viewfinder Golden Fine-Line HUD
          Positioned.fill(
            child: CustomPaint(
              painter: _ViewfinderPainter(
                lineColor: AppColors.borderGold,
              ),
            ),
          ),

          // Top Navigation Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderGold, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flare, color: AppColors.iheGold, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'MIRROR MODE • PROVADOR',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // Store Switcher & Bottom Shutter Controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Store selector chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStoreChip('Lojas Renner'),
                      const SizedBox(width: 12),
                      _buildStoreChip('C&A'),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Shutter Button
                  GestureDetector(
                    key: const Key('shutter_button'),
                    onTap: _onCaptureGarment,
                    child: AnimatedScale(
                      scale: _isCapturing ? 0.92 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: CustomPaint(
                        size: const Size(76, 76),
                        painter: _ShutterButtonPainter(
                          borderColor: AppColors.iheGold,
                          innerColor: AppColors.surfaceCanvas,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Toque para analisar paridade com seu acervo',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreChip(String storeName) {
    final isSelected = _selectedStore == storeName;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedStore = storeName;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceCanvas
              : Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.iheGold : Colors.white24,
            width: 1.0,
          ),
        ),
        child: Text(
          storeName,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? AppColors.textPrimary : Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  final Color lineColor;

  _ViewfinderPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(
      size.width * 0.12,
      size.height * 0.20,
      size.width * 0.76,
      size.height * 0.52,
    );

    canvas.drawRect(rect, paint);

    const cornerLength = 20.0;
    final cornerPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, cornerLength), cornerPaint);

    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight - const Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft - const Offset(0, cornerLength), cornerPaint);

    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight - const Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight - const Offset(0, cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShutterButtonPainter extends CustomPainter {
  final Color borderColor;
  final Color innerColor;

  _ShutterButtonPainter({
    required this.borderColor,
    required this.innerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer thin gold ring
    final outerPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 2, outerPaint);

    // Inner soft solid circle
    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 8, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
