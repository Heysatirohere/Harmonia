import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../mocks/mock_clothes.dart';
import '../../models/clothing_item.dart';
import '../../models/wardrobe_analytics.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_room.dart';
import '../atelier/atelier_widgets.dart';
import '../atelier/room_scene.dart';

/// Tela do Dashboard Analítico de Rotação de Acervo & ESG (Seção 3.2.2 da Doc)
///
/// Monitora a saúde do guarda-roupa pessoal, taxa de ociosidade (30, 60 e 90 dias),
/// proporção cromática dominante e rotinas de reativação de peças esquecidas.
class WardrobeAnalyticsScreen extends StatefulWidget {
  final List<ClothingItem>? items;

  const WardrobeAnalyticsScreen({super.key, this.items});

  @override
  State<WardrobeAnalyticsScreen> createState() => _WardrobeAnalyticsScreenState();
}

class _WardrobeAnalyticsScreenState extends State<WardrobeAnalyticsScreen> {
  /// Cor de dado (não é token de interface): areia escurecida, visível sobre o papel
  static const _idle30Color = Color(0xFFA89170);

  late final WardrobeAnalytics _analytics;

  @override
  void initState() {
    super.initState();
    final sourceItems = widget.items ?? mockClothes;
    _analytics = WardrobeAnalytics.fromItems(sourceItems);
  }

  void _handleReactivatePiece(ClothingItem item) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ReactivateGarmentSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget section(Widget child, {bool sheet = true}) => SliverPadding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin, 0, AppSpacing.pageMargin, 20),
      sliver: SliverToBoxAdapter(child: sheet ? AtelierSheet(child: child) : child),
    );

    // Ocre dourado no diagnóstico e nas métricas; verdete na reativação das peças adormecidas
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
                subtitle: 'Rotação, ociosidade e custo por uso',
                room: AtelierRoom.gildedOchre,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            // 1. Diagnóstico ESG & rotação (já é uma folha)
            section(_buildEsgHealthSummaryCard(), sheet: false),
            // 2. Ociosidade (30, 60, 90 dias)
            section(_buildRotationTimelineSection()),
            // 3. Proporção cromática dominante (CIE L*a*b*)
            section(_buildChromaticDistributionSection()),
            // 4. Custo por uso & capital ocioso (já é uma folha)
            section(_buildFinancialMetricsSection(), sheet: false),
            // 5. Reativação de peças adormecidas (>90 dias)
            const RoomMarker(room: AtelierRoom.verdigris),
            const SliverToBoxAdapter(
              child: RoomSectionTitle(title: 'Peças adormecidas', meta: '> 90 dias'),
            ),
            section(_buildDormantPiecesSection()),
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.sizeOf(context).height * 0.4)),
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
            'A indústria têxtil aponta que a maioria das pessoas usa menos de 1/3 do armário. O HarmonIA propõe novas coordenações para elevar a sua rotação para mais de 75%.',
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
                title: 'Ativas (<30d)',
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
            const Text(
              '✦ Cartela Outono',
              style: TextStyle(fontSize: 11, color: AppColors.gildedInk, fontWeight: FontWeight.w600),
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

  Widget _buildFinancialMetricsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paperBone,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.hairlineInk, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.gildedInk),
              const SizedBox(width: 8),
              Text(
                'MÉTRICA PATRIMONIAL & CUSTO POR USO',
                style: AppTypography.metadataBadge(
                  color: AppColors.gildedInk,
                ).copyWith(fontSize: 9.5, letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custo Médio / Uso',
                      style: GoogleFonts.interTight(fontSize: 11, color: AppColors.inkSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${_analytics.averageCostPerWear.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: GoogleFonts.bodoniModa(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.hairlineInk),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capital Ocioso Parado',
                      style: GoogleFonts.interTight(fontSize: 11, color: AppColors.inkSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${_analytics.estimatedIdleCapital.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: GoogleFonts.bodoniModa(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentCinnabar,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDormantPiecesSection() {
    if (_analytics.dormantItems.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REATIVAR PEÇAS ADORMECIDAS (>90D)',
                  style: AppTypography.metadataBadge(
                    color: AppColors.accentCinnabar,
                  ).copyWith(fontSize: 9.5, letterSpacing: 1.0),
                ),
                const SizedBox(height: 2),
                Text(
                  'Resgate de Patrimônio Ocioso',
                  style: GoogleFonts.bodoniModa(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.inkText),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _analytics.dormantItems.length,
            itemBuilder: (context, index) {
              final piece = _analytics.dormantItems[index];
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          color: AppColors.paperBone,
                          child: Center(
                            child: piece.imageUrl.isNotEmpty
                                ? Image.network(
                                    piece.imageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.checkroom, color: AppColors.inkSecondary, size: 32),
                                  )
                                : const Icon(Icons.checkroom, color: AppColors.inkSecondary, size: 32),
                          ),
                        ),
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
                      'Sem uso recente',
                      style: GoogleFonts.interTight(
                        fontSize: 10,
                        color: AppColors.accentCinnabar,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: OutlinedButton(
                        onPressed: () => _handleReactivatePiece(piece),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: const BorderSide(color: AppColors.accentCinnabar, width: 0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text(
                          'Reativar Look',
                          style: GoogleFonts.interTight(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentCinnabar,
                          ),
                        ),
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

/// Modal Curatorial para reativação de peça esquecida
class _ReactivateGarmentSheet extends StatelessWidget {
  final ClothingItem item;

  const _ReactivateGarmentSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.paperBone,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: AppColors.hairlineInk, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'REATIVAÇÃO DE PATRIMÔNIO (ESG)',
            style: AppTypography.metadataBadge(
              color: AppColors.verdigrisInk,
            ).copyWith(fontSize: 9.5, letterSpacing: 1.0),
          ),
          const SizedBox(height: 6),
          Text(
            'Coordenar "${item.name}"',
            style: GoogleFonts.bodoniModa(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.inkText),
          ),
          const SizedBox(height: 8),
          Text(
            'Esta peça está classificada como adormecida no seu acervo (>90 dias). O motor do IHE sugere combiná-la com tons neutros em linho ou areia suave para reinseri-la na sua rotina matinal.',
            style: AppTypography.bodyReading().copyWith(color: AppColors.inkSecondary, fontSize: 12.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.tapestryNoir,
                    content: Text(
                      'Combinação de reativação gerada com sucesso!',
                      style: GoogleFonts.interTight(color: AppColors.ivoryText),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: Text(
                'Gerar Look com Esta Peça',
                style: GoogleFonts.interTight(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCinnabar,
                foregroundColor: AppColors.ivoryText,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
