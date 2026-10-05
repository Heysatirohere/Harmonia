import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/services/community_api_service.dart';
import '../../data/services/open_meteo_weather_service.dart';
import '../../data/services/outfit_api_service.dart';
import '../../domain/models/recommended_look.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../models/weather_context.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_room.dart';
import '../atelier/atelier_widgets.dart';
import '../atelier/room_scene.dart';
import '../widgets/filter_chips_bar.dart';
import '../widgets/photo_capture.dart';
import '../widgets/share_outfit_sheet.dart';
import '../widgets/weather_context_badge.dart';
import 'store_mirror_screen.dart';

/// Tela de Sugestão Diária de Look (DailyOutfitScreen - RF16)
///
/// Renascença do Ateliê (AGENTS.md 4.2 e 7.2):
/// - Veludo bordô na composição do look; ao rolar até o IHE, a Sala dissolve em ocre dourado
/// - Peças listadas direto sobre a Sala, sem cartões
/// - Pontuação IHE em Bodoni de joalheria e ações em até 3 toques
class DailyOutfitScreen extends StatefulWidget {
  final WeatherRepository? weatherRepository;
  final OutfitApiService? service;
  final CommunityApiService? communityService;
  final PhotoCapture? capturePhoto;

  const DailyOutfitScreen({
    super.key,
    this.weatherRepository,
    this.service,
    this.communityService,
    this.capturePhoto,
  });

  @override
  State<DailyOutfitScreen> createState() => _DailyOutfitScreenState();
}

class _DailyOutfitScreenState extends State<DailyOutfitScreen> {
  late final WeatherRepository _weatherRepository = widget.weatherRepository ?? OpenMeteoWeatherService();

  /// Clima local (RF16); nulo enquanto carrega ou quando indisponível
  WeatherContext? _weather;
  WeatherFailure? _weatherFailure;
  bool _weatherLoading = true;

  /// Sem clima, o motor recebe o mesmo padrão neutro da API
  static const _neutralTemperature = 22.0;
  late final OutfitApiService _service = widget.service ?? OutfitApiService();
  late final CommunityApiService _communityService = widget.communityService ?? CommunityApiService();
  /// Aprovações registradas (RF13), por look exibido: id do registro para desfazer
  final Map<RecommendedLook, String> _approvals = {};
  bool _sendingFeedback = false;

  /// Todas as sugestões desta consulta foram descartadas
  bool _discardedAll = false;

  /// Ocasiões oferecidas e a chave correspondente no motor do IHE
  static const _occasions = [
    ('Casual', 'CASUAL'),
    ('Trabalho', 'TRABALHO'),
    ('Noite', 'NOITE'),
    ('Festa', 'FESTA'),
  ];
  int _occasionIndex = 0;

  List<RecommendedLook> _looks = const [];
  int _lookIndex = 0;
  bool _loading = true;
  OutfitException? _error;

  /// Descarta respostas de uma ocasião que já não está selecionada
  int _requestId = 0;

