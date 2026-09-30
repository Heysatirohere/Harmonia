import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../mocks/mock_weather.dart';
import '../../models/weather_context.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_room.dart';
import '../atelier/atelier_widgets.dart';
import '../atelier/room_scene.dart';
import '../widgets/weather_context_badge.dart';
import 'store_mirror_screen.dart';

/// Tela de Sugestão Diária de Look (DailyOutfitScreen - RF16)
///
/// Renascença do Ateliê (AGENTS.md 4.2 e 7.2):
/// - Veludo bordô na composição do look; ao rolar até o IHE, a Sala dissolve em ocre dourado
/// - Peças listadas direto sobre a Sala, sem cartões
/// - Pontuação IHE em Bodoni de joalheria e ações em até 3 toques
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

  static const _months = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];

  @override
  void initState() {
    super.initState();
    _weather = widget.weatherContext ?? MockWeather.current;
  }

  String get _today {
    final now = DateTime.now();
    return '${now.day} de ${_months[now.month - 1]}';
  }

  void _handleApproveLook() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isApproved = !_isApproved;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.tapestryNoir,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          side: const BorderSide(color: AppColors.hairlineGold, width: 0.8),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.gildedLeaf, size: 18),
            const SizedBox(width: 10),
            Text(
              _isApproved ? 'Look do dia registrado no seu acervo!' : 'Aprovação desfeita.',
              style: AppTypography.bodyReading(color: AppColors.ivoryText),
            ),
          ],
        ),
      ),
    );
  }

  void _openMirrorMode() {
    HapticFeedback.mediumImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreMirrorScreen()));
  }

  void _handleOpenMirrorSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.tapestryNoir.withValues(alpha: 0.55),
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.paddingOf(ctx).bottom),
        decoration: const BoxDecoration(
          color: AppColors.paperBone,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLarge)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairlineInk,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.center_focus_strong, size: 30, color: AppColors.gildedInk),
            const SizedBox(height: 10),
            Text(
              'Mirror Mode',
              style: AppTypography.displayEditorial(color: AppColors.inkText).copyWith(fontSize: 26),
            ),
            const SizedBox(height: 6),
            Text(
              'HUD de enquadramento para comparar a peça da loja com o seu guarda-roupa.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyReading(color: AppColors.inkSecondary),
            ),
            const SizedBox(height: 20),
            CinnabarButton(
              label: 'Iniciar câmera de paridade',
              icon: Icons.photo_camera_outlined,
              onPressed: () {
                Navigator.pop(ctx);
                _openMirrorMode();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const iheScore = 89;
    final strong = iheScore >= 75;

    return Scaffold(
      backgroundColor: AppColors.tapestryNoir,
      body: RoomScene(
        room: AtelierRoom.velvetBordeaux,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const RoomMarker(room: AtelierRoom.velvetBordeaux),
            SliverToBoxAdapter(
              child: RoomHeader(
                eyebrow: 'Curadoria • $_today',
                title: 'Look do Dia',
                subtitle: 'Sobreposição terracota em linho cru',
                room: AtelierRoom.velvetBordeaux,
                trailing: RoomIconButton(
                  icon: Icons.center_focus_strong,
                  label: 'Modo Provador (Mirror Mode)',
                  onTap: _openMirrorMode,
                ),
              ),
            ),

            // 1. Clima local (RF16)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
              sliver: SliverToBoxAdapter(child: WeatherContextBadge(weatherContext: _weather)),
            ),

            // 2. "The Floating Canvas": peças do look direto sobre o veludo
            const SliverToBoxAdapter(child: RoomSectionTitle(title: 'Composição', meta: '3 peças')),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _GarmentRow(
                    category: 'Alfaiataria • superior',
                    title: 'Blazer Desestruturado em Linho',
                    provenance: 'Acervo pessoal • 4 anos de uso',
                    color: Color(0xFFA34836),
                    tag: '100% linho reciclado',
                  ),
                  _GarmentRow(
                    category: 'Base superior',
                    title: 'Regata Seda Areia',
                    provenance: 'Brechó vintage paulistano',
                    color: Color(0xFFD9CDBF),
                    tag: 'Segunda mão certificada',
                  ),
                  _GarmentRow(
                    category: 'Base inferior',
                    title: 'Pantalona Ampla Off-White',
                    provenance: 'Ateliê sustentável local',
                    color: Color(0xFFF1ECE2),
                    tag: 'Algodão orgânico',
                    isLast: true,
                  ),
                ]),
              ),
            ),

            // 3. Medidor IHE: a Sala dissolve em ocre dourado
            const RoomMarker(room: AtelierRoom.gildedOchre),
            const SliverToBoxAdapter(child: RoomSectionTitle(title: 'Harmonia do look', meta: 'IHE')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$iheScore',
                            style: AppTypography.heroDisplay().copyWith(fontSize: 96, height: 0.9),
                          ),
                          TextSpan(
                            text: '%',
                            style: AppTypography.heroDisplay(color: AppColors.gildedLeaf).copyWith(fontSize: 48),
                          ),
                        ],
                      ),
                    ),
                    if (strong) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Text('✦ ', style: TextStyle(fontSize: 16, color: AppColors.gildedLeaf)),
                          Text(
                            'LOOK FORTEMENTE RECOMENDADO',
                            style: AppTypography.atelierMeta(color: AppColors.ivoryText),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      'Composição pensada para o clima de ${_weather.city} (${_weather.formattedTemperature}), '
                      'garantindo transição perfeita entre ambientes.',
                      style: AppTypography.bodyReading(color: AppColors.ivoryMuted).copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 32),

                    // 4. Ações de 3 toques (RNF06)
                    CinnabarButton(
                      label: _isApproved ? 'Look aprovado' : 'Aprovar look do dia',
                      icon: _isApproved ? Icons.check_circle : Icons.favorite_border,
                      onPressed: _handleApproveLook,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _handleOpenMirrorSheet,
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: AppColors.ivoryText),
                        label: Text(
                          'Simular no provador',
                          style: AppTypography.uiHeadline(color: AppColors.ivoryText).copyWith(fontSize: 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.hairlineIvory, width: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.sizeOf(context).height * 0.5)),
          ],
        ),
      ),
    );
  }
}

/// Peça do look direto sobre a Sala: amostra tonal, nome em Bodoni e proveniência
class _GarmentRow extends StatelessWidget {
  final String category;
  final String title;
  final String provenance;
  final Color color;
  final String tag;
  final bool isLast;

  const _GarmentRow({
    required this.category,
    required this.title,
    required this.provenance,
    required this.color,
    required this.tag,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.hairlineIvory, width: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.hairlineIvory, width: 1.0),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.toUpperCase(), style: AppTypography.atelierMeta().copyWith(fontSize: 9.5)),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: AppTypography.displayEditorial(color: AppColors.ivoryText).copyWith(fontSize: 18, height: 1.2),
                ),
                const SizedBox(height: 3),
                Text(provenance, style: AppTypography.bodySmall(color: AppColors.ivoryMuted)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.eco_outlined, size: 12, color: AppColors.verdigrisLight),
                    const SizedBox(width: 5),
                    Text(tag, style: AppTypography.bodySmall(color: AppColors.verdigrisLight).copyWith(fontSize: 11.5)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
