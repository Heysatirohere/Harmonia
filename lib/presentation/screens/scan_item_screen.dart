import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/wardrobe_api_service.dart';
import '../../models/clothing_item.dart';
import '../../models/garment_segmentation.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_room.dart';
import '../atelier/atelier_widgets.dart';
import '../atelier/room_scene.dart';
import '../widgets/color_extractor_chips.dart';
import '../widgets/segmentation_preview.dart';

/// Tela do Fluxo de Digitalização e Cadastro Rápido de Peças (Scanner / Upload)
/// Conforme AGENTS.md e Regra dos 3 Toques (RNF06):
/// - Toque 1: Captura/Alternância da foto e remoção do fundo via IA.
/// - Toque 2: Confirmação rápida dos atributos extraídos (categoria, formalidade, CIE L*a*b*).
/// - Toque 3: Toque em "Catalogar no Acervo" em accentCinnabar com HapticFeedback.mediumImpact().
/// Sala frescoBlue: fundo frio para a cor da peça recortada se destacar (AGENTS.md 4.2).
class ScanItemScreen extends StatefulWidget {
  final ValueChanged<ClothingItem>? onItemCataloged;

  const ScanItemScreen({super.key, this.onItemCataloged});

  @override
  State<ScanItemScreen> createState() => _ScanItemScreenState();
}

class _ScanItemScreenState extends State<ScanItemScreen> {
  final WardrobeApiService _wardrobeService = WardrobeApiService();
  final ImagePicker _picker = ImagePicker();

  // Foto capturada pelo usuário e resultado do recorte/extração cromática (RF04, RF05)
  Uint8List? _capturedBytes;
  String? _capturedFileName;
  GarmentSegmentation? _segmentation;
  bool _isSegmenting = false;
  String? _segmentationError;
  bool _isUploading = false;

  // Dados da inferência da IA / edição do usuário
  final TextEditingController _nameController = TextEditingController(text: 'Sobrecamisa Terracota Ateliê');
  final TextEditingController _provenanceController = TextEditingController(text: 'Linho Italiano • Segundas Mãos');
  final TextEditingController _esgNoteController = TextEditingController(text: '100% Linho Reciclado Certificado');

  int _selectedCategoryIndex = 0;
  final List<String> _categories = const ['Partes de cima', 'Partes de baixo', 'Calçados', 'Peças únicas'];

  double _formalityLevel = 0.65; // 65% Casual Chic
  bool _isConsciousFashion = true;
  int _selectedColorIndex = 0;

  List<ExtractedColorCentroid> get _extractedCentroids => [
    for (final c in _segmentation?.colors ?? const <GarmentColor>[])
      ExtractedColorCentroid(
        color: c.color,
        hexCode: c.hex,
        nuanceName: c.name,
        labCoordinates: c.labLabel,
        percentage: c.percentage,
      ),
  ];

  bool get _canCatalog => _segmentation != null && !_isUploading;

  @override
  void dispose() {
    _nameController.dispose();
    _provenanceController.dispose();
    _esgNoteController.dispose();
    super.dispose();
  }

