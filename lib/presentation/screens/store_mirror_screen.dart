import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../data/services/outfit_api_service.dart';
import '../../data/services/wardrobe_api_service.dart';
import '../../models/clothing_item.dart';
import '../../models/garment_segmentation.dart';
import '../atelier/atelier_room.dart';
import '../atelier/atelier_widgets.dart';
import '../atelier/room_scene.dart';
import '../widgets/photo_capture.dart';
import '../widgets/store_parity_sheet.dart';

/// Modo Provador: paridade de uma peça da loja com o acervo (RF08, RF09)
///
/// Fluxo em 3 toques (RNF06): categoria → obturador → disparo da câmera.
/// A foto passa pelo mesmo recorte e extração L*a*b* do scanner e é
/// comparada com o acervo pelo motor do IHE, sem gastar a cota diária.
class StoreMirrorScreen extends StatefulWidget {
  final WardrobeApiService? wardrobeService;
  final OutfitApiService? outfitService;
  final PhotoCapture? capturePhoto;

  const StoreMirrorScreen({super.key, this.wardrobeService, this.outfitService, this.capturePhoto});

  @override
  State<StoreMirrorScreen> createState() => _StoreMirrorScreenState();
}

class _StoreMirrorScreenState extends State<StoreMirrorScreen> {
  late final WardrobeApiService _wardrobeService = widget.wardrobeService ?? WardrobeApiService();
  late final OutfitApiService _outfitService = widget.outfitService ?? OutfitApiService();

  /// A segmentação ainda não classifica a peça (RF05), então a categoria é escolhida aqui
  static const _categories = ['Partes de cima', 'Partes de baixo', 'Calçados', 'Peças únicas'];
  String _category = _categories.first;

  Uint8List? _photo;
  bool _analyzing = false;

  Future<void> _capture(ImageSource source) async {
    if (_analyzing) return;
    HapticFeedback.mediumImpact();

    final CapturedPhoto? photo;
    try {
      photo = await (widget.capturePhoto ?? pickPhotoWithSystem)(source);
    } on PlatformException {
      _showMessage('Não foi possível abrir a câmera. Verifique a permissão do app.');
      return;
    }
    if (photo == null || !mounted) return;

    setState(() {
      _photo = photo!.bytes;
      _analyzing = true;
    });

    try {
      final segmentation = await _wardrobeService.segmentGarment(imageBytes: photo.bytes, fileName: photo.name);
      if (segmentation.colors.isEmpty) {
        throw const SegmentationException('Não encontramos a cor da peça. Tente outra foto.');
      }
      final result = await _outfitService.analyzeStoreParity(
        storeGarment: _storeGarment(segmentation.colors.first, segmentation.styleEmbedding),
      );
      if (!mounted) return;
      setState(() => _analyzing = false);
      HapticFeedback.selectionClick();
      await StoreParitySheet.show(context, parityResult: result);
    } on SegmentationException catch (e) {
      _showMessage(e.message);
    } on OutfitException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted && _analyzing) setState(() => _analyzing = false);
    }
  }

  ClothingItem _storeGarment(GarmentColor color, List<double>? styleEmbedding) {
    return ClothingItem(
      id: 'store-${DateTime.now().millisecondsSinceEpoch}',
      name: '${_singular(_category)} ${color.name.toLowerCase()}',
      category: _category,
      dominantColor: color.color,
      labColorSpace: color.labLabel,
      labL: color.l,
      labA: color.a,
      labB: color.b,
      styleEmbedding: styleEmbedding,
      usageRate: 0,
      imageUrl: '',
      brandOrProvenance: 'Peça da loja',
    );
  }

  static String _singular(String category) => switch (category) {
        'Partes de cima' => 'Parte de cima',
        'Partes de baixo' => 'Parte de baixo',
        'Calçados' => 'Calçado',
        _ => 'Peça única',
      };

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.tapestryNoir,
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: GoogleFonts.interTight(color: AppColors.ivoryText, fontSize: 13)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photo;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return Scaffold(
      backgroundColor: AppColors.tapestryNoir,
      body: Stack(
        // O body do Scaffold tem altura livre; sem expand a Stack encolhe até a barra do topo
        fit: StackFit.expand,
        children: [
          // A foto da peça vira a cenografia; antes dela, a tapeçaria noturna
          Positioned.fill(
            key: const Key('mirror_backdrop'),
            child: photo != null
                ? Image.memory(
                    photo,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    cacheWidth: (MediaQuery.sizeOf(context).width * dpr).round(),
                    gaplessPlayback: true,
                  )
                : const RoomScene(room: AtelierRoom.tapestryNoir, child: SizedBox.expand()),
          ),
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: const Cubic(0.16, 1.0, 0.3, 1.0),
              color: AppColors.tapestryNoir.withValues(alpha: _analyzing ? 0.6 : 0.35),
            ),
          ),

          // Viewfinder Golden Fine-Line HUD
          Positioned.fill(
            child: CustomPaint(
              painter: _ViewfinderPainter(
                lineColor: AppColors.gildedLeaf,
              ),
            ),
          ),

          // Top Navigation Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.ivoryText, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.tapestryNoir.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.hairlineGold, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flare, color: AppColors.gildedLeaf, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'MIRROR MODE • PROVADOR',
                            style: GoogleFonts.interTight(
                              color: AppColors.ivoryText,
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
          ),

          // Categoria da peça & obturador
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        for (final category in _categories) ...[
                          _buildCategoryChip(category),
                          if (category != _categories.last) const SizedBox(width: 10),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 40),
                      const SizedBox(width: 28),
                      // Obturador: abre a câmera
                      GestureDetector(
                        key: const Key('shutter_button'),
                        onTap: () => _capture(ImageSource.camera),
                        child: AnimatedScale(
                          scale: _analyzing ? 0.92 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: const Cubic(0.34, 1.56, 0.64, 1.0),
                          child: CustomPaint(
                            size: const Size(76, 76),
                            painter: _ShutterButtonPainter(
                              borderColor: AppColors.gildedLeaf,
                              innerColor: AppColors.ivoryText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 28),
                      RoomIconButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Escolher da galeria',
                        onTap: () => _capture(ImageSource.gallery),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _analyzing
                          ? 'Comparando a peça com o seu acervo…'
                          : 'Fotografe a peça da loja para comparar com o seu acervo',
                      key: ValueKey(_analyzing),
                      style: GoogleFonts.interTight(
                        color: AppColors.ivoryMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildCategoryChip(String category) {
    final isSelected = _category == category;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _category = category);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.ivoryText
              : AppColors.tapestryNoir.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.gildedLeaf : AppColors.hairlineIvory,
            width: 1.0,
          ),
        ),
        child: Text(
          category,
          style: GoogleFonts.interTight(
            color: isSelected ? AppColors.inkText : AppColors.ivoryText,
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
