import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/outfit_combination.dart';
import '../../theme/app_theme.dart';

/// Medidor Visual do IHE (Índice de Harmonia Estética)
/// Conforme AGENTS.md Seção 6.2:
/// - Medidor minimalista circular vetorial via CustomPainter com gradiente metálico joalheiro
/// - Pontuação central em Playfair Display
/// - Selo "✦ LOOK FORTEMENTE RECOMENDADO" para pontuações >= 75% em caixa alta (+0.8 kerning)
/// - Decomposição visual dos 4 pilares (S_cor, S_bio, S_ocasion, S_cos) em microchips refinados
class IheScoreGauge extends StatelessWidget {
  final IheSubScores ihe;
  final bool compact;
  final VoidCallback? onTap;

  const IheScoreGauge({
    super.key,
    required this.ihe,
    this.compact = false,
    this.onTap,
  });

  void _showPillarsModal(BuildContext context) {
    HapticFeedback.lightImpact();
    if (onTap != null) {
      onTap!();
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _IhePillarsDetailSheet(ihe: ihe),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: ihe.isStronglyRecommended
              ? AppColors.iheGold.withValues(alpha: 0.4)
              : AppColors.borderSubtle,
          width: 0.8,
        ),
        boxShadow: AppColors.editorialShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Área Superior: Medidor Vetorial Joalheiro & Selo de Recomendação
          GestureDetector(
            onTap: () => _showPillarsModal(context),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                // CustomPainter com o Arco Metálico
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CustomPaint(
                    painter: _IheArcPainter(
                      scoreProgress: ihe.overallScore / 100.0,
                    ),
                    child: Center(
                      child: Text(
                        '${ihe.overallScore}%',
                        style: AppTypography.displayEditorial(
                          color: AppColors.iheGold,
                        ).copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Títulos e Selo "✦ LOOK FORTEMENTE RECOMENDADO"
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ÍNDICE DE HARMONIA ESTÉTICA',
                            style: AppTypography.metadataBadge(
                              color: AppColors.textSecondary,
                            ).copyWith(fontSize: 9.5, letterSpacing: 1.0),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (ihe.isStronglyRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.iheGoldLight.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.borderGold,
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            '✦ LOOK FORTEMENTE RECOMENDADO',
                            style: AppTypography.metadataBadge(
                              color: AppColors.iheGold,
                            ).copyWith(fontSize: 9.0, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                          ),
                        )
                      else
                        Text(
                          'Equilíbrio & Ressonância Tonal',
                          style: AppTypography.subtitleCuratorial(
                            color: AppColors.textPrimary,
                          ).copyWith(fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 12),

          // Área Inferior: Microchips Horizontais dos 4 Pilares
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // Pilar 1: S_cor (Harmonia Cromática CIE L*a*b*)
                _PillarMicroChip(
                  label: 'S_cor ${(ihe.sColor * 100).round()}%',
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ihe.dominantColor,
                      border: Border.all(color: AppColors.borderSubtle, width: 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Pilar 2: S_bio (Compensação Morfológica)
                _PillarMicroChip(
                  label: 'S_bio ${(ihe.sBio * 100).round()}%',
                  icon: Icons.accessibility_new_rounded,
                ),
                const SizedBox(width: 6),

                // Pilar 3: S_ocasion (Contexto & Clima)
                _PillarMicroChip(
                  label: ihe.occasionContext,
                  icon: Icons.wb_sunny_outlined,
                ),
                const SizedBox(width: 6),

                // Pilar 4: S_cos (Ressonância Vetorial)
                _PillarMicroChip(
                  label: 'S_cos ${(ihe.sCos * 100).round()}%',
                  icon: Icons.auto_awesome_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter do Medidor Circular com Gradiente Champanhe & Ouro
class _IheArcPainter extends CustomPainter {
  final double scoreProgress; // 0.0 a 1.0

  _IheArcPainter({required this.scoreProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;

    // 1. Trilha de Fundo Capilar
    final trackPaint = Paint()
      ..color = AppColors.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Arco do Progresso com Gradiente Metálico Joalheiro
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * scoreProgress.clamp(0.0, 1.0);

    final progressGradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + (2 * math.pi),
      colors: const [
        Color(0xFFE4C586), // Champanhe Suave
        AppColors.iheGold, // Ouro IHE
        Color(0xFF8B6420), // Ouro Queimado
        Color(0xFFE4C586),
      ],
    );

    final progressPaint = Paint()
      ..shader = progressGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _IheArcPainter oldDelegate) {
    return oldDelegate.scoreProgress != scoreProgress;
  }
}

/// Microchip Horizontal para Decomposição do Pilar
class _PillarMicroChip extends StatelessWidget {
  final String label;
  final Widget? leading;
  final IconData? icon;

  const _PillarMicroChip({
    required this.label,
    this.leading,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(
              icon,
              size: 11,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.metadataBadge(
              color: AppColors.textPrimary,
            ).copyWith(fontSize: 9.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Modal Detalhado dos 4 Pilares do IHE
class _IhePillarsDetailSheet extends StatelessWidget {
  final IheSubScores ihe;

  const _IhePillarsDetailSheet({required this.ihe});

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

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderGold, width: 1.0),
                ),
                child: Text(
                  '${ihe.overallScore}',
                  style: AppTypography.displayEditorial(color: AppColors.iheGold)
                      .copyWith(fontSize: 26, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Análise de Harmonia Estética',
                      style: AppTypography.displayEditorial().copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 2),
                    if (ihe.isStronglyRecommended)
                      Text(
                        '✦ Look Fortemente Recomendado',
                        style: AppTypography.metadataBadge(color: AppColors.iheGold),
                      )
                    else
                      Text(
                        ihe.occasionContext,
                        style: AppTypography.bodySmall(),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 16),

          Text(
            'DECOMPOSIÇÃO DOS 4 PILARES ANALÍTICOS',
            style: AppTypography.metadataBadge().copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),

          _PillarRow(
            title: '1. Harmonia Cromática (S_cor)',
            description: 'Matiz e luminosidade correlacionados no espaço CIE L*a*b*',
            percentage: (ihe.sColor * 100).round(),
            colorSwatch: ihe.dominantColor,
          ),
          _PillarRow(
            title: '2. Compensação Morfológica (S_bio)',
            description: 'Equilíbrio de proporções e caimento da silhueta',
            percentage: (ihe.sBio * 100).round(),
            icon: Icons.accessibility_new_rounded,
          ),
          _PillarRow(
            title: '3. Contexto & Clima (S_ocasion)',
            description: ihe.occasionContext,
            percentage: (ihe.sOcasion * 100).round(),
            icon: Icons.wb_sunny_outlined,
          ),
          _PillarRow(
            title: '4. Ressonância Vetorial (S_cos)',
            description: 'Afinidade semântica com o acervo prévio do usuário',
            percentage: (ihe.sCos * 100).round(),
            icon: Icons.auto_awesome_outlined,
          ),
        ],
      ),
    );
  }
}

class _PillarRow extends StatelessWidget {
  final String title;
  final String description;
  final int percentage;
  final Color? colorSwatch;
  final IconData? icon;

  const _PillarRow({
    required this.title,
    required this.description,
    required this.percentage,
    this.colorSwatch,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle, width: 0.6),
            ),
            child: Center(
              child: colorSwatch != null
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorSwatch,
                      ),
                    )
                  : Icon(
                      icon ?? Icons.circle_outlined,
                      size: 14,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTypography.uiHeadline().copyWith(fontSize: 13),
                    ),
                    Text(
                      '$percentage%',
                      style: AppTypography.uiHeadline(color: AppColors.iheGold)
                          .copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Text(
                  description,
                  style: AppTypography.bodySmall(),
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
