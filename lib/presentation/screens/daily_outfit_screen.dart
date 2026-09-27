import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../mocks/mock_weather.dart';
import '../../models/weather_context.dart';
import '../widgets/weather_context_badge.dart';

/// Tela de Sugestão Diária de Look (DailyOutfitScreen - RF16)
///
/// Segue a diretriz máxima do AGENTS.md:
/// - Fundo creme quente (#FBF9F5)
/// - Posicionamento fluido do WeatherContextBadge no topo
/// - "Floating Canvas" para a arara virtual de peças sem molduras duras
/// - Medidor de IHE tipo chancela joalheria
/// - Regra dos 3 toques para aprovação e provador
class DailyOutfitScreen extends StatefulWidget {
  final WeatherContext? weatherContext;

  const DailyOutfitScreen({
    super.key,
    this.weatherContext,
  });

  @override
  State<DailyOutfitScreen> createState() => _DailyOutfitScreenState();
}

class _DailyOutfitScreenState extends State<DailyOutfitScreen> {
  late final WeatherContext _weather;
  bool _isApproved = false;

  @override
  void initState() {
    super.initState();
    _weather = widget.weatherContext ?? MockWeather.current;
  }

  void _handleApproveLook() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isApproved = !_isApproved;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.iheGold, size: 18),
            const SizedBox(width: 8),
            Text(
              _isApproved
                  ? 'Look do dia registrado no seu acervo!'
                  : 'Aprovação desfeita.',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.surfaceCanvas,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleOpenMirrorMode() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.borderSubtle, width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Icon(Icons.center_focus_strong,
                size: 32, color: AppColors.iheGold),
            const SizedBox(height: 10),
            Text(
              'Mirror Mode • Provador AR',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'HUD minimalista ativado para paridade física com as peças do seu guarda-roupa.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTerracotta,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Iniciar Câmera de Paridade',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
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
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CURADORIA HARMONIA • 27 SETEMBRO',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Sugestão Diária',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border,
                color: AppColors.textPrimary, size: 22),
            onPressed: () {
              HapticFeedback.selectionClick();
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.textPrimary, size: 22),
            onPressed: () {
              HapticFeedback.selectionClick();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. POSICIONAMENTO FLUIDO DO BADGE DE CLIMA NO TOPO (RF16)
              WeatherContextBadge(weatherContext: _weather),

              const SizedBox(height: 20),

              // 2. CHANCELA IHE & TÍTULO EDITORIAL DO LOOK
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Badge IHE Selo Joalheria
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.iheGoldLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.borderGold,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('✦ ',
                                  style: TextStyle(
                                      color: AppColors.iheGold, fontSize: 10)),
                              Text(
                                'LOOK FORTEMENTE RECOMENDADO',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: AppColors.iheGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Score IHE 89%
                        Text(
                          '89%',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.iheGold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Sobreposição Terracota em Linho Cru',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Composição pensada para o clima de ${_weather.city} (${_weather.formattedTemperature}), garantindo transição perfeita entre ambientes.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. "THE FLOATING CANVAS" (ARARA VIRTUAL)
              Text(
                'COMPOSIÇÃO DO ACERVO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 12),

              // Cards Flutuantes de Peças (Floating Canvas)
              const _GarmentItemCard(
                category: 'ALFAIATARIA (SUPERIOR)',
                title: 'Blazer Desestruturado em Linho',
                provenance: 'Acervo Pessoal • 4 anos de uso',
                colorAccent: AppColors.accentTerracotta,
                tag: '100% Linho Reciclado',
              ),
              const SizedBox(height: 10),
              const _GarmentItemCard(
                category: 'BASE SUPERIOR',
                title: 'Regata Seda Areia',
                provenance: 'Brechó Vintage Paulistano',
                colorAccent: AppColors.accentSand,
                tag: 'Segunda Mão Certificada',
              ),
              const SizedBox(height: 10),
              const _GarmentItemCard(
                category: 'BASE INFERIOR',
                title: 'Pantalona Ampla Off-White',
                provenance: 'Ateliê Sustentável Local',
                colorAccent: AppColors.accentOlive,
                tag: 'Algodão Orgânico',
              ),

              const SizedBox(height: 24),

              // 4. AÇÕES DE 3 TOQUES (RNF06)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleApproveLook,
                  icon: Icon(
                    _isApproved ? Icons.check_circle : Icons.favorite_border,
                    size: 18,
                  ),
                  label: Text(
                    _isApproved ? 'Look Aprovado' : 'Aprovar Look do Dia',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isApproved
                        ? AppColors.accentOlive
                        : AppColors.accentTerracotta,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleOpenMirrorMode,
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: Text(
                    'Simular no Provador (Mirror Mode)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: AppColors.borderSubtle, width: 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.surfaceRaised,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget individual da peça flutuante no Floating Canvas
class _GarmentItemCard extends StatelessWidget {
  final String category;
  final String title;
  final String provenance;
  final Color colorAccent;
  final String tag;

  const _GarmentItemCard({
    required this.category,
    required this.title,
    required this.provenance,
    required this.colorAccent,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 0.8,
        ),
        boxShadow: AppColors.floatingGarmentShadow,
      ),
      child: Row(
        children: [
          // Amostra Tonal da Cor
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorAccent,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  provenance,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceCanvas,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 0.6,
              ),
            ),
            child: Text(
              tag,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.accentOlive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
