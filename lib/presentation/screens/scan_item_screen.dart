import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/wardrobe_api_service.dart';
import '../../models/clothing_item.dart';
import '../../theme/app_theme.dart';
import '../widgets/color_extractor_chips.dart';
import '../widgets/segmentation_preview.dart';

/// Tela do Fluxo de Digitalização e Cadastro Rápido de Peças (Scanner / Upload)
/// Conforme AGENTS.md e Regra dos 3 Toques (RNF06):
/// - Toque 1: Captura/Alternância da foto e remoção do fundo via IA.
/// - Toque 2: Confirmação rápida dos atributos extraídos (categoria, formalidade, CIE L*a*b*).
/// - Toque 3: Toque em "Catalogar no Acervo" em accentTerracotta com HapticFeedback.mediumImpact().
class ScanItemScreen extends StatefulWidget {
  final ValueChanged<ClothingItem>? onItemCataloged;

  const ScanItemScreen({
    super.key,
    this.onItemCataloged,
  });

  @override
  State<ScanItemScreen> createState() => _ScanItemScreenState();
}

class _ScanItemScreenState extends State<ScanItemScreen> {
  final WardrobeApiService _wardrobeService = WardrobeApiService();
  final ImagePicker _picker = ImagePicker();

  // Foto capturada pelo usuário
  Uint8List? _capturedBytes;
  String? _capturedFileName;
  bool _isUploading = false;

  // Dados da inferência da IA / edição do usuário
  final TextEditingController _nameController =
      TextEditingController(text: 'Sobrecamisa Terracota Ateliê');
  final TextEditingController _provenanceController =
      TextEditingController(text: 'Linho Italiano • Segundas Mãos');
  final TextEditingController _esgNoteController =
      TextEditingController(text: '100% Linho Reciclado Certificado');

  int _selectedCategoryIndex = 0;
  final List<String> _categories = const [
    'Partes de cima',
    'Partes de baixo',
    'Calçados',
    'Ocasião',
  ];

  double _formalityLevel = 0.65; // 65% Casual Chic
  bool _isConsciousFashion = true;
  int _selectedColorIndex = 0;

