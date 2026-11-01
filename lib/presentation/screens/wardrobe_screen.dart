import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/demo/demo_mode.dart';
import '../../data/services/wardrobe_api_service.dart';
import '../../mocks/mock_clothes.dart';
import '../../models/clothing_item.dart';
import '../../models/wardrobe_filters.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_widgets.dart';
import '../atelier/atelier_room.dart';
import '../atelier/room_scene.dart';
import '../widgets/clothing_card.dart';
import '../widgets/editorial_form.dart';
import '../widgets/filter_chips_bar.dart';
import '../widgets/wardrobe_filter_sheet.dart';
import 'circular_marketplace_screen.dart';
import 'daily_outfit_screen.dart';
import 'scan_item_screen.dart';
import 'wardrobe_analytics_screen.dart';

/// Tela do Guarda-Roupa / Inventário Virtual ("The Floating Canvas")
/// Conforme AGENTS.md (Renascença do Ateliê):
/// - Cada categoria é uma seção com sua própria Sala; o fundo se dissolve entre elas no scroll
/// - Com um filtro ativo, a tela inteira dissolve para a Sala da categoria
/// - Peças flutuam direto sobre a cenografia; detalhes abrem numa folha paperBone
class WardrobeScreen extends StatefulWidget {
  final WardrobeApiService? service;

  const WardrobeScreen({super.key, this.service});

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
  late final WardrobeApiService _wardrobeService = widget.service ?? WardrobeApiService();
  List<ClothingItem> _items = const [];
  bool _loading = true;
  String? _loadError;
  int _selectedFilterIndex = 0;

  /// Cor, formalidade, frequência de uso, estação e cápsula (RF06), aplicados sobre as peças carregadas
  WardrobeFilters _filters = WardrobeFilters.none;

