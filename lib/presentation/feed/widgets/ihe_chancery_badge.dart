import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/community_post.dart';

/// Badge de Chancela Joalheria do IHE (Índice de Harmonia Estética)
/// Segue a Seção 4.2 do AGENTS.md:
/// - Tratamento tipo joalheria com anel fino e gradiente metálico discreto.
/// - Selo '✦ Look Fortemente Recomendado' para pontuação >= 75%.
/// - Ao toque com resposta háptica, abre a decomposição visual intuitiva dos 4 pilares.
class IheChanceryBadge extends StatelessWidget {
  final IheBreakdown ihe;
  final bool compact;

  const IheChanceryBadge({
    super.key,
    required this.ihe,
    this.compact = false,
  });

  void _showBreakdownModal(BuildContext context) {
    HapticFeedback.lightImpact();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _IheDetailsSheet(ihe: ihe),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showBreakdownModal(context),
        borderRadius: BorderRadius.circular(24),
        splashColor: AppColors.iheGold.withValues(alpha: 0.15),
        highlightColor: AppColors.iheGold.withValues(alpha: 0.08),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceCanvas.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: ihe.isStronglyRecommended
                      ? AppColors.iheGold.withValues(alpha: 0.65)
                      : AppColors.borderSubtle,
                  width: 0.8,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x141A1817),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Anel joalheria com valor numérico fino
                  _JewelryScoreCircle(score: ihe.overallScore),
                  const SizedBox(width: 7),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'IHE',
                            style: AppTypography.metaLabel(
                              color: AppColors.textPrimary,
                            ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8),
                          ),
                          if (ihe.isStronglyRecommended) ...[
                            const SizedBox(width: 4),
                            const Text(
                              '✦',
                              style: TextStyle(
                                color: AppColors.iheGold,
                                fontSize: 11,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${ihe.overallScore}% Harmonia',
                        style: AppTypography.metaLabel(
                          color: ihe.isStronglyRecommended
                              ? AppColors.iheGold
                              : AppColors.textSecondary,
                        ).copyWith(fontSize: 9.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Anel minimalista joalheiro com gradiente champanhe metálico
class _JewelryScoreCircle extends StatelessWidget {
  final int score;

  const _JewelryScoreCircle({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE4C586),
            AppColors.iheGold,
            Color(0xFF8B6420),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 25,
          height: 25,
          decoration: const BoxDecoration(
            color: AppColors.surfaceCanvas,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$score',
              style: AppTypography.iheMetric(color: AppColors.iheGold).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal inferior com a Decomposição Visual dos 4 Pilares do IHE
class _IheDetailsSheet extends StatelessWidget {
  final IheBreakdown ihe;

  const _IheDetailsSheet({required this.ihe});

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
          // Puxador central sutil
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

          // Cabeçalho da Chancela
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ihe.isStronglyRecommended
                        ? AppColors.iheGold.withValues(alpha: 0.5)
                        : AppColors.borderSubtle,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${ihe.overallScore}',
                  style: AppTypography.iheMetricLarge(color: AppColors.iheGold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Índice de Harmonia Estética',
                      style: AppTypography.editorialTitleSmall(),
                    ),
                    const SizedBox(height: 3),
                    if (ihe.isStronglyRecommended)
                      Text(
                        '✦ Look Fortemente Recomendado',
                        style: AppTypography.sealLabel(),
                      )
                    else
                      Text(
                        'Equilíbrio e ressonância tonal calculados',
                        style: AppTypography.bodySmall(),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 18),

          Text(
            'DECOMPOSIÇÃO DOS 4 PILARES',
            style: AppTypography.metaLabel().copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),

          // 1. Harmonia Cromática (S_cor) no espaço CIE L*a*b*
          _PillarTile(
            pilarNumber: '1',
            title: 'Harmonia Cromática (S_cor)',
            description: 'Matiz e luminosidade correlacionados no espaço CIE L*a*b*',
            scorePercentage: (ihe.sColor * 100).round(),
            leadingWidget: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: ihe.dominantColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderGold, width: 1.2),
              ),
            ),
          ),

          // 2. Compensação Morfológica (S_bio)
          _PillarTile(
            pilarNumber: '2',
            title: 'Compensação Morfológica (S_bio)',
            description: 'Equilíbrio visual das proporções e corte das silhuetas',
            scorePercentage: (ihe.sBio * 100).round(),
            icon: Icons.accessibility_new_rounded,
          ),

          // 3. Contexto & Clima (S_ocasion)
          _PillarTile(
            pilarNumber: '3',
            title: 'Contexto & Clima (S_ocasion)',
            description: ihe.occasionContext,
            scorePercentage: (ihe.sOcasion * 100).round(),
            icon: Icons.wb_sunny_outlined,
          ),

          // 4. Similaridade Vetorial (S_cos)
          _PillarTile(
            pilarNumber: '4',
            title: 'Similaridade Vetorial (S_cos)',
            description: 'Ressonância semântica com o acervo pessoal do usuário',
            scorePercentage: (ihe.sCos * 100).round(),
            icon: Icons.auto_awesome_outlined,
          ),
        ],
      ),
    );
  }
}

class _PillarTile extends StatelessWidget {
  final String pilarNumber;
  final String title;
  final String description;
  final int scorePercentage;
  final IconData? icon;
  final Widget? leadingWidget;

  const _PillarTile({
    required this.pilarNumber,
    required this.title,
    required this.description,
    required this.scorePercentage,
    this.icon,
    this.leadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle, width: 0.8),
            ),
            child: Center(
              child: leadingWidget ??
                  Icon(
                    icon ?? Icons.circle_outlined,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.bodySmall(color: AppColors.textPrimary).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '$scorePercentage%',
                      style: AppTypography.bodySmall(color: AppColors.iheGold).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.metaLabel(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
