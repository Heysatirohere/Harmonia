import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/demo/demo_mode.dart';
import '../../data/services/wardrobe_api_service.dart';
import '../../models/wardrobe_analytics.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_room.dart';
import '../atelier/atelier_widgets.dart';
import '../atelier/room_scene.dart';

/// Tela do Dashboard Analítico de Rotação de Acervo & ESG (Seção 3.2.2 da Doc)
///
/// Monitora a saúde do guarda-roupa pessoal, taxa de ociosidade (30, 60 e 90 dias),
/// proporção cromática dominante e as peças adormecidas. O uso de cada peça vem dos
/// looks aprovados no Look do Dia (RF13), calculado pela API.
class WardrobeAnalyticsScreen extends StatefulWidget {
  final WardrobeApiService? service;

  const WardrobeAnalyticsScreen({super.key, this.service});

  @override
  State<WardrobeAnalyticsScreen> createState() => _WardrobeAnalyticsScreenState();
}

class _WardrobeAnalyticsScreenState extends State<WardrobeAnalyticsScreen> {
  /// Cor de dado (não é token de interface): areia escurecida, visível sobre o papel
  static const _idle30Color = Color(0xFFA89170);

  late final WardrobeApiService _service = widget.service ?? WardrobeApiService();
  WardrobeAnalytics? _data;
  String? _error;
  bool _loading = true;

  static const WardrobeAnalytics _demoAnalytics = WardrobeAnalytics(
    totalPieces: 8,
    activePiecesCount: 7,
    idle30DaysCount: 1,
    idle60DaysCount: 0,
    idle90DaysCount: 0,
    neverWornCount: 0,
    totalWears: 38,
    colorDistribution: [
      DominantColorShare(
        colorName: 'Terracota e Terras',
        color: Color(0xFFB8361E),
        percentage: 37.5,
        count: 3,
        labCoordinates: 'L* 42.0 · a* 38.0 · b* 24.0',
      ),
      DominantColorShare(
        colorName: 'Neutros & Marfim',
        color: Color(0xFFE9E4D6),
        percentage: 37.5,
        count: 3,
        labCoordinates: 'L* 88.0 · a* 2.0 · b* 8.0',
      ),
      DominantColorShare(
        colorName: 'Esmeralda Profundo',
        color: Color(0xFF1C3120),
        percentage: 25.0,
        count: 2,
        labCoordinates: 'L* 22.0 · a* -14.0 · b* 6.0',
      ),
    ],
    dormantItems: [],
  );

