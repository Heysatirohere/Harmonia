import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../mocks/mock_gap_analysis.dart';
import '../../models/affiliated_product.dart';
import '../../models/wardrobe_gap.dart';

/// Modal / Bandeja de Análise de Lacunas do Acervo (Gap Analysis - RF11, RF12 & RN03)
class GapAnalysisSheet extends StatefulWidget {
  final List<WardrobeGap>? customGaps;
  final ScrollController? scrollController;
  final Function(AffiliatedProduct product)? onLaunchAffiliate;

  const GapAnalysisSheet({
    super.key,
    this.customGaps,
    this.scrollController,
    this.onLaunchAffiliate,
  });

  /// Método estático para abrir o modal via showModalBottomSheet
  static Future<void> show(
    BuildContext context, {
    List<WardrobeGap>? customGaps,
    Function(AffiliatedProduct product)? onLaunchAffiliate,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        snap: true,
        builder: (context, scrollController) {
          return GapAnalysisSheet(
            customGaps: customGaps,
            scrollController: scrollController,
            onLaunchAffiliate: onLaunchAffiliate,
          );
        },
      ),
    );
  }

  @override
  State<GapAnalysisSheet> createState() => _GapAnalysisSheetState();
}

class _GapAnalysisSheetState extends State<GapAnalysisSheet> {
  late final List<WardrobeGap> _gaps;

  @override
  void initState() {
    super.initState();
    _gaps = widget.customGaps ?? GapAnalysisMockService.gaps;
  }

  Future<void> _handleLaunchUrl(AffiliatedProduct product) async {
    HapticFeedback.lightImpact();

    if (widget.onLaunchAffiliate != null) {
      widget.onLaunchAffiliate!(product);
      return;
    }

    final uri = Uri.parse(product.affiliateUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showFallbackFeedback(product);
      }
    } catch (_) {
      _showFallbackFeedback(product);
    }
  }

  void _showFallbackFeedback(AffiliatedProduct product) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(Icons.open_in_new_rounded,
                color: product.store.badgeColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Redirecionando para a loja oficial ${product.store.displayName}...',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.surfaceCanvas,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.borderGold, width: 0.8),
        ),
      ),
      child: Column(
        children: [
          // Puxador Indicador
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Conteúdo Rolável da Análise de Lacunas
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // 1. CABEÇALHO EDITORIAL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INTELIGÊNCIA DE ACERVO • DESTRAVE DE LOOKS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.accentTerracotta,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Otimização de Acervo',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.iheGoldLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.borderGold, width: 0.8),
                      ),
                      child: Text(
                        '${_gaps.length} Lacunas Identificadas',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.iheGold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  'Com base na sua cartela Outono Suave e biótipo Ampulheta, identificamos peças faltantes estratégicas que multiplicarão as opções com seu vestuário atual.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 20),

                // 2. LISTA DE CARDS DE LACUNA (GAP CARDS)
                ...List.generate(_gaps.length, (index) {
                  final gap = _gaps[index];
                  return _WardrobeGapCard(
                    gap: gap,
                    onLaunchProduct: _handleLaunchUrl,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card Editorial de Lacuna de Armário com Silhueta Etérea
class _WardrobeGapCard extends StatelessWidget {
  final WardrobeGap gap;
  final Function(AffiliatedProduct product) onLaunchProduct;

  const _WardrobeGapCard({
    required this.gap,
    required this.onLaunchProduct,
  });

  @override
  Widget build(BuildContext context) {
    // ENFORCING RN03: Apenas produtos com estoque disponível (inStock == true)
    final availableProducts = gap.availableProducts;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 0.8,
        ),
        boxShadow: AppColors.editorialShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Silhueta Etérea Pontilhada + Metadados
          Row(
            children: [
              // Silhueta Etérea / Retículo Pontilhado
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceCanvas,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.iheGold.withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                ),
                child: CustomPaint(
                  painter: _EtherealDottedGarmentPainter(),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: AppColors.iheGold,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CATEGORIA RECOMENDADA',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gap.missingCategory,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge de Estimativa do Ganho de IHE (+Δ IHE)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.iheGoldLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.borderGold,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  gap.formattedGain,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iheGold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Justificativa Estilística da IA
          Text(
            gap.rationale,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textPrimary.withValues(alpha: 0.88),
            ),
          ),

          const SizedBox(height: 16),

          // Subtítulo do Carrossel de Afiliação
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sugestões Curadas de Parceiros',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${availableProducts.length} disponíveis',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accentOlive,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Carrossel Horizontal de Produtos Afiliados (RF12 & RN03)
          SizedBox(
            height: 210,
            child: availableProducts.isEmpty
                ? Center(
                    child: Text(
                      'Sem produtos com estoque no momento.',
                      style: AppTypography.metaLabel(),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: availableProducts.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, pIndex) {
                      final product = availableProducts[pIndex];
                      return _AffiliateProductCard(
                        product: product,
                        onTap: () => onLaunchProduct(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Card Individual de Produto Afiliado (C&A e Renner - RF12 & RN03)
class _AffiliateProductCard extends StatelessWidget {
  final AffiliatedProduct product;
  final VoidCallback onTap;

  const _AffiliateProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final store = product.store;

    return Container(
      width: 175,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com Logo/Badge da Loja Parceira + Tag de Paridade
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge da Loja (C&A ou Renner)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: store.badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: store.badgeColor.withValues(alpha: 0.4),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  store.shortName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: store.badgeColor,
                  ),
                ),
              ),

              // Swatch da Paridade Cromática
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: product.dominantColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 0.6,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Nome do Produto
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          // Tag de Paridade Tonal (Plus Jakarta Sans)
          Text(
            product.chromaticParityTag,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppColors.iheGold,
            ),
          ),

          const Spacer(),

          // Preço em Plus Jakarta Sans Semi-Bold
          Text(
            product.formattedPrice,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          // Botão de Redirecionamento de Afiliação (RF12)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: AppColors.accentTerracotta,
                  width: 0.8,
                ),
                backgroundColor: AppColors.surfaceRaised,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Ver na loja',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentTerracotta,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.north_east_rounded,
                    size: 12,
                    color: AppColors.accentTerracotta,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter para a silhueta etérea/pontilhada da peça ausente
class _EtherealDottedGarmentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.iheGold.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Desenho de um retículo sutil pontilhado ao redor
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
