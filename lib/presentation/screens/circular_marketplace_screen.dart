import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/services/wardrobe_api_service.dart';
import '../../domain/repositories/wardrobe_repository.dart';
import '../../models/circular_listing.dart';
import '../../models/clothing_item.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_room.dart';
import '../atelier/atelier_widgets.dart';
import '../atelier/room_scene.dart';

/// Vitrine C2C do Brechó Circular (Economia Circular & ESG — Seção 3.5.4 da Documentação).
///
/// Exibe peças seminovas anunciadas pela comunidade (`disposal_status = SELL`) e pelo
/// próprio usuário, ordenadas pela compatibilidade cromática ($S_{cor}$ CIE $L^*a^*b^*$)
/// com a cartela sazonal do comprador.
class CircularMarketplaceScreen extends StatefulWidget {
  final WardrobeRepository? service;

  /// Peças locais do acervo do usuário (permite refletir anúncios criados offline/em memória).
  final List<ClothingItem> localItems;

  /// Callback disparado quando uma peça do brechó é incorporada ou reativada no acervo.
  final ValueChanged<ClothingItem>? onItemAcquired;

  const CircularMarketplaceScreen({
    super.key,
    this.service,
    this.localItems = const [],
    this.onItemAcquired,
  });

  @override
  State<CircularMarketplaceScreen> createState() => _CircularMarketplaceScreenState();
}

class _CircularMarketplaceScreenState extends State<CircularMarketplaceScreen> {
  late final WardrobeRepository _service = widget.service ?? WardrobeApiService();

  static const List<String> _categories = [
    'Todos',
    'Partes de cima',
    'Partes de baixo',
    'Calçados',
    'Peças únicas',
  ];