  /// Só chamado depois do carregamento: as seções leem daqui
  WardrobeAnalytics get _analytics => _data!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getAnalytics();
      if (mounted) {
        setState(() {
          _data = data.totalPieces == 0 && kDemoMode ? _demoAnalytics : data;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (kDemoMode) {
          _data = _demoAnalytics;
        } else {
          _error = e is WardrobeException ? e.message : 'Não foi possível carregar a saúde do acervo.';
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget section(Widget child, {bool sheet = true}) => SliverPadding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin, 0, AppSpacing.pageMargin, 20),
      sliver: SliverToBoxAdapter(child: sheet ? AtelierSheet(child: child) : child),
    );

    final data = _data;
    // Ocre dourado no diagnóstico e nas métricas; verdete nas peças adormecidas
    return Scaffold(
      backgroundColor: AppColors.tapestryNoir,
      body: RoomScene(
        room: AtelierRoom.gildedOchre,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const RoomMarker(room: AtelierRoom.gildedOchre),
            SliverToBoxAdapter(
              child: RoomHeader(
                eyebrow: 'Inteligência patrimonial & ESG',
                title: 'Saúde do Acervo',
                subtitle: 'Rotação, ociosidade e cores',
                room: AtelierRoom.gildedOchre,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            if (data == null || data.totalPieces == 0)
              SliverToBoxAdapter(child: _buildPlaceholder())
            else ...[
              // 1. Diagnóstico ESG & rotação (já é uma folha)
              section(_buildEsgHealthSummaryCard(), sheet: false),
              // 2. Ociosidade (30, 60, 90 dias)
              section(_buildRotationTimelineSection()),
              // 3. Proporção cromática dominante (CIE L*a*b*)
              section(_buildChromaticDistributionSection()),
              // 4. Peças adormecidas (>90 dias)
              const RoomMarker(room: AtelierRoom.verdigris),
              const SliverToBoxAdapter(
                child: RoomSectionTitle(title: 'Peças adormecidas', meta: '> 90 dias'),
              ),
              section(_buildDormantPiecesSection()),
            ],
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.sizeOf(context).height * 0.4)),
          ],
        ),
      ),
    );
  }

  /// Carregando, erro ou acervo vazio
  Widget _buildPlaceholder() {
    final error = _error;
    final (String title, String message, bool canRetry) = switch ((_loading, error)) {
      (true, _) => ('Lendo o seu acervo…', 'Cruzando as suas peças com os looks que você aprovou.', false),
      (false, final String message) => ('O ateliê não respondeu', message, true),
      (false, null) => (
          'Seu acervo ainda está vazio',
          'Digitalize as suas peças para acompanhar a rotação e as cores do armário.',
          false,
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
              RoomIconButton(icon: Icons.refresh, label: 'Tentar de novo', onTap: _load),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEsgHealthSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paperBone,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: AppColors.paperShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.verdigrisInk.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.verdigrisInk.withValues(alpha: 0.3), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.eco_outlined, color: AppColors.verdigrisInk, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'DIRETRIZ ESG & CIRCULARIDADE',
                      style: AppTypography.metadataBadge(
                        color: AppColors.verdigrisInk,
                      ).copyWith(fontSize: 9.0, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
              Text(
                '${_analytics.activePercentage.toStringAsFixed(0)}% ATIVO',
                style: GoogleFonts.bodoniModa(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentCinnabar,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${_analytics.activePiecesCount} das ${_analytics.totalPieces} peças em circulação frequente',
            style: GoogleFonts.bodoniModa(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.inkText,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A indústria têxtil aponta que a maioria das pessoas usa menos de 1/3 do armário. '
            'Cada look que você aprova no Look do Dia conta como uso das peças dele; '
            'peças novas contam a partir do cadastro.',
            style: AppTypography.bodyReading().copyWith(color: AppColors.inkSecondary, fontSize: 12.0, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildRotationTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ROTAÇÃO DE ACERVO POR PERÍODO (3.2.2)',
          style: AppTypography.metadataBadge(color: AppColors.inkSecondary).copyWith(fontSize: 10, letterSpacing: 1.0),
        ),
        const SizedBox(height: 12),
        // Barra proporcional contínua
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                _buildSegmentBar(_analytics.activePiecesCount, AppColors.verdigrisInk),
                _buildSegmentBar(_analytics.idle30DaysCount, _idle30Color),
                _buildSegmentBar(_analytics.idle60DaysCount, AppColors.gildedInk),
                _buildSegmentBar(_analytics.idle90DaysCount, AppColors.accentCinnabar),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Grid de janelas de tempo
        Row(
          children: [
            Expanded(
              child: _buildTimeWindowCard(
                title: 'Em uso (<30d)',
                count: _analytics.activePiecesCount,
                color: AppColors.verdigrisInk,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTimeWindowCard(
                title: 'Atenção (30–60d)',
                count: _analytics.idle30DaysCount,
                color: _idle30Color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTimeWindowCard(
                title: 'Ociosas (60–90d)',
                count: _analytics.idle60DaysCount,
                color: AppColors.gildedInk,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTimeWindowCard(
                title: 'Dormindo (>90d)',
                count: _analytics.idle90DaysCount,
                color: AppColors.accentCinnabar,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSegmentBar(int count, Color color) {
    if (_analytics.totalPieces == 0) return const SizedBox();
    final flex = count;
    if (flex == 0) return const SizedBox();
    return Expanded(
      flex: flex,
      child: Container(color: color),
    );
  }

  Widget _buildTimeWindowCard({required String title, required int count, required Color color}) {
    final pct = _analytics.totalPieces > 0 ? (count / _analytics.totalPieces) * 100 : 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.paperBoneRaised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.hairlineInk, width: 0.6),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.interTight(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count peças (${pct.toStringAsFixed(0)}%)',
                  style: GoogleFonts.interTight(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChromaticDistributionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              'PROPORÇÃO CROMÁTICA DOMINANTE (CIE LAB*)',
              style: AppTypography.metadataBadge(
                color: AppColors.inkSecondary,
              ).copyWith(fontSize: 10, letterSpacing: 1.0),
            ),
            Text(
              '${_analytics.totalWears} ${_analytics.totalWears == 1 ? 'uso registrado' : 'usos registrados'}',
              style: AppTypography.bodySmall(color: AppColors.inkSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paperBoneRaised,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(color: AppColors.hairlineInk, width: 0.8),
          ),
          child: Column(
            children: _analytics.colorDistribution.map((c) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.hairlineInk, width: 0.8),
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
                                c.colorName,
                                style: GoogleFonts.interTight(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkText,
                                ),
                              ),
                              Text(
                                '${c.percentage.toStringAsFixed(0)}%',
                                style: GoogleFonts.interTight(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.inkText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            c.labCoordinates,
                            style: GoogleFonts.interTight(fontSize: 10, color: AppColors.inkSecondary),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: c.percentage / 100.0,
                              minHeight: 4,
                              backgroundColor: AppColors.paperBone,
                              valueColor: AlwaysStoppedAnimation<Color>(c.color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDormantPiecesSection() {
    final dormant = _analytics.dormantItems;
    if (dormant.isEmpty) {
      return Text(
        'Nenhuma peça está há mais de 90 dias sem uso. O armário inteiro está em rotação.',
        style: AppTypography.bodyReading().copyWith(color: AppColors.inkSecondary),
      );
    }

    final cacheWidth = (150 * MediaQuery.devicePixelRatioOf(context)).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RESGATE DE PATRIMÔNIO OCIOSO',
          style: AppTypography.metadataBadge(
            color: AppColors.accentCinnabar,
          ).copyWith(fontSize: 9.5, letterSpacing: 1.0),
        ),
        const SizedBox(height: 2),
        Text(
          '${dormant.length} ${dormant.length == 1 ? 'peça esquecida' : 'peças esquecidas'} no armário',
          style: GoogleFonts.bodoniModa(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.inkText),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: dormant.length,
            itemBuilder: (context, index) {
              final garment = dormant[index];
              final piece = garment.item;
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.paperBoneRaised,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(color: AppColors.hairlineInk, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Center(
                        child: piece.imageUrl.isNotEmpty
                            ? Image.network(
                                piece.imageUrl,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                                cacheWidth: cacheWidth,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.checkroom, color: AppColors.inkSecondary, size: 32),
                              )
                            : const Icon(Icons.checkroom, color: AppColors.inkSecondary, size: 32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      piece.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.interTight(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      garment.idleLabel,
                      maxLines: 2,
                      style: GoogleFonts.interTight(
                        fontSize: 10.5,
                        color: AppColors.accentCinnabar,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