  /// Bancada de montagem magnética de look na arara (AGENTS.md 7.1)
  bool _composerOpen = false;
  final Map<String, ClothingItem> _composedSlots = {};

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
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final items = await _wardrobeService.getClothingItems();
      if (mounted) setState(() => _items = items.isEmpty && kDemoMode ? mockClothes : items);
    } on WardrobeException catch (e) {
      if (!mounted) return;
      setState(() {
        if (kDemoMode) {
          _items = mockClothes;
        } else {
          _loadError = e.message;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? get _selectedCategory => _selectedFilterIndex == 0 ? null : _categories[_selectedFilterIndex];

  /// Peças agrupadas por categoria, na ordem dos filtros e depois as demais
  List<(String, List<ClothingItem>)> get _sections {
    final selected = _selectedCategory;
    final groups = <String, List<ClothingItem>>{};
    for (final item in _items) {
      if (selected != null && item.category != selected) continue;
      if (!_filters.matches(item)) continue;
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
      builder: (ctx) => _GarmentDetailSheet(
        item: item,
        service: _wardrobeService,
        onItemUpdated: (updated) {
          setState(() {
            final idx = _items.indexWhere((i) => i.id == updated.id);
            if (idx != -1) {
              final copy = List<ClothingItem>.from(_items);
              copy[idx] = updated;
              _items = copy;
            }
          });
        },
        onItemDeleted: (deleted) {
          setState(() {
            _items = _items.where((i) => i.id != deleted.id).toList();
          });
        },
      ),
    );
  }

  Future<void> _openScanner() async {
    HapticFeedback.mediumImpact();
    final newItem = await Navigator.push<ClothingItem>(
      context,
      MaterialPageRoute(
        builder: (context) => ScanItemScreen(
          // A peça já foi salva pelo ScanItemScreen
          onItemCataloged: (item) => setState(() => _items = [item, ..._items]),
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
            if (_items.isNotEmpty) SliverToBoxAdapter(child: _buildRefineRow()),
            if (_composerOpen) SliverToBoxAdapter(child: _buildLookComposerTray()),
            if (_loading && _items.isEmpty)
              const SliverToBoxAdapter(child: SizedBox.shrink())
            else if (sections.isEmpty)
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
                        final card = ClothingCard(item: item, onTap: () => _onItemTap(item));
                        return LongPressDraggable<ClothingItem>(
                          data: item,
                          onDragStarted: () {
                            HapticFeedback.selectionClick();
                            if (!_composerOpen) setState(() => _composerOpen = true);
                          },
                          feedback: Material(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: 120,
                              height: 160,
                              child: Opacity(opacity: 0.9, child: card),
                            ),
                          ),
                          childWhenDragging: Opacity(opacity: 0.35, child: card),
                          child: card,
                        );
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
    if (_items.isEmpty) return const SizedBox.shrink();

    final totalItems = _items.length;
    final esgCount = _items.where((i) => i.isConsciousFashion).length;
    final scored = _items.map((i) => i.iheScore).whereType<int>().toList();
    final averageIhe = scored.isEmpty ? null : (scored.reduce((a, b) => a + b) / scored.length).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WardrobeAnalyticsScreen(service: _wardrobeService)),
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.ivoryVeil,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: AppColors.hairlineGold, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: AppColors.gildedVeil, shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome, size: 13, color: AppColors.gildedLeaf),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalItems PEÇAS',
                        style: AppTypography.uiHeadline(
                          color: AppColors.ivoryText,
                        ).copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      const Text('•', style: TextStyle(color: AppColors.hairlineIvory)),
                      const SizedBox(width: 6),
                      Text(
                        averageIhe == null ? 'IHE —' : 'IHE MÉDIO $averageIhe%',
                        style: AppTypography.uiHeadline(
                          color: AppColors.gildedLeaf,
                        ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      if (esgCount > 0) ...[
                        const SizedBox(width: 6),
                        const Text('•', style: TextStyle(color: AppColors.hairlineIvory)),
                        const SizedBox(width: 6),
                        Text(
                          '$esgCount ESG',
                          style: AppTypography.uiHeadline(color: AppColors.verdigrisLight).copyWith(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('SAÚDE →', style: AppTypography.atelierMeta(color: AppColors.ivoryText).copyWith(fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }

  void _openFilters() {
    HapticFeedback.selectionClick();
    WardrobeFilterSheet.show(
      context,
      items: _items,
      filters: _filters,
      onChanged: (filters) => setState(() => _filters = filters),
    );
  }

  void _openCircularMarketplace() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CircularMarketplaceScreen(
          service: _wardrobeService,
          localItems: _items,
          onItemAcquired: (acquired) {
            if (!mounted) return;
            setState(() {
              final idx = _items.indexWhere((i) => i.id == acquired.id);
              if (idx != -1) {
                _items[idx] = acquired;
              } else {
                _items.insert(0, acquired);
              }
            });
          },
        ),
      ),
    );
  }

  /// Refinar por cor, formalidade e uso (RF06); com filtro ativo, mostra quantos e permite limpar
  Widget _buildRefineRow() {
    final active = _filters.activeCount;
    Widget action(String label, IconData? icon, VoidCallback onTap) => Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: AppColors.ivoryText),
                    const SizedBox(width: 6),
                  ],
                  Text(label, style: AppTypography.atelierMeta(color: AppColors.ivoryText)),
                ],
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin, 4, AppSpacing.pageMargin, 0),
      child: Wrap(
        spacing: 12,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          action(active == 0 ? 'REFINAR' : 'REFINAR • $active', Icons.tune, _openFilters),
          action(
            _composerOpen ? 'FECHAR ARARA' : 'MONTAR LOOK',
            Icons.dry_cleaning_outlined,
            () {
              HapticFeedback.selectionClick();
              setState(() => _composerOpen = !_composerOpen);
            },
          ),
          action('BRECHÓ CIRCULAR', Icons.eco_outlined, _openCircularMarketplace),
          if (active > 0)
            action('LIMPAR FILTROS', null, () {
              HapticFeedback.selectionClick();
              setState(() => _filters = WardrobeFilters.none);
            }),
        ],
      ),
    );
  }

  void _snapItemToComposer(ClothingItem item) {
    // Encaixe magnético na arara (AGENTS.md 7.1)
    HapticFeedback.selectionClick();
    setState(() {
      _composerOpen = true;
      _composedSlots[item.category] = item;
    });
  }

  int get _composedIheScore {
    if (_composedSlots.isEmpty) return 0;
    final scores = _composedSlots.values.map((i) => i.iheScore ?? 84).toList();
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }

  void _approveComposedLook() {
    if (_composedSlots.isEmpty) return;
    // Finalização ou aprovação de look aciona HapticFeedback.mediumImpact() (AGENTS.md 7.1)
    HapticFeedback.mediumImpact();
    final score = _composedIheScore;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.tapestryNoir,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Look autoral aprovado com IHE $score% (${_composedSlots.length} peças).',
          style: AppTypography.bodySmall(color: AppColors.ivoryText),
        ),
      ),
    );
  }

  Widget _buildLookComposerTray() {
    const slotCategories = ['Partes de cima', 'Partes de baixo', 'Calçados'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin, 8, AppSpacing.pageMargin, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.ivoryVeil,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(color: AppColors.hairlineGold, width: 0.9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'ARARA MAGNÉTICA • ARRASTE PEÇAS',
                  style: AppTypography.atelierMeta(color: AppColors.gildedLeaf),
                ),
                const Spacer(),
                if (_composedSlots.isNotEmpty)
                  Text(
                    'IHE $_composedIheScore%',
                    style: AppTypography.uiHeadline(color: AppColors.ivoryText),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final slot in slotCategories)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: DragTarget<ClothingItem>(
                        onWillAcceptWithDetails: (details) {
                          HapticFeedback.selectionClick();
                          return true;
                        },
                        onAcceptWithDetails: (details) => _snapItemToComposer(details.data),
                        builder: (context, candidateData, rejectedData) {
                          final assigned = _composedSlots[slot];
                          final hovering = candidateData.isNotEmpty;
                          return AnimatedScale(
                            scale: hovering ? 1.05 : (assigned != null ? 1.0 : 0.96),
                            duration: AppMotion.medium,
                            curve: AppMotion.theatricalGesture,
                            child: GestureDetector(
                              onTap: assigned != null
                                  ? () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _composedSlots.remove(slot));
                                    }
                                  : null,
                              child: Container(
                                height: 78,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.tapestryNoir.withValues(alpha: hovering ? 0.55 : 0.32),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                  border: Border.all(
                                    color: assigned != null || hovering
                                        ? AppColors.gildedLeaf
                                        : AppColors.hairlineIvory,
                                    width: assigned != null || hovering ? 1.2 : 0.8,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (assigned != null) ...[
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: assigned.dominantColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.hairlineIvory, width: 0.8),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        assigned.name,
                                        style: AppTypography.bodySmall(color: AppColors.ivoryText)
                                            .copyWith(fontSize: 10.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ] else ...[
                                      const Icon(Icons.add_rounded, size: 16, color: AppColors.ivoryMuted),
                                      const SizedBox(height: 4),
                                      Text(
                                        slot,
                                        style: AppTypography.atelierMeta(color: AppColors.ivoryMuted)
                                            .copyWith(fontSize: 8.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
            if (_composedSlots.isNotEmpty) ...[
              const SizedBox(height: 12),
              CinnabarButton(
                label: 'Aprovar Look Montado',
                icon: Icons.check_circle_outline,
                onPressed: _approveComposedLook,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final error = _loadError;
    final (title, message) = switch ((error, _items.isEmpty)) {
      (final String error, _) => ('O acervo não respondeu', error),
      (null, true) => ('Sua arara está vazia', 'Digitalize a primeira peça para começar a montar looks.'),
      (null, false) when !_filters.isEmpty => (
          'Nenhuma peça com esses filtros',
          'Ajuste ou limpe os filtros de cor, formalidade e uso para ver mais peças.',
        ),
      (null, false) => ('Nenhuma peça nesta categoria', 'Digitalize novas peças em 1 toque para expandir sua arara virtual.'),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              error != null ? Icons.cloud_off_outlined : Icons.dry_cleaning_outlined,
              size: 44,
              color: AppColors.ivoryMuted,
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.subtitleCuratorial(color: AppColors.ivoryText)),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodySmall(color: AppColors.ivoryMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (error != null)
              RoomIconButton(icon: Icons.refresh, label: 'Tentar de novo', onTap: _loadItems)
            else if (_items.isEmpty)
              CinnabarButton(label: 'Digitalizar peça', icon: Icons.photo_camera_outlined, onPressed: _openScanner),
            if (kDemoMode) ...[
              const SizedBox(height: 12),
              EditorialButton(
                label: 'Carregar Coleção do Ateliê (8 Peças)',
                tone: EditorialButtonTone.outline,
                onPressed: () {
                  setState(() {
                    _items = mockClothes;
                    _loadError = null;
                  });
                },
              ),
            ],
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

/// Folha de leitura (paperBone) com os detalhes morfocromáticos da peça (AGENTS.md 7.5, RF05, 3.2.3)
class _GarmentDetailSheet extends StatefulWidget {
  final ClothingItem item;
  final WardrobeApiService service;
  final ValueChanged<ClothingItem>? onItemUpdated;
  final ValueChanged<ClothingItem>? onItemDeleted;

  const _GarmentDetailSheet({
    required this.item,
    required this.service,
    this.onItemUpdated,
    this.onItemDeleted,
  });

  @override
  State<_GarmentDetailSheet> createState() => _GarmentDetailSheetState();
}

class _GarmentDetailSheetState extends State<_GarmentDetailSheet> {
  late ClothingItem _item = widget.item;

  Future<void> _openEditSheet() async {
    HapticFeedback.selectionClick();
    final updated = await showModalBottomSheet<ClothingItem>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _EditGarmentSheet(item: _item, service: widget.service),
    );
    if (updated != null && mounted) {
      setState(() => _item = updated);
      widget.onItemUpdated?.call(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.tapestryNoir,
          behavior: SnackBarBehavior.floating,
          content: Text('Atributos da peça atualizados.', style: AppTypography.bodySmall(color: AppColors.ivoryText)),
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    HapticFeedback.selectionClick();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.tapestryNoir.withValues(alpha: 0.6),
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paperBone,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLarge)),
        title: Text('Excluir Peça', style: AppTypography.displayEditorial().copyWith(fontSize: 22)),
        content: Text(
          'Deseja remover "${_item.name}" do seu acervo? A foto será apagada do armazenamento e a peça não aparecerá mais nas combinações (RN04).',
          style: AppTypography.bodyReading(color: AppColors.inkText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: AppTypography.uiHeadline(color: AppColors.inkSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCinnabar,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSmall)),
            ),
            child: Text('Excluir', style: AppTypography.uiHeadline(color: AppColors.ivoryText)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      HapticFeedback.heavyImpact();
      final success = await widget.service.deleteClothingItem(_item.id);
      if (!mounted) return;
      if (success) {
        widget.onItemDeleted?.call(_item);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.tapestryNoir,
            behavior: SnackBarBehavior.floating,
            content: Text('Peça removida do acervo.', style: AppTypography.bodySmall(color: AppColors.ivoryText)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.tapestryNoir,
            behavior: SnackBarBehavior.floating,
            content: Text('Não foi possível excluir a peça agora.', style: AppTypography.bodySmall(color: AppColors.ivoryText)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;

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
          _DetailRow(
            label: 'FREQUÊNCIA DE USO',
            value: item.formattedCostPerUse != null
                ? '${item.usageRate} combinações • ${item.formattedCostPerUse}'
                : '${item.usageRate} combinações no acervo',
          ),
          if (item.season != null && item.season!.isNotEmpty)
            _DetailRow(label: 'ESTAÇÃO', value: item.season!),
          if (item.capsules.isNotEmpty)
            _DetailRow(label: 'COLEÇÃO CÁPSULA', value: item.capsules.join(' • ')),
          if (item.disposalStatus != null && item.disposalStatus != 'ACTIVE')
            _DetailRow(label: 'DESTINAÇÃO ESG', value: _disposalLabel(item.disposalStatus!)),
          if (item.isConsciousFashion && item.consciousNote != null)
            _DetailRow(label: 'SUSTENTABILIDADE ESG', value: item.consciousNote!),

          const SizedBox(height: 16),

          // Botões de Ação: Editar Atributos e Excluir
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openEditSheet,
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.inkText),
                  label: Text('Editar Atributos', style: AppTypography.uiHeadline(color: AppColors.inkText).copyWith(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.hairlineInk, width: 1.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMedium)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.accentCinnabar, size: 22),
                tooltip: 'Excluir peça',
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    side: const BorderSide(color: AppColors.hairlineInk, width: 1.0),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          CinnabarButton(
            label: 'Combinar no Provador Virtual',
            icon: Icons.auto_awesome_outlined,
            onPressed: () {
              final nav = Navigator.of(context);
              nav.pop();
              nav.push(
                MaterialPageRoute(
                  builder: (_) => DailyOutfitScreen(anchorItem: item),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _disposalLabel(String status) => switch (status) {
        'DONATE' || 'DONATED' => 'Separada para Doação',
        'SELL' => 'Separada para Brechó / Venda',
        'RECYCLE' || 'DISCARDED' => 'Separada para Reciclagem Têxtil',
        _ => 'Ativa no Acervo',
      };
}

/// Folha de edição de metadados da peça (Seção 3.2.3 da Documentação)
class _EditGarmentSheet extends StatefulWidget {
  final ClothingItem item;
  final WardrobeApiService service;

  const _EditGarmentSheet({required this.item, required this.service});

  @override
  State<_EditGarmentSheet> createState() => _EditGarmentSheetState();
}

class _EditGarmentSheetState extends State<_EditGarmentSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late String _selectedCategory;
  late double _formality;
  late String _selectedSeason;
  late String _selectedDisposal;
  late Set<String> _selectedCapsules;
  bool _saving = false;

  static const _availableCategories = [
    'Partes de cima',
    'Partes de baixo',
    'Calçados',
    'Peças únicas',
  ];

  static const _availableSeasons = [
    'Todas',
    'Verão',
    'Meia-estação',
    'Inverno',
  ];

  static const _availableCapsules = [
    'Trabalho',
    'Viagem',
    'Festa',
    'Minimal',
  ];

  static const _disposalOptions = [
    ('ACTIVE', 'No acervo'),
    ('DONATE', 'Doar'),
    ('SELL', 'Brechó'),
    ('RECYCLE', 'Reciclar'),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _priceController = TextEditingController(
      text: widget.item.price != null ? widget.item.price!.toStringAsFixed(2) : '',
    );
    _selectedCategory = widget.item.category;
    if (!_availableCategories.contains(_selectedCategory)) {
      _selectedCategory = _availableCategories.first;
    }
    _formality = widget.item.formalityScore ?? 0.5;
    _selectedSeason = widget.item.season ?? 'Todas';
    if (!_availableSeasons.contains(_selectedSeason)) {
      _selectedSeason = 'Todas';
    }
    _selectedDisposal = widget.item.disposalStatus ?? 'ACTIVE';
    _selectedCapsules = {...widget.item.capsules};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final parsedPrice = double.tryParse(_priceController.text.trim().replaceAll(',', '.'));

    final updated = widget.item.copyWith(
      name: name,
      category: _selectedCategory,
      formalityScore: _formality,
      price: parsedPrice,
      season: _selectedSeason,
      disposalStatus: _selectedDisposal,
      capsules: _selectedCapsules.toList(),
    );

    final saved = await widget.service.updateClothingItem(updated);
    if (!mounted) return;
    setState(() => _saving = false);

    // Falhou: a folha continua aberta com o que foi digitado, para tentar de novo
    if (saved == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.tapestryNoir,
          behavior: SnackBarBehavior.floating,
          content: Text('Não foi possível salvar a peça agora.', style: AppTypography.bodySmall(color: AppColors.ivoryText)),
        ),
      );
      return;
    }
    Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paperBone,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLarge)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
              const SizedBox(height: 18),
              Text(
                'EDITAR ATRIBUTOS',
                style: AppTypography.atelierMeta(color: AppColors.accentCinnabar),
              ),
              const SizedBox(height: 4),
              Text(
                'Ajuste Fino de Metadados',
                style: AppTypography.displayEditorial(color: AppColors.inkText).copyWith(fontSize: 24),
              ),
              const SizedBox(height: 20),

              // Nome da Peça
              Text('NOME DA PEÇA', style: AppTypography.atelierMeta(color: AppColors.inkSecondary).copyWith(fontSize: 9.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: AppTypography.bodyReading(color: AppColors.inkText),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.paperBoneRaised,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.hairlineInk),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.hairlineInk),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.accentCinnabar, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Preço de Compra (para Custo por Uso - Seção 3.2.2)
              Text('VALOR DE AQUISIÇÃO (R\$)', style: AppTypography.atelierMeta(color: AppColors.inkSecondary).copyWith(fontSize: 9.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTypography.bodyReading(color: AppColors.inkText),
                decoration: InputDecoration(
                  hintText: 'Ex: 280.00',
                  hintStyle: AppTypography.bodySmall(color: AppColors.inkSecondary),
                  filled: true,
                  fillColor: AppColors.paperBoneRaised,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.hairlineInk),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.hairlineInk),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.accentCinnabar, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Categoria
              Text('CATEGORIA', style: AppTypography.atelierMeta(color: AppColors.inkSecondary).copyWith(fontSize: 9.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableCategories.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  return ChoiceChip(
                    label: Text(
                      cat,
                      style: AppTypography.atelierMeta(
                        color: isSelected ? AppColors.ivoryText : AppColors.inkText,
                      ).copyWith(fontSize: 10),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.accentCinnabar,
                    backgroundColor: AppColors.paperBoneRaised,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      side: BorderSide(
                        color: isSelected ? AppColors.accentCinnabar : AppColors.hairlineInk,
                        width: 0.8,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = cat);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Estação
              Text('ESTAÇÃO', style: AppTypography.atelierMeta(color: AppColors.inkSecondary).copyWith(fontSize: 9.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSeasons.map((season) {
                  final isSelected = season == _selectedSeason;
                  return ChoiceChip(
                    label: Text(
                      season,
                      style: AppTypography.atelierMeta(
                        color: isSelected ? AppColors.ivoryText : AppColors.inkText,
                      ).copyWith(fontSize: 10),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.accentCinnabar,
                    backgroundColor: AppColors.paperBoneRaised,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      side: BorderSide(
                        color: isSelected ? AppColors.accentCinnabar : AppColors.hairlineInk,
                        width: 0.8,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedSeason = season);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Coleções Cápsula
              Text('COLEÇÕES CÁPSULA', style: AppTypography.atelierMeta(color: AppColors.inkSecondary).copyWith(fontSize: 9.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableCapsules.map((cap) {
                  final isSelected = _selectedCapsules.contains(cap);
                  return FilterChip(
                    label: Text(
                      cap,
                      style: AppTypography.atelierMeta(
                        color: isSelected ? AppColors.ivoryText : AppColors.inkText,
                      ).copyWith(fontSize: 10),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.accentCinnabar,
                    backgroundColor: AppColors.paperBoneRaised,
                    checkmarkColor: AppColors.ivoryText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      side: BorderSide(
                        color: isSelected ? AppColors.accentCinnabar : AppColors.hairlineInk,
                        width: 0.8,
                      ),
                    ),
                    onSelected: (selected) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (selected) {
                          _selectedCapsules.add(cap);
                        } else {
                          _selectedCapsules.remove(cap);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Destinação Consciente ESG (Seção 3.2.2)
              Text('DESTINAÇÃO CONSCIENTE (ESG)', style: AppTypography.atelierMeta(color: AppColors.inkSecondary).copyWith(fontSize: 9.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _disposalOptions.map((entry) {
                  final (code, label) = entry;
                  final isSelected = code == _selectedDisposal;
                  return ChoiceChip(
                    label: Text(
                      label,
                      style: AppTypography.atelierMeta(
                        color: isSelected ? AppColors.ivoryText : AppColors.inkText,
                      ).copyWith(fontSize: 10),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.verdigrisInk,
                    backgroundColor: AppColors.paperBoneRaised,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      side: BorderSide(
                        color: isSelected ? AppColors.verdigrisInk : AppColors.hairlineInk,
                        width: 0.8,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedDisposal = code);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Nível de Formalidade
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('NÍVEL DE FORMALIDADE', style: AppTypography.atelierMeta(color: AppColors.inkSecondary).copyWith(fontSize: 9.5)),
                  Text(
                    '${(_formality * 100).round()}% • ${_formalityLabel(_formality)}',
                    style: AppTypography.atelierMeta(color: AppColors.gildedInk).copyWith(fontSize: 10),
                  ),
                ],
              ),
              Slider(
                value: _formality,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                activeColor: AppColors.accentCinnabar,
                inactiveColor: AppColors.hairlineInk,
                onChanged: (val) {
                  setState(() => _formality = val);
                },
              ),
              const SizedBox(height: 24),

              // Botões (sem CircularProgressIndicator cru - AGENTS.md Seção 2)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.hairlineInk),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMedium)),
                      ),
                      child: Text('Cancelar', style: AppTypography.uiHeadline(color: AppColors.inkSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CinnabarButton(
                      label: 'Salvar',
                      busy: _saving,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formalityLabel(double value) {
    if (value <= 0.25) return 'Muito Casual';
    if (value <= 0.50) return 'Casual Chic';
    if (value <= 0.75) return 'Trabalho / Semi-formal';
    return 'Gala / Alta Formalidade';
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