  void _showSourcePicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.paperBone,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inkSecondary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Capturar Peça de Roupa',
              style: AppTypography.displayEditorial().copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.accentCinnabar),
              title: Text('Câmera Fotográfica', style: AppTypography.uiHeadline()),
              subtitle: Text('Fotografe a peça no cabide ou superfície plana', style: AppTypography.bodyReading()),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            const Divider(color: AppColors.hairlineInk, height: 1),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.gildedInk),
              title: Text('Galeria de Fotos', style: AppTypography.uiHeadline()),
              subtitle: Text('Escolha uma foto da galeria do seu dispositivo', style: AppTypography.bodyReading()),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1400);

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _capturedBytes = bytes;
          _capturedFileName = picked.name;
          if (_nameController.text == 'Sobrecamisa Terracota Ateliê') {
            _nameController.text = 'Nova Peça do Acervo';
          }
        });
        HapticFeedback.mediumImpact();
        await _analyzePhoto();
      }
    } catch (e) {
      debugPrint('[ScanItemScreen] Erro ao selecionar imagem: $e');
    }
  }

  /// Envia a foto ao pipeline de recorte de fundo e extração cromática
  Future<void> _analyzePhoto() async {
    final bytes = _capturedBytes;
    if (bytes == null) return;

    setState(() {
      _isSegmenting = true;
      _segmentation = null;
      _segmentationError = null;
      _selectedColorIndex = 0;
    });

    try {
      final result = await _wardrobeService.segmentGarment(
        imageBytes: bytes,
        fileName: _capturedFileName ?? 'peca.jpg',
      );
      if (!mounted || !identical(bytes, _capturedBytes)) return;
      setState(() => _segmentation = result);
      HapticFeedback.selectionClick();
    } on SegmentationException catch (e) {
      if (!mounted || !identical(bytes, _capturedBytes)) return;
      setState(() => _segmentationError = e.message);
    } finally {
      if (mounted && identical(bytes, _capturedBytes)) {
        setState(() => _isSegmenting = false);
      }
    }
  }

  Future<void> _handleCatalogItem() async {
    final segmentation = _segmentation;
    if (segmentation == null || _isUploading) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isUploading = true;
    });

    final selectedColor = segmentation.colors[_selectedColorIndex];
    final defaultUrl = 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800&auto=format&fit=crop&q=80';

    final newItem = ClothingItem(
      id: 'scanned-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim().isEmpty ? 'Peça sem nome' : _nameController.text.trim(),
      category: _categories[_selectedCategoryIndex],
      dominantColor: selectedColor.color,
      labColorSpace: selectedColor.labLabel,
      labL: selectedColor.l,
      labA: selectedColor.a,
      labB: selectedColor.b,
      formalityScore: _formalityLevel,
      usageRate: 1,
      imageUrl: defaultUrl,
      brandOrProvenance: _provenanceController.text.trim().isEmpty
          ? 'Acervo Pessoal'
          : _provenanceController.text.trim(),
      isConsciousFashion: _isConsciousFashion,
      consciousNote: _isConsciousFashion ? _esgNoteController.text.trim() : null,
    );

    // Upload no Supabase Storage e persistência no banco
    ClothingItem catalogedItem = newItem;
    try {
      // Envia o recorte PNG com canal alfa, não a foto original
      catalogedItem = await _wardrobeService.uploadAndCatalogGarment(
        imageBytes: segmentation.cutoutPng,
        fileName: 'garment_${DateTime.now().microsecondsSinceEpoch}.png',
        item: newItem,
      );
    } catch (e) {
      debugPrint('[ScanItemScreen] Erro na catalogação: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }

    widget.onItemCataloged?.call(catalogedItem);

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context, catalogedItem);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.tapestryNoir,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMedium)),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.gildedLeaf, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Peça "${catalogedItem.name}" catalogada no seu acervo!',
                  style: AppTypography.bodyReading(color: AppColors.ivoryText),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final centroids = _extractedCentroids;

    return Scaffold(
      backgroundColor: AppColors.tapestryNoir,
      body: RoomScene(
        room: AtelierRoom.frescoBlue,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Cabeçalho Editorial com Ação de Fechar
            SliverToBoxAdapter(
              child: RoomHeader(
                eyebrow: 'Pipeline morfocromático • RNF06',
                title: 'Digitalizar peça',
                room: AtelierRoom.frescoBlue,
                trailing: RoomIconButton(
                  icon: Icons.close_rounded,
                  label: 'Fechar',
                  onTap: () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  },
                ),
              ),
            ),

            // 2. TOQUE 1: Visualizador de Remoção de Fundo (Foto Bruta vs PNG Alfa)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                child: SegmentationPreview(
                  originalBytes: _capturedBytes,
                  cutoutBytes: _segmentation?.cutoutPng,
                  isProcessing: _isSegmenting,
                  errorMessage: _segmentationError,
                  onRetry: _analyzePhoto,
                  onChangePhoto: _showSourcePicker,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 3. TOQUE 2: Painel de Atributos & Morfocromia Extraída
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                child: AtelierSheet(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Extração de Cores no Espaço CIE L*a*b*
                      if (centroids.isNotEmpty)
                        ColorExtractorChips(
                          centroids: centroids,
                          selectedIndex: _selectedColorIndex,
                          onSelectCentroid: (index) {
                            setState(() => _selectedColorIndex = index);
                          },
                        )
                      else
                        Text(
                          _isSegmenting
                              ? 'ANALISANDO CORES NO ESPAÇO CIE L*a*b*...'
                              : 'AS CORES DOMINANTES SURGEM APÓS A ANÁLISE DA FOTO',
                          style: AppTypography.metadataBadge(color: AppColors.inkSecondary).copyWith(fontSize: 9.5),
                        ),

                      const SizedBox(height: 24),
                      const Divider(color: AppColors.hairlineInk, height: 1),
                      const SizedBox(height: 20),

                      // Campo de Nome da Peça
                      Text(
                        'NOME DA PEÇA',
                        style: AppTypography.metadataBadge(color: AppColors.inkSecondary).copyWith(fontSize: 9.5),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        style: AppTypography.uiHeadline(color: AppColors.inkText),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.paperBoneRaised,
                          hintText: 'Ex: Blazer Linho Cru',
                          hintStyle: AppTypography.bodyReading(color: AppColors.inkSecondary),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            borderSide: const BorderSide(color: AppColors.hairlineInk, width: 0.8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            borderSide: const BorderSide(color: AppColors.hairlineInk, width: 0.8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            borderSide: const BorderSide(color: AppColors.accentCinnabar, width: 1.2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Seleção de Categoria Minimalista
                      Text(
                        'CATEGORIA TAXONÔMICA',
                        style: AppTypography.metadataBadge(color: AppColors.inkSecondary).copyWith(fontSize: 9.5),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            for (int i = 0; i < _categories.length; i++) ...[
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedCategoryIndex = i);
                                },
                                child: AnimatedContainer(
                                  duration: AppMotion.fast,
                                  curve: AppMotion.editorialDecel,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: i == _selectedCategoryIndex ? AppColors.inkText : AppColors.paperBoneRaised,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: i == _selectedCategoryIndex ? AppColors.inkText : AppColors.hairlineInk,
                                      width: 0.6,
                                    ),
                                  ),
                                  child: Text(
                                    _categories[i],
                                    style: AppTypography.uiHeadline(
                                      color: i == _selectedCategoryIndex ? AppColors.paperBone : AppColors.inkText,
                                    ).copyWith(fontSize: 12),
                                  ),
                                ),
                              ),
                              if (i < _categories.length - 1) const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Slider de Formalidade (0% a 100%)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'NÍVEL DE FORMALIDADE',
                            style: AppTypography.metadataBadge(color: AppColors.inkSecondary).copyWith(fontSize: 9.5),
                          ),
                          Text(
                            '${(_formalityLevel * 100).round()}% • ${_getFormalityLabel(_formalityLevel)}',
                            style: AppTypography.uiHeadline(
                              color: AppColors.accentCinnabar,
                            ).copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          activeTrackColor: AppColors.accentCinnabar,
                          inactiveTrackColor: AppColors.paperBone,
                          thumbColor: AppColors.accentCinnabar,
                          overlayColor: AppColors.accentCinnabar.withValues(alpha: 0.12),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        ),
                        child: Slider(
                          value: _formalityLevel,
                          onChanged: (value) {
                            setState(() => _formalityLevel = value);
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Proveniência / Brechó
                      Text(
                        'PROVENIÊNCIA & ORIGEM',
                        style: AppTypography.metadataBadge(color: AppColors.inkSecondary).copyWith(fontSize: 9.5),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _provenanceController,
                        style: AppTypography.bodyReading(color: AppColors.inkText),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.paperBoneRaised,
                          hintText: 'Ex: Brechó Vintage 1994',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            borderSide: const BorderSide(color: AppColors.hairlineInk, width: 0.8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            borderSide: const BorderSide(color: AppColors.hairlineInk, width: 0.8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            borderSide: const BorderSide(color: AppColors.accentCinnabar, width: 1.2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Switch Editorial de Moda Consciente / ESG
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.paperBoneRaised,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          border: Border.all(
                            color: _isConsciousFashion
                                ? AppColors.verdigrisInk.withValues(alpha: 0.4)
                                : AppColors.hairlineInk,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.eco_outlined, color: AppColors.verdigrisInk, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MODA CONSCIENTE / SEGULINHA CIRCULAR',
                                    style: AppTypography.metadataBadge(
                                      color: AppColors.verdigrisInk,
                                    ).copyWith(fontSize: 9, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Peça sustentável, vintage ou segunda mão',
                                    style: AppTypography.bodySmall(
                                      color: AppColors.inkSecondary,
                                    ).copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _isConsciousFashion,
                              activeThumbColor: AppColors.paperBoneRaised,
                              activeTrackColor: AppColors.verdigrisInk,
                              onChanged: (val) {
                                HapticFeedback.selectionClick();
                                setState(() => _isConsciousFashion = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // 4. TOQUE 3: CTA primário em cinábrio ("Catalogar no Acervo")
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pageMargin,
                  0,
                  AppSpacing.pageMargin,
                  32 + MediaQuery.paddingOf(context).bottom,
                ),
                child: CinnabarButton(
                  label: 'Catalogar no Acervo',
                  icon: Icons.checkroom_rounded,
                  busy: _isUploading,
                  onPressed: _canCatalog ? _handleCatalogItem : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFormalityLabel(double value) {
    if (value < 0.3) return 'Casual Descontraído';
    if (value < 0.7) return 'Casual Chic / Ateliê';
    return 'Formal / Eventos';
  }
}
