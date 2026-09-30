import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/wardrobe_api_service.dart';
import '../../mocks/mock_clothes.dart';
import '../../models/clothing_item.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_room.dart';
import '../atelier/room_scene.dart';
import '../widgets/clothing_card.dart';
import '../widgets/filter_chips_bar.dart';
import 'scan_item_screen.dart';
import 'wardrobe_analytics_screen.dart';

/// Tela do Guarda-Roupa / Inventário Virtual ("The Floating Canvas")
/// Conforme AGENTS.md (Renascença do Ateliê):
/// - Cada categoria é uma seção com sua própria Sala; o fundo se dissolve entre elas no scroll
/// - Com um filtro ativo, a tela inteira dissolve para a Sala da categoria
/// - Peças flutuam direto sobre a cenografia; detalhes abrem numa folha paperBone
class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  /// Sala de cada categoria do acervo
  static AtelierRoom roomFor(String category) => switch (category) {
        'Partes de cima' => AtelierRoom.silkEmerald,
        'Partes de baixo' => AtelierRoom.velvetBordeaux,
        'Calçados' => AtelierRoom.gildedOchre,
        'Peças únicas' => AtelierRoom.frescoBlue,
        _ => AtelierRoom.verdigris,
      };

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final WardrobeApiService _wardrobeService = WardrobeApiService();
  List<ClothingItem> _items = List.from(mockClothes);
  int _selectedFilterIndex = 0;
  final List<String> _categories = const [
    'Todos',
    'Partes de cima',
    'Partes de baixo',
    'Calçados',
    'Peças únicas',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _wardrobeService.getClothingItems();
    if (mounted && items.isNotEmpty) {
      setState(() {
        _items = items;
      });
    }
  }

  String? get _selectedCategory => _selectedFilterIndex == 0 ? null : _categories[_selectedFilterIndex];

  /// Peças agrupadas por categoria, na ordem dos filtros e depois as demais
  List<(String, List<ClothingItem>)> get _sections {
    final selected = _selectedCategory;
    final groups = <String, List<ClothingItem>>{};
    for (final item in _items) {
      if (selected != null && item.category != selected) continue;
      groups.putIfAbsent(item.category, () => []).add(item);
    }
    int order(String category) {
      final index = _categories.indexOf(category);
      return index < 0 ? _categories.length : index;
    }

    final keys = groups.keys.toList()..sort((a, b) => order(a).compareTo(order(b)));
    return [for (final key in keys) (key, groups[key]!)];
  }

  void _onItemTap(ClothingItem item) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.tapestryNoir.withValues(alpha: 0.55),
      isScrollControlled: true,
      builder: (ctx) => _GarmentDetailSheet(item: item),
    );
  }

  Future<void> _openScanner() async {
    HapticFeedback.mediumImpact();
    final newItem = await Navigator.push<ClothingItem>(
      context,
      MaterialPageRoute(
        builder: (context) => ScanItemScreen(
          onItemCataloged: (item) {
            _wardrobeService.createClothingItem(item);
            setState(() {
              _items.insert(0, item);
              mockClothes.insert(0, item);
            });
          },
        ),
      ),
    );
    if (newItem != null && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    final selected = _selectedCategory;
    final headerRoom = selected != null ? WardrobeScreen.roomFor(selected) : AtelierRoom.silkEmerald;

    return Scaffold(
      backgroundColor: AppColors.tapestryNoir,
      body: RoomScene(
        room: headerRoom,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            RoomMarker(room: headerRoom),
            SliverToBoxAdapter(child: _buildEditorialHeader(context, headerRoom)),
            SliverToBoxAdapter(child: _buildAcervoMetrics(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: FilterChipsBar(
                categories: _categories,
                selectedIndex: _selectedFilterIndex,
                onCategorySelected: (index) {
                  setState(() => _selectedFilterIndex = index);
                },
              ),
            ),
            if (sections.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              for (final (category, items) in sections) ...[
                RoomMarker(room: WardrobeScreen.roomFor(category)),
                SliverToBoxAdapter(child: _SectionHeader(category: category, count: items.length)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 28,
                      crossAxisSpacing: AppSpacing.elementGap,
                      childAspectRatio: 0.66,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        return ClothingCard(item: item, onTap: () => _onItemTap(item));
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
              ],
            // Respiro final: deixa o início da última seção subir até o topo e completar a troca
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.sizeOf(context).height * 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorialHeader(BuildContext context, AtelierRoom room) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageMargin,
        MediaQuery.paddingOf(context).top + 28,
        AppSpacing.pageMargin,
        20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACERVO',
                  style: AppTypography.atelierMeta(
                    color: room.allowsSmallGoldText ? AppColors.gildedLeaf : AppColors.ivoryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Guarda-roupa', style: AppTypography.heroDisplay().copyWith(fontSize: 40)),
                const SizedBox(height: 4),
                Text(
                  'The Floating Canvas',
                  style: AppTypography.subtitleCuratorial(color: AppColors.ivoryMuted),
                ),
              ],
            ),
          ),
          // Digitalizar peça em 1 toque
          Semantics(
            label: 'Digitalizar nova peça',
            button: true,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: _openScanner,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.accentCinnabar,
                  shape: BoxShape.circle,
                  // Contorno capilar: o cinábrio sozinho fica abaixo de 3:1 sobre o bordô
                  border: Border.all(color: AppColors.ivoryText.withValues(alpha: 0.6), width: 1.0),
                ),
                child: const Icon(Icons.add_a_photo_outlined, color: AppColors.ivoryText, size: 21),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcervoMetrics(BuildContext context) {
    final totalItems = _items.length;
    final esgCount = _items.where((i) => i.isConsciousFashion).length;
    final scored = _items.map((i) => i.iheScore).whereType<int>().toList();
    final averageIhe = scored.isEmpty ? null : (scored.reduce((a, b) => a + b) / scored.length).round();

    Widget divider() => Container(
          width: 0.8,
          height: 34,
          color: AppColors.hairlineIvory,
          margin: const EdgeInsets.symmetric(horizontal: 14),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WardrobeAnalyticsScreen(items: _items)),
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.hairlineIvory, width: 0.8),
              bottom: BorderSide(color: AppColors.hairlineIvory, width: 0.8),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _MetricItem(label: 'PEÇAS', value: '$totalItems'),
                  divider(),
                  _MetricItem(
                    label: 'IHE MÉDIO',
                    value: averageIhe == null ? '—' : '$averageIhe%',
                    valueColor: AppColors.gildedLeaf,
                  ),
                  divider(),
                  _MetricItem(
                    label: 'CIRCULARES',
                    value: '$esgCount',
                    valueColor: AppColors.verdigrisLight,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'SAÚDE & ROTAÇÃO DO ACERVO  →',
                  style: AppTypography.atelierMeta(color: AppColors.ivoryText).copyWith(fontSize: 9.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dry_cleaning_outlined, size: 44, color: AppColors.ivoryMuted),
            const SizedBox(height: 16),
            Text(
              'Nenhuma peça nesta categoria',
              style: AppTypography.subtitleCuratorial(color: AppColors.ivoryText),
            ),
            const SizedBox(height: 8),
            Text(
              'Digitalize novas peças em 1 toque para expandir sua arara virtual.',
              style: AppTypography.bodySmall(color: AppColors.ivoryMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Abertura de cada Sala: nome da categoria em itálico de revista
class _SectionHeader extends StatelessWidget {
  final String category;
  final int count;

  const _SectionHeader({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageMargin,
        AppSpacing.sectionGap,
        AppSpacing.pageMargin,
        20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(category, style: AppTypography.sectionDisplay())),
          Text(count == 1 ? '1 PEÇA' : '$count PEÇAS', style: AppTypography.atelierMeta()),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTypography.displayEditorial(color: valueColor ?? AppColors.ivoryText)
                .copyWith(fontSize: 24, height: 1.0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.atelierMeta().copyWith(fontSize: 9),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Folha de leitura (paperBone) com os detalhes morfocromáticos da peça (AGENTS.md 7.5)
class _GarmentDetailSheet extends StatelessWidget {
  final ClothingItem item;

  const _GarmentDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paperBone,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLarge)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairlineInk,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Peça em destaque (PNG alfa sem sombra de caixa)
          Container(
            height: 190,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.paperBoneRaised,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            ),
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.checkroom_outlined, color: AppColors.inkSecondary, size: 36),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category.toUpperCase(),
                      style: AppTypography.atelierMeta(color: AppColors.accentCinnabar),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      style: AppTypography.displayEditorial(color: AppColors.inkText).copyWith(fontSize: 26),
                    ),
                  ],
                ),
              ),
              // Ouro só sobre fundo escuro: joia noir dentro da folha clara
              if (item.iheScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.tapestryNoir,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${item.iheScore}%',
                        style: AppTypography.displayEditorial(color: AppColors.gildedLeaf)
                            .copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      Text('IHE', style: AppTypography.atelierMeta(color: AppColors.gildedLeaf).copyWith(fontSize: 8)),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.hairlineInk, height: 1),
          const SizedBox(height: 16),

          _DetailRow(
            label: 'MORFOCROMIA (CIE L*a*b*)',
            value: item.labColorSpace,
            leadingDotColor: item.dominantColor,
          ),
          _DetailRow(label: 'PROVENIÊNCIA', value: item.brandOrProvenance),
          _DetailRow(label: 'FREQUÊNCIA DE USO', value: '${item.usageRate} combinações no acervo'),
          if (item.isConsciousFashion && item.consciousNote != null)
            _DetailRow(label: 'SUSTENTABILIDADE ESG', value: item.consciousNote!),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCinnabar,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              child: Text(
                'Combinar no Provador Virtual',
                style: AppTypography.uiHeadline(color: AppColors.ivoryText).copyWith(fontSize: 14.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? leadingDotColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.leadingDotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (leadingDotColor != null) ...[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: leadingDotColor,
                border: Border.all(color: AppColors.hairlineInk, width: 0.6),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.atelierMeta(color: AppColors.inkSecondary).copyWith(fontSize: 9.5)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyReading(color: AppColors.inkText).copyWith(fontSize: 13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
