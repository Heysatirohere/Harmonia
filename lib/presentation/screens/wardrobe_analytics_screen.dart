import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../mocks/mock_clothes.dart';
import '../../models/clothing_item.dart';
import '../../models/wardrobe_analytics.dart';
import '../../theme/app_theme.dart';
import '../widgets/ihe_score_gauge.dart';

/// Tela do Dashboard Analítico de Rotação de Acervo & ESG (Seção 3.2.2 da Doc)
///
/// Monitora a saúde do guarda-roupa pessoal, taxa de ociosidade (30, 60 e 90 dias),
/// proporção cromática dominante e rotinas de reativação de peças esquecidas.
class WardrobeAnalyticsScreen extends StatefulWidget {
  final List<ClothingItem>? items;

  const WardrobeAnalyticsScreen({
    super.key,
    this.items,
  });

  @override
  State<WardrobeAnalyticsScreen> createState() => _WardrobeAnalyticsScreenState();
}

class _WardrobeAnalyticsScreenState extends State<WardrobeAnalyticsScreen> {
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
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INTELIGÊNCIA PATRIMONIAL & ESG',
              style: AppTypography.metadataBadge(color: AppColors.accentOlive).copyWith(
                fontSize: 9.0,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Saúde do Guarda-Roupa',
              style: AppTypography.displayEditorial().copyWith(
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CARD PRINCIPAL DE DIAGNÓSTICO ESG & ROTAÇÃO
              _buildEsgHealthSummaryCard(),

              const SizedBox(height: 24),

              // 2. INDICADOR MULTICRITÉRIO DE OCIOSIDADE (30, 60, 90 DIAS)
              _buildRotationTimelineSection(),

              const SizedBox(height: 28),

              // 3. MAPA DE PROPORÇÃO CROMÁTICA DOMINANTE (CIE L*a*b*)
              _buildChromaticDistributionSection(),

              const SizedBox(height: 28),

              // 4. MÉTRICAS FINANCEIRAS: CUSTO POR USO & CAPITAL OCIOSO
              _buildFinancialMetricsSection(),

              const SizedBox(height: 28),

              // 5. VITRINE DE REATIVAÇÃO DE PEÇAS ADORMECIDAS (>90 DIAS)
              _buildDormantPiecesSection(),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEsgHealthSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderSubtle, width: 0.8),
        boxShadow: AppColors.editorialShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentOlive.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentOlive.withValues(alpha: 0.3), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.eco_outlined, color: AppColors.accentOlive, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'DIRETRIZ ESG & CIRCULARIDADE',
                      style: AppTypography.metadataBadge(color: AppColors.accentOlive).copyWith(
                        fontSize: 9.0,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_analytics.activePercentage.toStringAsFixed(0)}% ATIVO',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentTerracotta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${_analytics.activePiecesCount} das ${_analytics.totalPieces} peças em circulação frequente',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A indústria têxtil aponta que a maioria das pessoas usa menos de 1/3 do armário. O HarmonIA propõe novas coordenações para elevar a sua rotação para mais de 75%.',
            style: AppTypography.bodyReading().copyWith(
              color: AppColors.textSecondary,
              fontSize: 12.0,
              height: 1.45,
            ),
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
          style: AppTypography.metadataBadge(color: AppColors.textSecondary).copyWith(
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        // Barra proporcional contínua
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                _buildSegmentBar(_analytics.activePiecesCount, AppColors.accentOlive),
                _buildSegmentBar(_analytics.idle30DaysCount, AppColors.accentSand),
                _buildSegmentBar(_analytics.idle60DaysCount, AppColors.iheGold),
                _buildSegmentBar(_analytics.idle90DaysCount, AppColors.accentTerracotta),
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
                color: AppColors.accentOlive,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTimeWindowCard(
                title: 'Atenção (30–60d)',
                count: _analytics.idle30DaysCount,
                color: AppColors.accentSand,
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
                color: AppColors.iheGold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTimeWindowCard(
                title: 'Dormindo (>90d)',
                count: _analytics.idle90DaysCount,
                color: AppColors.accentTerracotta,
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

  Widget _buildTimeWindowCard({
    required String title,
    required int count,
    required Color color,
  }) {
    final pct = _analytics.totalPieces > 0 ? (count / _analytics.totalPieces) * 100 : 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderSubtle, width: 0.6),
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count peças (${pct.toStringAsFixed(0)}%)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROPORÇÃO CROMÁTICA DOMINANTE (CIE LAB*)',
              style: AppTypography.metadataBadge(color: AppColors.textSecondary).copyWith(
                fontSize: 10,
                letterSpacing: 1.0,
              ),
            ),
            const Text(
              '✦ Cartela Outono',
              style: TextStyle(fontSize: 11, color: AppColors.iheGold, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(color: AppColors.borderSubtle, width: 0.8),
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
                        border: Border.all(color: AppColors.borderSubtle, width: 0.8),
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
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${c.percentage.toStringAsFixed(0)}%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            c.labCoordinates,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: c.percentage / 100.0,
                              minHeight: 4,
                              backgroundColor: AppColors.surfaceSubtle,
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
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderGold, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.iheGold),
              const SizedBox(width: 8),
              Text(
                'MÉTRICA PATRIMONIAL & CUSTO POR USO',
                style: AppTypography.metadataBadge(color: AppColors.iheGold).copyWith(
                  fontSize: 9.5,
                  letterSpacing: 1.0,
                ),
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${_analytics.averageCostPerWear.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.borderSubtle),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capital Ocioso Parado',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${_analytics.estimatedIdleCapital.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentTerracotta,
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
                  style: AppTypography.metadataBadge(color: AppColors.accentTerracotta).copyWith(
                    fontSize: 9.5,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Resgate de Patrimônio Ocioso',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
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
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(color: AppColors.borderSubtle, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          color: AppColors.surfaceSubtle,
                          child: Center(
                            child: piece.imageUrl.isNotEmpty
                                ? Image.network(
                                    piece.imageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.checkroom,
                                      color: AppColors.textMuted,
                                      size: 32,
                                    ),
                                  )
                                : const Icon(Icons.checkroom, color: AppColors.textMuted, size: 32),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      piece.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sem uso recente',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppColors.accentTerracotta,
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
                          side: const BorderSide(color: AppColors.accentTerracotta, width: 0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text(
                          'Reativar Look',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentTerracotta,
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
        color: AppColors.surfaceCanvas,
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
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'REATIVAÇÃO DE PATRIMÔNIO (ESG)',
            style: AppTypography.metadataBadge(color: AppColors.accentOlive).copyWith(
              fontSize: 9.5,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Coordenar "${item.name}"',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esta peça está classificada como adormecida no seu acervo (>90 dias). O motor do IHE sugere combiná-la com tons neutros em linho ou areia suave para reinseri-la na sua rotina matinal.',
            style: AppTypography.bodyReading().copyWith(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
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
                    backgroundColor: AppColors.textPrimary,
                    content: Text(
                      'Combinação de reativação gerada com sucesso!',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: Text(
                'Gerar Look com Esta Peça',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTerracotta,
                foregroundColor: Colors.white,
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
