import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../models/affiliated_product.dart';
import '../../models/wardrobe_gap.dart';

class GapAnalysisSheet extends StatelessWidget {
  final WardrobeGap gap;

  const GapAnalysisSheet({
    super.key,
    required this.gap,
  });

  static Future<void> show(BuildContext context, {required WardrobeGap gap}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCanvas,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.borderGold, width: 0.8),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              GapAnalysisSheet(gap: gap),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAffiliateUrl(BuildContext context, AffiliatedProduct product) async {
    HapticFeedback.mediumImpact();
    final uri = Uri.parse(product.affiliateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.textPrimary,
            content: Text(
              'Redirecionando para ${product.storeDisplayName}...',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // RN03: Strictly use availableProducts which filters out inStock == false items
    final products = gap.availableProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ethereal Silhouette Icon Box
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.borderGold,
                  width: 1.0,
                ),
              ),
              child: const Icon(
                Icons.checkroom_outlined,
                color: AppColors.iheGold,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gap.missingCategory,
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderGold, width: 0.6),
                    ),
                    child: Text(
                      '✦ +${gap.deltaIhe.toStringAsFixed(1)}% NO ÍNDICE DE HARMONIA',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.iheGold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Text(
          gap.stylisticRationale,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'PEÇAS SUGERIDAS DOS PARCEIROS (RN03)',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),

        if (products.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Nenhum item com estoque disponível no momento.',
              style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 12),
            ),
          )
        else
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Container(
                  width: 154,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: SizedBox(
                          height: 95,
                          width: double.infinity,
                          child: Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.surfaceSubtle,
                                child: const Center(
                                  child: Icon(Icons.shopping_bag_outlined, color: AppColors.iheGold, size: 24),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.storeDisplayName,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textMuted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textPrimary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.formattedPrice,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.accentTerracotta,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              height: 26,
                              child: ElevatedButton(
                                onPressed: () => _openAffiliateUrl(context, product),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surfaceCanvas,
                                  foregroundColor: AppColors.textPrimary,
                                  elevation: 0,
                                  side: const BorderSide(color: AppColors.borderSubtle),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  'Ver na Loja',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
