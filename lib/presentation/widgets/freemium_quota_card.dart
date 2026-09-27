import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_profile.dart';

class FreemiumQuotaCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onUpgradeTap;

  const FreemiumQuotaCard({
    super.key,
    required this.profile,
    this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasHitLimit = profile.isPiecesQuotaReached || profile.isDailyLooksQuotaReached;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SAÚDE DA ASSINATURA (RN02)',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: profile.isPremium
                      ? AppColors.surfaceRaised
                      : AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: profile.isPremium ? AppColors.borderGold : AppColors.borderSubtle,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  profile.isPremium ? '✦ PLANO PREMIUM' : 'PLANO FREEMIUM',
                  style: GoogleFonts.plusJakartaSans(
                    color: profile.isPremium ? AppColors.iheGold : AppColors.textSecondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Piece quota metric
          _buildThinRulerMetric(
            label: 'Acervo Cadastrado',
            current: profile.registeredPiecesCount,
            max: profile.maxPiecesQuota,
            unit: 'peças',
            ratio: profile.piecesRatio,
            isWarning: profile.isPiecesQuotaReached,
          ),
          const SizedBox(height: 14),

          // Daily looks metric
          _buildThinRulerMetric(
            label: 'Combinações Diárias por IA',
            current: profile.dailyLooksGeneratedCount,
            max: profile.maxDailyLooksQuota,
            unit: 'looks hoje',
            ratio: profile.dailyLooksRatio,
            isWarning: profile.isDailyLooksQuotaReached,
          ),

          if (hasHitLimit && !profile.isPremium) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentTerracotta.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accentTerracotta.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_clock_outlined,
                    color: AppColors.accentTerracotta,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Limite da Cota Gratuita Atingido',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.accentTerracotta,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Desbloqueie peças e gerações ilimitadas com a assinatura HarmonIA Ateliê.',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onUpgradeTap?.call();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentTerracotta,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Upgrade',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThinRulerMetric({
    required String label,
    required int current,
    required int max,
    required String unit,
    required double ratio,
    required bool isWarning,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$current / $max $unit',
              style: GoogleFonts.plusJakartaSans(
                color: isWarning ? AppColors.accentTerracotta : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isWarning ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Ultra-thin 2.5px typographic ruler
        Container(
          height: 2.5,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  decoration: BoxDecoration(
                    color: isWarning
                        ? AppColors.accentTerracotta
                        : AppColors.iheGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