  List<CircularListing> _listings = const [];
  bool _isLoading = true;
  String _selectedCategory = 'Todos';
  bool _onlyHighCompatibility = false;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);

    final ownLocalListings = widget.localItems
        .where((item) => item.disposalStatus == 'SELL')
        .map((item) => CircularListing.fromClothingItem(item, isOwnListing: true))
        .toList();

    List<CircularListing> remoteListings = const [];
    try {
      remoteListings = await _service.getCircularMarketplace();
    } catch (_) {
      remoteListings = const [];
    }

    if (!mounted) return;

    final mergedById = <String, CircularListing>{};
    for (final own in ownLocalListings) {
      mergedById[own.itemId] = own;
    }
    for (final item in remoteListings) {
      mergedById.putIfAbsent(item.itemId, () => item);
    }
    if (mergedById.isEmpty) {
      for (final demo in CircularListing.demoListings) {
        mergedById[demo.itemId] = demo;
      }
    } else {
      final hasCommunity = mergedById.values.any((l) => !l.isOwnListing);
      if (!hasCommunity) {
        for (final demo in CircularListing.demoListings) {
          mergedById.putIfAbsent(demo.itemId, () => demo);
        }
      }
    }

    final merged = mergedById.values.toList()
      ..sort((a, b) {
        if (a.isOwnListing != b.isOwnListing) {
          return a.isOwnListing ? -1 : 1;
        }
        return b.paletteCompatibility.compareTo(a.paletteCompatibility);
      });

    setState(() {
      _listings = merged;
      _isLoading = false;
    });
  }

  List<CircularListing> get _filteredListings {
    return _listings.where((item) {
      final matchesCategory = _selectedCategory == 'Todos' || item.category == _selectedCategory;
      final matchesCompatibility = !_onlyHighCompatibility || item.isHighHarmony;
      return matchesCategory && matchesCompatibility;
    }).toList();
  }

  Future<void> _acquireListing(CircularListing listing) async {
    HapticFeedback.mediumImpact();
    final acquiredItem = listing.toClothingItem(disposalStatus: 'ACTIVE');
    ClothingItem saved = acquiredItem;
    try {
      final created = await _service.createClothingItem(acquiredItem);
      if (created != null) {
        saved = created;
      }
    } catch (_) {}

    if (!mounted) return;
    widget.onItemAcquired?.call(saved);
    setState(() {
      _listings = _listings.where((l) => l.itemId != listing.itemId).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Peça "${listing.title}" incorporada ao seu acervo com sucesso.'),
      ),
    );
  }

  Future<void> _withdrawOwnListing(CircularListing listing) async {
    HapticFeedback.selectionClick();
    final reactivated = listing.toClothingItem(disposalStatus: 'ACTIVE');
    try {
      await _service.updateClothingItem(reactivated);
    } catch (_) {}

    if (!mounted) return;
    widget.onItemAcquired?.call(reactivated);
    setState(() {
      _listings = _listings.where((l) => l.itemId != listing.itemId).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Anúncio de "${listing.title}" retirado; peça reativada no acervo.'),
      ),
    );
  }

  void _openDetailSheet(CircularListing listing) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _CircularListingDetailSheet(
          listing: listing,
          onPrimaryAction: () {
            Navigator.of(sheetContext).pop();
            if (listing.isOwnListing) {
              _withdrawOwnListing(listing);
            } else {
              _acquireListing(listing);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredListings;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RoomScene(
        room: AtelierRoom.verdigris,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: RoomHeader(
                room: AtelierRoom.verdigris,
                eyebrow: 'Economia circular & ESG • Seção 3.5.4',
                title: 'Brechó Circular',
                subtitle: 'Peças seminovas compatíveis com sua cartela',
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildCuratorialBanner(),
            ),
            SliverToBoxAdapter(
              child: _buildFiltersRow(),
            ),
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageMargin,
                  AppSpacing.elementGap,
                  AppSpacing.pageMargin,
                  120,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisExtent: 270,
                    mainAxisSpacing: AppSpacing.elementGap,
                    crossAxisSpacing: AppSpacing.elementGap,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const AtelierShimmer(
                      room: AtelierRoom.verdigris,
                      height: 260,
                      borderRadius: AppSpacing.radiusLarge,
                    ),
                    childCount: 4,
                  ),
                ),
              )
            else if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageMargin,
                  AppSpacing.elementGap,
                  AppSpacing.pageMargin,
                  120,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisExtent: 270,
                    mainAxisSpacing: AppSpacing.elementGap,
                    crossAxisSpacing: AppSpacing.elementGap,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final listing = filtered[index];
                      return _CircularListingCard(
                        listing: listing,
                        onTap: () => _openDetailSheet(listing),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuratorialBanner() {
    final ownCount = _listings.where((l) => l.isOwnListing).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageMargin,
        AppSpacing.tightGap,
        AppSpacing.pageMargin,
        AppSpacing.elementGap,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.elementGap),
        decoration: BoxDecoration(
          color: AppColors.ivoryText.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.hairlineIvory),
        ),
        child: Row(
          children: [
            const Icon(Icons.eco_outlined, color: AppColors.gildedLeaf, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURADORIA POR CARTELA CIE L*A*B*',
                    style: AppTypography.metadataBadge(color: AppColors.ivoryText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ownCount > 0
                        ? 'Você possui $ownCount peça(s) anunciada(s) no Brechó Circular além das sugestões da comunidade.'
                        : 'Cada peça é avaliada segundo o ΔE da sua cartela pessoal para evitar compras ociosas.',
                    style: AppTypography.bodyReading(color: AppColors.ivoryMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.tightGap),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final selected = cat == _selectedCategory;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategory = cat);
                },
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.editorialDecel,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.ivoryText : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    border: Border.all(
                      color: selected ? AppColors.ivoryText : AppColors.hairlineIvory,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: AppTypography.uiHeadline(
                      color: selected ? AppColors.inkText : AppColors.ivoryText,
                    ).copyWith(fontSize: 13),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.tightGap),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _onlyHighCompatibility = !_onlyHighCompatibility);
                },
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.editorialDecel,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _onlyHighCompatibility
                        ? AppColors.ivoryText.withValues(alpha: 0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    border: Border.all(
                      color: _onlyHighCompatibility ? AppColors.ivoryText : AppColors.hairlineIvory,
                    ),
                  ),
                  child: Text(
                    '✦ ALTA HARMONIA (≥75%)',
                    style: AppTypography.metadataBadge(
                      color: _onlyHighCompatibility ? AppColors.ivoryText : AppColors.ivoryMuted,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${_filteredListings.length} PEÇAS',
                style: AppTypography.metadataBadge(color: AppColors.ivoryMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pageMargin),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.pageMargin),
        decoration: BoxDecoration(
          color: AppColors.paperBone,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nenhuma peça encontrada neste filtro',
              style: AppTypography.subtitleCuratorial(color: AppColors.inkText),
            ),
            const SizedBox(height: 8),
            Text(
              'Experimente alternar a categoria ou desativar o filtro de alta harmonia para ver todas as peças disponíveis.',
              style: AppTypography.bodyReading(color: AppColors.inkSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularListingCard extends StatelessWidget {
  final CircularListing listing;
  final VoidCallback onTap;

  const _CircularListingCard({
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final swatchColor = listing.dominantColor;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = (180 * dpr).round();
    final cutLabel = listing.cutType ?? 'RETO';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paperBone,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(
            color: listing.isOwnListing ? AppColors.accentCinnabar : AppColors.hairlineInk,
            width: listing.isOwnListing ? 1.4 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: AppColors.paperBoneRaised,
                    child: listing.imageUrl.isNotEmpty
                        ? Image.network(
                            listing.imageUrl,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                            cacheWidth: cacheW,
                            errorBuilder: (_, _, _) => _GarmentSwatchFallback(
                              color: swatchColor,
                              category: listing.category,
                            ),
                          )
                        : _GarmentSwatchFallback(
                            color: swatchColor,
                            category: listing.category,
                          ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: listing.isOwnListing
                            ? AppColors.accentCinnabar
                            : AppColors.tapestryNoir.withValues(alpha: 0.84),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      child: Text(
                        listing.isOwnListing
                            ? 'SEU ANÚNCIO'
                            : '✦ ${listing.compatibilityPercent}% HARMONIA',
                        style: AppTypography.metadataBadge(
                          color: listing.isOwnListing
                              ? AppColors.ivoryText
                              : (listing.isHighHarmony
                                  ? AppColors.gildedLeaf
                                  : AppColors.ivoryText),
                        ).copyWith(fontSize: 9.5),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: swatchColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.ivoryText, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.uiHeadline(color: AppColors.inkText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$cutLabel • ${listing.colorFamily}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyReading(color: AppColors.inkSecondary)
                        .copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        listing.formattedPrice,
                        style: AppTypography.uiHeadline(color: AppColors.accentCinnabar),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          listing.isOwnListing ? 'VOCÊ' : 'C2C',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.metadataBadge(color: AppColors.inkSecondary)
                              .copyWith(fontSize: 9.0, letterSpacing: 0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GarmentSwatchFallback extends StatelessWidget {
  final Color color;
  final String category;

  const _GarmentSwatchFallback({
    required this.color,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.hairlineInk, width: 1.5),
            ),
            child: const Icon(
              Icons.checkroom_outlined,
              color: AppColors.ivoryText,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.toUpperCase(),
            style: AppTypography.metadataBadge(color: AppColors.inkSecondary),
          ),
        ],
      ),
    );
  }
}

class _CircularListingDetailSheet extends StatelessWidget {
  final CircularListing listing;
  final VoidCallback onPrimaryAction;

  const _CircularListingDetailSheet({
    required this.listing,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final swatchColor = listing.dominantColor;
    final cutLabel = listing.cutType ?? 'RETO';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paperBone,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLarge)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageMargin,
        16,
        AppSpacing.pageMargin,
        AppSpacing.pageMargin + 12,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.hairlineInk,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.verdigris,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Text(
                    '✦ ${listing.compatibilityPercent}% COMPATÍVEL COM SUA CARTELA',
                    style: AppTypography.metadataBadge(color: AppColors.ivoryText),
                  ),
                ),
                const Spacer(),
                Text(
                  listing.isOwnListing ? 'SEU ANÚNCIO' : 'C2C VERIFICADO',
                  style: AppTypography.metadataBadge(color: AppColors.inkSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              listing.title,
              style: AppTypography.editorialTitleLarge(color: AppColors.inkText),
            ),
            const SizedBox(height: 4),
            Text(
              '${listing.category} • Corte $cutLabel • Família ${listing.colorFamily}',
              style: AppTypography.bodyReading(color: AppColors.inkSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paperBoneRaised,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: AppColors.hairlineInk),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: swatchColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.hairlineInk),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COORDENADAS CIE L*A*B*',
                          style: AppTypography.metadataBadge(color: AppColors.inkSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          listing.labLabel,
                          style: AppTypography.uiHeadline(color: AppColors.inkText),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    listing.formattedPrice,
                    style: AppTypography.editorialTitleLarge(
                      color: AppColors.accentCinnabar,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CinnabarButton(
              label: listing.isOwnListing
                  ? 'Retirar do Brechó e Reativar'
                  : 'Incorporar ao Meu Acervo',
              icon: listing.isOwnListing
                  ? Icons.undo_rounded
                  : Icons.checkroom_outlined,
              onPressed: onPrimaryAction,
            ),
          ],
        ),
      ),
    );
  }
}
