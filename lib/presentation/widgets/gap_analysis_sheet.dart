import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/affiliated_product.dart';
import '../../models/wardrobe_gap.dart';
import '../../theme/app_theme.dart';

/// Conteúdo de uma lacuna sobre a folha paperBone: a peça-chave, os looks que ela
/// destrava (RF11) e onde comprá-la nos parceiros, só com estoque (RF12, RN03)
class GapAnalysisSheet extends StatelessWidget {
  final WardrobeGap gap;

  const GapAnalysisSheet({super.key, required this.gap});

  String get _impact {
    if (gap.strongLooks > 0) {
      return gap.strongLooks == 1 ? '✦ 1 LOOK FORTE' : '✦ ${gap.strongLooks} LOOKS FORTES';
    }
    return 'MELHOR LOOK ${gap.bestIhe.round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final products = gap.availableProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Swatch(color: gap.color, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gap.title, style: AppTypography.editorialTitleMedium()),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(_impact, style: AppTypography.sealLabel()),
                      if (gap.deltaIhe > 0)
                        Text(
                          '+${gap.deltaIhe.toStringAsFixed(1)} PTS NO IHE',
                          style: AppTypography.metadataBadge(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(gap.stylisticRationale, style: AppTypography.bodyReading(color: AppColors.inkSecondary)),
        const SizedBox(height: 18),
        const Divider(color: AppColors.hairlineInk, height: 1),
        const SizedBox(height: 14),
        Text('ONDE ENCONTRAR', style: AppTypography.metadataBadge()),
        const SizedBox(height: 6),
        if (products.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Nenhum parceiro com estoque no momento.',
              style: AppTypography.bodySmall(),
            ),
          )
        else
          for (final product in products) _ProductRow(product: product),
      ],
    );
  }
}

/// Produto de parceiro: amostra da cor, loja e o link de afiliação para a busca na loja
class _ProductRow extends StatelessWidget {
  final AffiliatedProduct product;

  const _ProductRow({required this.product});

  Future<void> _open(BuildContext context) async {
    HapticFeedback.selectionClick();
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(Uri.parse(product.affiliateUrl), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[GapAnalysisSheet] Link de afiliação não abriu: $e');
    }
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.tapestryNoir,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Não foi possível abrir ${product.storeDisplayName}.',
            style: AppTypography.bodyReading(color: AppColors.ivoryText),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _Swatch(color: product.color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.storeDisplayName.toUpperCase(), style: AppTypography.metadataBadge()),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    style: AppTypography.uiHeadline().copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('Ver na loja', style: AppTypography.uiHeadline(color: AppColors.accentCinnabar).copyWith(fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.north_east, size: 14, color: AppColors.accentCinnabar),
          ],
        ),
      ),
    );
  }
}

/// Amostra tonal da cor L*a*b* da peça, com filete para tons claros não sumirem no papel
class _Swatch extends StatelessWidget {
  final Color color;
  final double size;

  const _Swatch({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.hairlineInk, width: 1),
      ),
    );
  }
}