  static const _months = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];

  @override
  void initState() {
    super.initState();
    _loadWeatherThenLooks();
  }

  /// O clima vem antes dos looks: gerar com o padrão e depois com o clima real
  /// seriam duas consultas diferentes, e duas cobranças da cota
  Future<void> _loadWeatherThenLooks() async {
    setState(() {
      _weatherLoading = true;
      _weatherFailure = null;
    });
    try {
      final weather = await _weatherRepository.current();
      if (mounted) setState(() => _weather = weather);
    } on WeatherFailure catch (failure) {
      if (mounted) setState(() => _weatherFailure = failure);
    } finally {
      if (mounted) setState(() => _weatherLoading = false);
    }
    if (mounted) await _loadLooks();
  }

  Future<void> _resolveWeather(WeatherFailureKind kind) async {
    HapticFeedback.selectionClick();
    await _weatherRepository.resolve(kind);
    if (mounted) await _loadWeatherThenLooks();
  }

  Future<void> _loadLooks() async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
      _discardedAll = false;
      _approvals.clear();
    });
    try {
      final looks = await _service.generateDailyOutfits(
        occasion: _occasions[_occasionIndex].$2,
        temperatureCelsius: _weather?.temperature ?? _neutralTemperature,
        isRaining: _weather?.isRainExpected ?? false,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _looks = looks;
        _lookIndex = 0;
      });
    } on OutfitException catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _looks = const [];
        _error = e;
      });
    } finally {
      if (mounted && requestId == _requestId) setState(() => _loading = false);
    }
  }

  void _selectOccasion(int index) {
    if (index == _occasionIndex) return;
    setState(() => _occasionIndex = index);
    _loadLooks();
  }

  /// Percorre os looks já gerados, sem gastar cota
  void _showNextLook() {
    HapticFeedback.selectionClick();
    setState(() {
      _lookIndex = (_lookIndex + 1) % _looks.length;
    });
  }

  String get _today {
    final now = DateTime.now();
    return '${now.day} de ${_months[now.month - 1]}';
  }

  /// Aprovar registra o look do dia (RF13); tocar de novo desfaz
  Future<void> _toggleApproval(RecommendedLook look) async {
    if (_sendingFeedback) return;
    final approvalId = _approvals[look];
    setState(() => _sendingFeedback = true);
    try {
      if (approvalId == null) {
        final id = await _service.sendLookFeedback(look, LookFeedbackAction.approved);
        HapticFeedback.mediumImpact();
        if (mounted) setState(() => _approvals[look] = id);
        _showMessage('Look do dia aprovado.', icon: Icons.check_circle_outline);
      } else {
        await _service.undoLookFeedback(approvalId);
        HapticFeedback.selectionClick();
        if (mounted) setState(() => _approvals.remove(look));
        _showMessage('Aprovação desfeita.');
      }
    } on OutfitException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _sendingFeedback = false);
    }
  }

  Future<void> _shareApproved(String approvalId) async {
    final post = await ShareOutfitSheet.show(
      context,
      service: _communityService,
      feedbackId: approvalId,
      capturePhoto: widget.capturePhoto,
    );
    if (post == null || !mounted) return;
    HapticFeedback.mediumImpact();
    _showMessage(post.isPublic ? 'Look publicado na comunidade.' : 'Look salvo em "Meus looks".');
  }

  /// Descartar tira o look desta lista e das próximas sugestões (RF13)
  Future<void> _discard(RecommendedLook look) async {
    if (_sendingFeedback) return;
    setState(() => _sendingFeedback = true);
    final String feedbackId;
    try {
      feedbackId = await _service.sendLookFeedback(look, LookFeedbackAction.discarded);
    } on OutfitException catch (e) {
      _showMessage(e.message);
      return;
    } finally {
      if (mounted) setState(() => _sendingFeedback = false);
    }
    if (!mounted) return;

    HapticFeedback.selectionClick();
    final position = _looks.indexOf(look);
    setState(() {
      _looks = [..._looks]..removeAt(position);
      _approvals.remove(look);
      _discardedAll = _looks.isEmpty;
      if (_lookIndex >= _looks.length) _lookIndex = 0;
    });
    _showMessage(
      'Sugestão descartada. Ela não volta a aparecer.',
      action: SnackBarAction(
        label: 'Desfazer',
        textColor: AppColors.gildedLeaf,
        onPressed: () => _undoDiscard(look, feedbackId, position),
      ),
    );
  }

  Future<void> _undoDiscard(RecommendedLook look, String feedbackId, int position) async {
    try {
      await _service.undoLookFeedback(feedbackId);
    } on OutfitException catch (e) {
      _showMessage(e.message);
      return;
    }
    if (!mounted) return;
    setState(() {
      _looks = [..._looks]..insert(position.clamp(0, _looks.length), look);
      _lookIndex = _looks.indexOf(look);
      _discardedAll = false;
    });
  }

  void _showMessage(String message, {IconData? icon, SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.tapestryNoir,
          behavior: SnackBarBehavior.floating,
          action: action,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            side: const BorderSide(color: AppColors.hairlineGold, width: 0.8),
          ),
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.gildedLeaf, size: 18),
                const SizedBox(width: 10),
              ],
              Expanded(child: Text(message, style: AppTypography.bodyReading(color: AppColors.ivoryText))),
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
    final look = _looks.isEmpty ? null : _looks[_lookIndex];

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
                room: AtelierRoom.velvetBordeaux,
                trailing: RoomIconButton(
                  icon: Icons.center_focus_strong,
                  label: 'Modo Provador (Mirror Mode)',
                  onTap: _openMirrorMode,
                ),
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

            // 1. Clima local (RF16)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
              sliver: SliverToBoxAdapter(child: _buildWeather(look)),
            ),

            if (look != null)
              ..._buildLook(look)
            else
              SliverToBoxAdapter(child: _buildPlaceholder()),
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.sizeOf(context).height * 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeather(RecommendedLook? look) {
    final weather = _weather;
    if (weather != null) {
      return WeatherContextBadge(weatherContext: weather, sOcasionScore: look?.sOcasion);
    }
    if (_weatherLoading) {
      return Text('Lendo o clima local…', style: AppTypography.bodySmall(color: AppColors.ivoryMuted));
    }
    return _WeatherUnavailable(failure: _weatherFailure!, onResolve: _resolveWeather);
  }

  /// Carregando, erro, cota esgotada ou acervo que ainda não forma um look
  Widget _buildPlaceholder() {
    final error = _error;
    final (String title, String message, bool canRetry) = switch ((_loading, error)) {
      (true, _) => ('Compondo o seu look…', 'O motor de harmonia está cruzando o seu acervo com o dia.', false),
      (false, OutfitException(isQuotaExceeded: true)) => ('Cota de hoje esgotada', error!.message, false),
      (false, final OutfitException error) => ('O ateliê não respondeu', error.message, true),
      (false, null) when _discardedAll => (
          'Você descartou as sugestões desta ocasião',
          'Gerar novas sugestões usa 1 combinação do dia.',
          true,
        ),
      (false, null) => (
          'Seu acervo ainda não forma um look',
          'Digitalize ao menos uma parte de cima e uma de baixo, ou uma peça única.',
          true,
        ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin, AppSpacing.sectionGap, AppSpacing.pageMargin, 0),
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
              RoomIconButton(
                icon: Icons.refresh,
                label: _discardedAll ? 'Gerar novas sugestões' : 'Tentar de novo',
                onTap: _loadLooks,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLook(RecommendedLook look) {
    return [
      // 2. "The Floating Canvas": peças do look direto sobre o veludo
      SliverToBoxAdapter(
        child: RoomSectionTitle(
          title: 'Composição',
          meta: '${look.items.length} ${look.items.length == 1 ? 'peça' : 'peças'}',
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            for (final (index, item) in look.items.indexed)
              _GarmentRow(
                category: item.category,
                title: item.name,
                provenance: item.brandOrProvenance,
                color: item.dominantColor,
                tag: item.isConsciousFashion ? item.consciousNote : null,
                isLast: index == look.items.length - 1,
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
                      text: '${look.ihePercentage}',
                      style: AppTypography.heroDisplay().copyWith(fontSize: 96, height: 0.9),
                    ),
                    TextSpan(
                      text: '%',
                      style: AppTypography.heroDisplay(color: AppColors.gildedLeaf).copyWith(fontSize: 48),
                    ),
                  ],
                ),
              ),
              if (look.isStronglyRecommended) ...[
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
                look.stylingAdvice,
                style: AppTypography.bodyReading(color: AppColors.ivoryMuted).copyWith(fontSize: 14),
              ),
              const SizedBox(height: 32),

              // 4. Ações de 3 toques (RNF06)
              CinnabarButton(
                label: _approvals.containsKey(look) ? 'Look aprovado' : 'Aprovar look do dia',
                icon: _approvals.containsKey(look) ? Icons.check_circle : Icons.favorite_border,
                onPressed: () => _toggleApproval(look),
                busy: _sendingFeedback,
              ),
              const SizedBox(height: 12),
              // Look aprovado pode ir para o feed com as peças e o IHE (RF14)
              if (_approvals[look] case final approvalId?) ...[
                _OutlineAction(
                  icon: Icons.ios_share,
                  label: 'Publicar na comunidade',
                  onPressed: () => _shareApproved(approvalId),
                ),
                const SizedBox(height: 12),
              ],
              if (_looks.length > 1) ...[
                _OutlineAction(
                  icon: Icons.autorenew,
                  label: 'Outra sugestão (${_lookIndex + 1}/${_looks.length})',
                  onPressed: _showNextLook,
                ),
                const SizedBox(height: 12),
              ],
              _OutlineAction(
                icon: Icons.remove_red_eye_outlined,
                label: 'Simular no provador',
                onPressed: _handleOpenMirrorSheet,
              ),
              const SizedBox(height: 12),
              _OutlineAction(
                icon: Icons.close,
                label: 'Descartar sugestão',
                onPressed: _sendingFeedback ? null : () => _discard(look),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

/// Clima indisponível: explica o efeito nos looks e oferece a ação que resolve
class _WeatherUnavailable extends StatelessWidget {
  final WeatherFailure failure;
  final ValueChanged<WeatherFailureKind> onResolve;

  const _WeatherUnavailable({required this.failure, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    final action = switch (failure.kind) {
      WeatherFailureKind.permissionDenied => 'Permitir localização',
      WeatherFailureKind.permissionDeniedForever => 'Abrir configurações',
      WeatherFailureKind.serviceDisabled => 'Ativar localização',
      WeatherFailureKind.unavailable => 'Tentar de novo',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.hairlineIvory, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_off_outlined, size: 18, color: AppColors.ivoryMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(failure.message, style: AppTypography.bodySmall(color: AppColors.ivoryText)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              'Looks calculados para clima ameno, sem chuva.',
              style: AppTypography.bodySmall(color: AppColors.ivoryMuted),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: TextButton(
              onPressed: () => onResolve(failure.kind),
              child: Text(action, style: AppTypography.uiHeadline(color: AppColors.ivoryText).copyWith(fontSize: 13.5)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ação secundária com contorno capilar marfim sobre a Sala
class _OutlineAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _OutlineAction({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: AppColors.ivoryText),
        label: Text(label, style: AppTypography.uiHeadline(color: AppColors.ivoryText).copyWith(fontSize: 14)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.hairlineIvory, width: 1.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMedium)),
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
  final String? tag;
  final bool isLast;

  const _GarmentRow({
    required this.category,
    required this.title,
    required this.provenance,
    required this.color,
    this.tag,
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
                if (tag case final String tag) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.eco_outlined, size: 12, color: AppColors.verdigrisLight),
                      const SizedBox(width: 5),
                      Text(tag, style: AppTypography.bodySmall(color: AppColors.verdigrisLight).copyWith(fontSize: 11.5)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
