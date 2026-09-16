import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../mocks/mock_clothes.dart';
import '../../models/clothing_item.dart';
import '../../theme/app_theme.dart';
import '../widgets/clothing_card.dart';
import '../widgets/filter_chips_bar.dart';
import 'scan_item_screen.dart';

/// Tela do Guarda-Roupa / Inventário Virtual ("The Floating Canvas")
/// Conforme AGENTS.md:
/// - Fundo creme quente (#FBF9F5)
/// - Cabeçalho editorial assimétrico com Playfair Display
/// - Grid de silhuetas com respiração ampla e profundidade tátil
/// - Filtros de categoria minimalistas e métricas do acervo
class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _categories = const [
    'Todos',
    'Partes de cima',
    'Partes de baixo',
    'Calçados',
    'Ocasião',
  ];

  List<ClothingItem> get _filteredItems {
    if (_selectedFilterIndex == 0) return mockClothes;
    final categoryName = _categories[_selectedFilterIndex];
    return mockClothes.where((item) => item.category == categoryName).toList();
  }

  void _onItemTap(ClothingItem item) {
    HapticFeedback.selectionClick();
    _showGarmentDetailsSheet(context, item);
  }

  void _showGarmentDetailsSheet(BuildContext context, ClothingItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _GarmentDetailModal(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Cabeçalho Editorial Assimétrico
            SliverToBoxAdapter(
              child: _buildEditorialHeader(context),
            ),

            // Métricas Curatoriais do Acervo
            SliverToBoxAdapter(
              child: _buildAcervoMetrics(context),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),

            // Barra de Filtros Minimalista
            SliverToBoxAdapter(
              child: FilterChipsBar(
                categories: _categories,
                selectedIndex: _selectedFilterIndex,
                onCategorySelected: (index) {
                  setState(() => _selectedFilterIndex = index);
                },
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),

            // Grid de Peças Recortadas ("Floating Canvas")
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.elementGap,
                    crossAxisSpacing: AppSpacing.elementGap,
                    childAspectRatio: 0.70, // Proporção editorial harmônica
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filtered[index];
                      return ClothingCard(
                        item: item,
                        onTap: () => _onItemTap(item),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 48),
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
        MediaQuery.of(context).padding.top + 20,
        AppSpacing.pageMargin,
        12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HarmonIA',
                style: AppTypography.displayEditorial().copyWith(
                  fontSize: 34,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'GUARDA-ROUPA • THE FLOATING CANVAS',
                style: AppTypography.metadataBadge(
                  color: AppColors.accentTerracotta,
                ).copyWith(fontSize: 10, letterSpacing: 1.4),
              ),
            ],
          ),

          // Botão Autoral Curatorial (Digitalizar Peça em 1 toque)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                HapticFeedback.mediumImpact();
                final newItem = await Navigator.push<ClothingItem>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScanItemScreen(
                      onItemCataloged: (item) {
                        setState(() {
                          mockClothes.insert(0, item);
                        });
                      },
                    ),
                  ),
                );
                if (newItem != null && mounted) {
                  setState(() {});
                }
              },
              borderRadius: BorderRadius.circular(24),
              splashColor: AppColors.accentTerracotta.withValues(alpha: 0.1),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 0.8,
                  ),
                  boxShadow: AppColors.editorialShadow,
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcervoMetrics(BuildContext context) {
    final totalItems = mockClothes.length;
    final esgCount = mockClothes.where((i) => i.isConsciousFashion).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 0.6,
          ),
        ),
        child: Row(
          children: [
            _MetricItem(
              label: 'ACERVO TOTAL',
              value: '$totalItems peças',
            ),
            Container(
              width: 0.8,
              height: 24,
              color: AppColors.borderSubtle,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            _MetricItem(
              label: 'HARMONIA MÉDIA',
              value: '89% IHE',
              highlightColor: AppColors.iheGold,
            ),
            Container(
              width: 0.8,
              height: 24,
              color: AppColors.borderSubtle,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            _MetricItem(
              label: 'MODA CIRCULAR',
              value: '$esgCount sustentáveis',
              highlightColor: AppColors.accentOlive,
            ),
          ],
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
            const Icon(
              Icons.dry_cleaning_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma peça nesta categoria',
              style: AppTypography.subtitleCuratorial(),
            ),
            const SizedBox(height: 8),
            Text(
              'Digitalize novas peças em 1 toque para expandir sua arara virtual.',
              style: AppTypography.bodySmall(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? highlightColor;

  const _MetricItem({
    required this.label,
    required this.value,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.metadataBadge(
              color: AppColors.textSecondary,
            ).copyWith(fontSize: 8.5, letterSpacing: 0.6),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.uiHeadline(
              color: highlightColor ?? AppColors.textPrimary,
            ).copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Modal de Detalhes da Peça com Curadoria Morfocromática (CIE L*a*b*)
class _GarmentDetailModal extends StatelessWidget {
  final ClothingItem item;

  const _GarmentDetailModal({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 32,
            offset: Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Puxador sutil
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.accentSand,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Peça em Destaque no Modal (PNG Alfa sem sombra de caixa)
          Center(
            child: Container(
              height: 180,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                border: Border.all(color: AppColors.borderSubtle, width: 0.8),
              ),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Nome & Categoria
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category.toUpperCase(),
                      style: AppTypography.metadataBadge(
                        color: AppColors.accentTerracotta,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      style: AppTypography.displayEditorial().copyWith(fontSize: 22),
                    ),
                  ],
                ),
              ),
              if (item.iheScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.iheGoldLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGold, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${item.iheScore}%',
                        style: AppTypography.displayEditorial(color: AppColors.iheGold)
                            .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'IHE SCORE',
                        style: AppTypography.metadataBadge(color: AppColors.iheGold)
                            .copyWith(fontSize: 8),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 16),

          // Detalhes Técnicos & Morfocromáticos (CIE L*a*b*)
          _DetailRow(
            label: 'Morfocromia (CIE L*a*b*)',
            value: item.labColorSpace,
            leadingDotColor: item.dominantColor,
          ),
          _DetailRow(
            label: 'Proveniência',
            value: item.brandOrProvenance,
          ),
          _DetailRow(
            label: 'Frequência de Uso',
            value: '${item.usageRate} combinações no acervo',
          ),
          if (item.isConsciousFashion && item.consciousNote != null)
            _DetailRow(
              label: 'Sustentabilidade ESG',
              value: item.consciousNote!,
              highlightColor: AppColors.accentOlive,
            ),

          const SizedBox(height: 24),

          // Ação Primária em Estilo Terracota
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTerracotta,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              child: Text(
                'Combinar no Provador Virtual',
                style: AppTypography.uiHeadline(color: AppColors.surfaceCanvas).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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
  final Color? highlightColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.leadingDotColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (leadingDotColor != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: leadingDotColor,
                border: Border.all(color: AppColors.borderSubtle, width: 0.6),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.metadataBadge(color: AppColors.textSecondary)
                      .copyWith(fontSize: 9.5),
                ),
                Text(
                  value,
                  style: AppTypography.bodyReading(
                    color: highlightColor ?? AppColors.textPrimary,
                  ).copyWith(fontSize: 12.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