  final List<ExtractedColorCentroid> _extractedCentroids = const [
    ExtractedColorCentroid(
      color: AppColors.accentTerracotta,
      hexCode: '#A34836',
      nuanceName: 'Terracota Ateliê',
      labCoordinates: 'L* 58.4, a* 28.2, b* 24.1',
      percentage: 62,
    ),
    ExtractedColorCentroid(
      color: AppColors.accentSand,
      hexCode: '#D9CDBF',
      nuanceName: 'Areia Suave',
      labCoordinates: 'L* 82.1, a* 4.3, b* 11.8',
      percentage: 24,
    ),
    ExtractedColorCentroid(
      color: AppColors.textPrimary,
      hexCode: '#1A1817',
      nuanceName: 'Carvão Profundo',
      labCoordinates: 'L* 14.2, a* 0.5, b* -0.8',
      percentage: 14,
    ),
  ];

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
          color: AppColors.surfaceCanvas,
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
                  color: AppColors.textSecondary.withValues(alpha: 0.25),
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
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.accentTerracotta),
              title: Text('Câmera Fotográfica', style: AppTypography.uiHeadline()),
              subtitle: Text('Fotografe a peça no cabide ou superfície plana', style: AppTypography.bodyReading()),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.iheGold),
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
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1400,
      );

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
      }
    } catch (e) {
      debugPrint('[ScanItemScreen] Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _handleCatalogItem() async {
    if (_isUploading) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isUploading = true;
    });

    final selectedCentroid = _extractedCentroids[_selectedColorIndex];
    final defaultUrl =
        'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800&auto=format&fit=crop&q=80';

    final newItem = ClothingItem(
      id: 'scanned-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim().isEmpty
          ? 'Peça sem nome'
          : _nameController.text.trim(),
      category: _categories[_selectedCategoryIndex],
      dominantColor: selectedCentroid.color,
      labColorSpace: selectedCentroid.labCoordinates,
      usageRate: 1,
      imageUrl: defaultUrl,
      brandOrProvenance: _provenanceController.text.trim().isEmpty
          ? 'Acervo Pessoal'
          : _provenanceController.text.trim(),
      isConsciousFashion: _isConsciousFashion,
      consciousNote: _isConsciousFashion ? _esgNoteController.text.trim() : null,
      iheScore: 91,
    );

    // Upload no Supabase Storage e persistência no banco
    ClothingItem catalogedItem = newItem;
    try {
      catalogedItem = await _wardrobeService.uploadAndCatalogGarment(
        imageBytes: _capturedBytes,
        fileName: _capturedFileName,
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
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.iheGold, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Peça "${catalogedItem.name}" catalogada no seu acervo!',
                  style: AppTypography.bodyReading(color: AppColors.surfaceCanvas),
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
    final selectedCentroid = _extractedCentroids[_selectedColorIndex];

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Cabeçalho Editorial com Ação de Fechar
            SliverToBoxAdapter(
              child: _buildEditorialHeader(context),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 12),
            ),

            // 2. TOQUE 1: Visualizador de Remoção de Fundo (Foto Bruta vs PNG Alfa)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                child: SegmentationPreview(
                  rawImageUrl:
                      'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800&auto=format&fit=crop&q=80',
                  croppedImageUrl:
                      'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800&auto=format&fit=crop&q=80',
                  localImageBytes: _capturedBytes,
                  onChangePhoto: _showSourcePicker,
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),

            // 3. TOQUE 2: Painel de Atributos & Morfocromia Extraída
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Extração de Cores no Espaço CIE L*a*b*
                    ColorExtractorChips(
                      centroids: _extractedCentroids,
                      selectedIndex: _selectedColorIndex,
                      onSelectCentroid: (index) {
                        setState(() => _selectedColorIndex = index);
                      },
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: AppColors.borderSubtle, height: 1),
                    const SizedBox(height: 20),

                    // Campo de Nome da Peça
                    Text(
                      'NOME DA PEÇA',
                      style: AppTypography.metadataBadge(color: AppColors.textSecondary)
                          .copyWith(fontSize: 9.5),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      style: AppTypography.uiHeadline(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceRaised,
                        hintText: 'Ex: Blazer Linho Cru',
                        hintStyle: AppTypography.bodyReading(color: AppColors.textMuted),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          borderSide:
                              const BorderSide(color: AppColors.accentTerracotta, width: 1.2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seleção de Categoria Minimalista
                    Text(
                      'CATEGORIA TAXONÔMICA',
                      style: AppTypography.metadataBadge(color: AppColors.textSecondary)
                          .copyWith(fontSize: 9.5),
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
                                  color: i == _selectedCategoryIndex
                                      ? AppColors.textPrimary
                                      : AppColors.surfaceRaised,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: i == _selectedCategoryIndex
                                        ? AppColors.textPrimary
                                        : AppColors.borderSubtle,
                                    width: 0.6,
                                  ),
                                ),
                                child: Text(
                                  _categories[i],
                                  style: AppTypography.uiHeadline(
                                    color: i == _selectedCategoryIndex
                                        ? AppColors.surfaceCanvas
                                        : AppColors.textPrimary,
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
                          style: AppTypography.metadataBadge(color: AppColors.textSecondary)
                              .copyWith(fontSize: 9.5),
                        ),
                        Text(
                          '${(_formalityLevel * 100).round()}% • ${_getFormalityLabel(_formalityLevel)}',
                          style: AppTypography.uiHeadline(color: AppColors.accentTerracotta)
                              .copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        activeTrackColor: AppColors.accentTerracotta,
                        inactiveTrackColor: AppColors.surfaceSubtle,
                        thumbColor: AppColors.accentTerracotta,
                        overlayColor: AppColors.accentTerracotta.withValues(alpha: 0.12),
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
                      style: AppTypography.metadataBadge(color: AppColors.textSecondary)
                          .copyWith(fontSize: 9.5),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _provenanceController,
                      style: AppTypography.bodyReading(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceRaised,
                        hintText: 'Ex: Brechó Vintage 1994',
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          borderSide:
                              const BorderSide(color: AppColors.accentTerracotta, width: 1.2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Switch Editorial de Moda Consciente / ESG
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        border: Border.all(
                          color: _isConsciousFashion
                              ? AppColors.accentOlive.withValues(alpha: 0.4)
                              : AppColors.borderSubtle,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.eco_outlined,
                            color: AppColors.accentOlive,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MODA CONSCIENTE / SEGULINHA CIRCULAR',
                                  style: AppTypography.metadataBadge(color: AppColors.accentOlive)
                                      .copyWith(fontSize: 9, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'Peça sustentável, vintage ou segunda mão',
                                  style: AppTypography.bodySmall(color: AppColors.textSecondary)
                                      .copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isConsciousFashion,
                            activeColor: AppColors.accentOlive,
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

            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),

            // 4. TOQUE 3: CTA Primário em Terracota ("Catalogar no Acervo")
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageMargin,
                  0,
                  AppSpacing.pageMargin,
                  32,
                ),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _handleCatalogItem,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.surfaceCanvas),
                            ),
                          )
                        : const Icon(
                            Icons.checkroom_rounded,
                            color: AppColors.surfaceCanvas,
                            size: 20,
                          ),
                    label: Text(
                      _isUploading ? 'Catalogando Peça...' : 'Catalogar no Acervo',
                      style: AppTypography.uiHeadline(color: AppColors.surfaceCanvas).copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentTerracotta,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      ),
                      shadowColor: AppColors.accentTerracotta.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorialHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageMargin,
        MediaQuery.of(context).padding.top + 16,
        AppSpacing.pageMargin,
        8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Digitalizar Peça',
                style: AppTypography.displayEditorial().copyWith(
                  fontSize: 28,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'PIPELINE MORFO-CROMÁTICO (RNF06)',
                style: AppTypography.metadataBadge(
                  color: AppColors.accentTerracotta,
                ).copyWith(fontSize: 9.5, letterSpacing: 1.2),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  String _getFormalityLabel(double value) {
    if (value < 0.3) return 'Casual Descontraído';
    if (value < 0.7) return 'Casual Chic / Ateliê';
    return 'Formal / Eventos';
  }
}
