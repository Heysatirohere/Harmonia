import 'package:flutter/material.dart';

import '../../core/demo/demo_mode.dart';
import '../../data/services/outfit_api_service.dart';
import '../../mocks/mock_gap_analysis.dart';
import '../../models/wardrobe_gap.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_room.dart';
import '../atelier/atelier_widgets.dart';
import '../atelier/room_scene.dart';
import '../widgets/filter_chips_bar.dart';
import '../widgets/gap_analysis_sheet.dart';

/// Lacunas do Acervo & Afiliação (RF11/RF12): cada lacuna em uma folha de papel sobre o verdete.
/// As lacunas vêm do motor IHE, medidas contra as peças reais do usuário na ocasião escolhida.
class GapAnalysisScreen extends StatefulWidget {
  final OutfitApiService? service;

  const GapAnalysisScreen({super.key, this.service});

  @override
  State<GapAnalysisScreen> createState() => _GapAnalysisScreenState();
}

class _GapAnalysisScreenState extends State<GapAnalysisScreen> {
  static const _room = AtelierRoom.verdigris;

  /// Ocasiões oferecidas e a chave correspondente no motor do IHE
  static const _occasions = [
    ('Casual', 'CASUAL'),
    ('Trabalho', 'TRABALHO'),
    ('Noite', 'NOITE'),
    ('Festa', 'FESTA'),
  ];
  int _occasionIndex = 0;

  late final OutfitApiService _service = widget.service ?? OutfitApiService();
  WardrobeGapReport? _report;
  String? _error;
  bool _loading = true;

  /// Respostas de uma ocasião anterior (troca no meio da carga) são ignoradas
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await _service.getWardrobeGaps(occasion: _occasions[_occasionIndex].$2);
      if (!mounted || generation != _generation) return;
      setState(() => _report = report.gaps.isEmpty && kDemoMode ? MockGapAnalysis.report : report);
    } on OutfitException catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        if (kDemoMode) {
          _report = MockGapAnalysis.report;
        } else {
          _report = null;
          _error = e.message;
        }
      });
    } finally {
      if (mounted && generation == _generation) setState(() => _loading = false);
    }
  }

  void _selectOccasion(int index) {
    if (index == _occasionIndex) return;
    setState(() => _occasionIndex = index);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final gaps = _report?.gaps ?? const <WardrobeGap>[];

    return Scaffold(
      backgroundColor: AppColors.tapestryNoir,
      body: RoomScene(
        room: _room,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: RoomHeader(
                eyebrow: 'Lacunas & afiliação • RF11/RF12',
                title: 'Otimização de Acervo',
                subtitle: 'Peças-chave que destravam novas combinações',
                room: _room,
                onBack: () => Navigator.maybePop(context),
              ),
            ),
            SliverToBoxAdapter(
              child: FilterChipsBar(
                categories: [for (final (label, _) in _occasions) label],
                selectedIndex: _occasionIndex,
                onCategorySelected: _selectOccasion,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.elementGap)),
            if (gaps.isEmpty)
              SliverToBoxAdapter(child: _buildPlaceholder())
            else ...[
              if (_report?.baselineIhe case final double baseline)
                SliverToBoxAdapter(
                  child: RoomSectionTitle(title: 'Seu acervo hoje', meta: 'IHE MÉDIO ${baseline.round()}%'),
                ),
              for (final gap in gaps)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin, 0, AppSpacing.pageMargin, 20),
                  sliver: SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      // Troca de ocasião: as folhas antigas esmaecem até a resposta nova chegar
                      opacity: _loading ? 0.6 : 1.0,
                      duration: AppMotion.medium,
                      curve: AppMotion.editorialDecel,
                      child: AtelierSheet(child: GapAnalysisSheet(gap: gap)),
                    ),
                  ),
                ),
            ],
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.sizeOf(context).height * 0.3)),
          ],
        ),
      ),
    );
  }

  /// Carregando, erro ou nenhuma lacuna
  Widget _buildPlaceholder() {
    final (String title, String message, bool canRetry) = switch ((_loading, _error, _report)) {
      (true, _, _) => ('Mapeando o seu acervo…', 'Medindo quais peças destravariam looks com o que você já tem.', false),
      (false, final String message, _) => ('O ateliê não respondeu', message, true),
      (false, null, WardrobeGapReport(baselineIhe: null)) => (
          'Seu acervo ainda não forma looks',
          'Digitalize algumas peças para descobrir o que falta no seu armário.',
          false,
        ),
      _ => (
          'Nenhuma lacuna por aqui',
          'Seu acervo já cobre as peças-chave para esta ocasião. Experimente outra ocasião.',
          false,
        ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin, AppSpacing.elementGap, AppSpacing.pageMargin, 0),
      child: AnimatedOpacity(
        opacity: _loading ? 0.7 : 1.0,
        duration: AppMotion.medium,
        curve: AppMotion.editorialDecel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.subtitleCuratorial(color: AppColors.ivoryText)),
            const SizedBox(height: AppSpacing.tightGap),
            Text(message, style: AppTypography.bodyReading(color: AppColors.ivoryMuted)),
            if (canRetry) ...[
              const SizedBox(height: 20),
              RoomIconButton(icon: Icons.refresh, label: 'Tentar de novo', onTap: _load),
            ],
          ],
        ),
      ),
    );
  }
}
