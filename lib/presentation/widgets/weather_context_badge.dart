import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../models/weather_context.dart';

/// Widget Editorial de Contexto Meteorológico (RF16)
///
/// Apresenta o clima local e a adequação do look de forma minimalista,
/// sem Material Design cru. Ao toque, dispara HapticFeedback.selectionClick()
/// e abre a BottomSheet com as variáveis que afetam o S_ocasion do IHE.
class WeatherContextBadge extends StatelessWidget {
  final WeatherContext weatherContext;
  final VoidCallback? onTap;

  const WeatherContextBadge({
    super.key,
    required this.weatherContext,
    this.onTap,
  });

  void _showWeatherDetailsModal(BuildContext context) {
    HapticFeedback.selectionClick();

    if (onTap != null) {
      onTap!();
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _WeatherDetailsSheet(weatherContext: weatherContext),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sobre a Sala: sem cartão, só contorno capilar marfim
    return Semantics(
      button: true,
      label: 'Clima em ${weatherContext.city}: ${weatherContext.formattedTemperature}, ${weatherContext.conditionLabel}',
      child: GestureDetector(
        onTap: () => _showWeatherDetailsModal(context),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: AppColors.hairlineIvory, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(weatherContext.city.toUpperCase(), style: AppTypography.atelierMeta()),
                        const SizedBox(height: 3),
                        Text(
                          weatherContext.conditionLabel.toUpperCase(),
                          style: AppTypography.atelierMeta(color: AppColors.ivoryText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(weatherContext.iconData, size: 20, color: AppColors.ivoryText),
                  const SizedBox(width: 8),
                  Text(
                    weatherContext.formattedTemperature,
                    style: AppTypography.displayEditorial(color: AppColors.ivoryText).copyWith(fontSize: 30, height: 1.0),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 0.6, color: AppColors.hairlineIvory),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('✦ ', style: TextStyle(fontSize: 11, color: AppColors.verdigrisLight)),
                  Expanded(
                    child: Text(
                      weatherContext.recommendationBadge,
                      style: AppTypography.bodySmall(color: AppColors.ivoryText).copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.ivoryMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal Bottom Sheet sutil com os detalhes das variáveis de clima (S_ocasion do IHE)
class _WeatherDetailsSheet extends StatelessWidget {
  final WeatherContext weatherContext;

  const _WeatherDetailsSheet({
    required this.weatherContext,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.paperBoneRaised,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.hairlineInk,
            width: 0.8,
          ),
          boxShadow: AppColors.paperShadow,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pílula centralizada de drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inkSecondary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Cabeçalho Editorial
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONTEXTO METEOROLÓGICO',
                          style: GoogleFonts.interTight(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.inkSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Variáveis do S_ocasion',
                          style: GoogleFonts.bodoniModa(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chancery Badge para S_ocasion
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gildedWash,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.hairlineInk,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'S_ocasion ',
                          style: GoogleFonts.interTight(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkText,
                          ),
                        ),
                        Text(
                          weatherContext.formattedScore,
                          style: GoogleFonts.bodoniModa(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gildedInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(
                  height: 1, thickness: 0.6, color: AppColors.hairlineInk),
              const SizedBox(height: 16),

              // Grid de 3 Variáveis Meteorológicas
              Row(
                children: [
                  Expanded(
                    child: _WeatherMetricTile(
                      label: 'TEMPERATURA',
                      value: weatherContext.formattedTemperature,
                      subtext: weatherContext.formattedMinMax,
                      icon: weatherContext.iconData,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _WeatherMetricTile(
                      label: 'VENTO',
                      value: weatherContext.formattedWind,
                      subtext: 'Brando',
                      icon: Icons.air_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _WeatherMetricTile(
                      label: 'UMIDADE',
                      value: weatherContext.formattedHumidity,
                      subtext: 'Ideal',
                      icon: Icons.water_drop_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Card do Raciocínio Estético (IHE S_ocasion)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.paperBone,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.hairlineInk,
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: AppColors.gildedInk,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'RECOMENDAÇÃO EDITORIAL DE CAMADAS',
                          style: GoogleFonts.interTight(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      weatherContext.sOcasionRationale,
                      style: GoogleFonts.interTight(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        color: AppColors.inkText,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Botão Entendido / Dismiss
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: AppColors.hairlineInk, width: 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.paperBoneRaised,
                  ),
                  child: Text(
                    'Entendido',
                    style: GoogleFonts.interTight(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card individual de métrica do clima no modal
class _WeatherMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final IconData icon;

  const _WeatherMetricTile({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.paperBone,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.hairlineInk,
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.inkSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.interTight(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.inkSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.bodoniModa(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.inkText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            subtext,
            style: GoogleFonts.interTight(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: AppColors.inkSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
