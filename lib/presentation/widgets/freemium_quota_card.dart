import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_profile.dart';

/// Card Monitor de Cota Freemium & Assinatura (RN02)
///
/// Apresenta indicadores lineares ultra-finos (régua tipográfica elegante) para
/// o limite de peças (30) e combinações IA (5/dia), exibindo alerta de upgrade em terracota suave.
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
    final hasReachedLimit = profile.hasReachedAnyFreemiumLimit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasReachedLimit ? AppColors.accentTerracotta : AppColors.borderGold,
          width: hasReachedLimit ? 1.2 : 0.8,
        ),
        boxShadow: AppColors.editorialShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da Cota
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PLANO & GOVERNANÇA • RN02',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.isPremium ? 'Plano Premium' : 'Plano Freemium',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: profile.isPremium
                      ? AppColors.accentOlive.withValues(alpha: 0.15)
                      : (hasReachedLimit
                          ? AppColors.accentTerracotta.withValues(alpha: 0.15)
                          : AppColors.iheGoldLight),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: profile.isPremium
                        ? AppColors.accentOlive
                        : (hasReachedLimit
                            ? AppColors.accentTerracotta
                            : AppColors.borderGold),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  profile.isPremium
                      ? '✦ ACESSO ILIMITADO'
                      : (hasReachedLimit ? '⚠️ TETO ATINGIDO' : '30 PEÇAS / 5 LOOKS'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: profile.isPremium
                        ? AppColors.accentOlive
                        : (hasReachedLimit
                            ? AppColors.accentTerracotta
                            : AppColors.iheGold),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 1. MÉTRICA: ACERVO CADASTRADO (30 Peças Limite RN02)
          _buildRulerMetric(
            label: 'Acervo Digitalizado',
            currentValue: profile.registeredPiecesCount,
            maxValue: profile.maxPiecesLimit,
            isUnlimited: profile.isPremium,
            unitLabel: 'peças',
            ratio: profile.piecesRatio,
            isAlert: profile.hasReachedPiecesLimit,
          ),

          const SizedBox(height: 14),

          // 2. MÉTRICA: COMBINAÇÕES DIÁRIAS IA (5 Looks Limite RN02)
          _buildRulerMetric(
            label: 'Combinações Diárias IA',
            currentValue: profile.dailyAiLooksUsed,
            maxValue: profile.maxDailyAiLooksLimit,
            isUnlimited: profile.isPremium,
            unitLabel: 'looks hoje',
            ratio: profile.dailyLooksRatio,
            isAlert: profile.hasReachedDailyLooksLimit,
          ),

          // 3. ALERTA DE UPGRADE EM TERRACOTA SUAVE (SE TETO ATINGIDO - RN02)
          if (hasReachedLimit) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentTerracotta.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.accentTerracotta.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.accentTerracotta,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Limite Freemium Atingido (RN02)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentTerracotta,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Você atingiu o teto do plano gratuito (30 peças ou 5 combinações diárias). Faça o upgrade para cadastrar peças ilimitadas.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textPrimary.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onUpgradeTap?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentTerracotta,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        'Fazer Upgrade para HarmonIA Premium',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
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

  /// Indicador de Régua Tipográfica Ultra-fina (2px)
  Widget _buildRulerMetric({
    required String label,
    required int currentValue,
    required int maxValue,
    required bool isUnlimited,
    required String unitLabel,
    required double ratio,
    required bool isAlert,
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              isUnlimited ? '$currentValue $unitLabel (Ilimitado)' : '$currentValue / $maxValue $unitLabel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isAlert ? AppColors.accentTerracotta : AppColors.iheGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Régua Tipográfica Ultrafina (2px)
        Stack(
          children: [
            Container(
              height: 2.5,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: ratio,
              child: Container(
                height: 2.5,
                decoration: BoxDecoration(
                  color: isAlert ? AppColors.accentTerracotta : AppColors.iheGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
