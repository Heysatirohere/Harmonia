import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/store_parity_result.dart';

/// Bandeja Deslizante de Paridade de Provador (RF09)
class StoreParitySheet extends StatefulWidget {
  final StoreParityResult parityResult;
  final ScrollController? scrollController;
  final VoidCallback? onClose;

  const StoreParitySheet({
    super.key,
    required this.parityResult,
    this.scrollController,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required StoreParityResult parityResult,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.40,
        maxChildSize: 0.94,
        snap: true,
        builder: (context, scrollController) {
          return StoreParitySheet(
            parityResult: parityResult,
            scrollController: scrollController,
            onClose: () => Navigator.of(ctx).pop(),
          );
        },
      ),
    );
  }

  @override
  State<StoreParitySheet> createState() => _StoreParitySheetState();
}

class _StoreParitySheetState extends State<StoreParitySheet> {
  int? _selectedMatchIndex;

  void _onMatchCardTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMatchIndex = _selectedMatchIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.parityResult;
    final storeGarment = result.storeGarment;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCanvas.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppColors.borderGold,
              width: 0.8,
            ),
          ),
          child: Column(
            children: [
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
              Expanded(
                child: ListView(
                  controller: widget.scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: storeGarment.dominantColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.borderGold,
                              width: 1.2,
                            ),
                            boxShadow: AppColors.floatingGarmentShadow,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                storeGarment.storeName.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                storeGarment.title,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (storeGarment.price != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  storeGarment.formattedPrice,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accentTerracotta,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              result.formattedOverallScore,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.iheGold,
                              ),
                            ),
                            Text(
                              'Compatibilidade',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (result.isStronglyRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.iheGoldLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.borderGold,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('✦ ',
                                style: TextStyle(
                                    color: AppColors.iheGold, fontSize: 12)),
                            Expanded(
                              child: Text(
                                'PARIDADE CONFIRMADA • PEÇA RECOMENDADA PARA SEU ACERVO',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: AppColors.iheGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),
                    Text(
                      result.editorialSummary,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Harmonia com seu Acervo',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${result.compatibleMatches.length} peças alinhadas',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(result.compatibleMatches.length, (index) {
                      final match = result.compatibleMatches[index];
                      final isSelected = _selectedMatchIndex == index;

                      return _ParityMatchCard(
                        match: match,
                        isSelected: isSelected,
                        onTap: () => _onMatchCardTapped(index),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParityMatchCard extends StatelessWidget {
  final ParityMatchItem match;
  final bool isSelected;
  final VoidCallback onTap;

  const _ParityMatchCard({
    required this.match,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final closetItem = match.closetItem;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surfaceCanvas : AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.iheGold : AppColors.borderSubtle,
          width: isSelected ? 1.2 : 0.8,
        ),
        boxShadow: AppColors.floatingGarmentShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.borderGold,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: closetItem.dominantColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.borderSubtle,
                          width: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            closetItem.category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            closetItem.title,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            closetItem.provenance,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.iheGoldLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.borderGold,
                          width: 0.6,
                        ),
                      ),
                      child: Text(
                        match.formattedPercentage,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.iheGold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  match.matchReason,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.textPrimary.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.borderSubtle,
                        width: 0.6,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MatchDetailStat(
                          label: 'Harmonia Cromática',
                          value: '${(match.chromaticScore * 100).round()}%',
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: AppColors.borderSubtle,
                        ),
                        _MatchDetailStat(
                          label: 'Silhueta & Biótipo',
                          value: '${(match.morphologicalScore * 100).round()}%',
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchDetailStat extends StatelessWidget {
  final String label;
  final String value;

  const _MatchDetailStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.accentTerracotta,
          ),
        ),
      ],
    );
  }
}
