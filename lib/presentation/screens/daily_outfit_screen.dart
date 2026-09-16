import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../mocks/mock_outfits.dart';
import '../../models/outfit_combination.dart';
import '../../theme/app_theme.dart';
import '../widgets/outfit_composition_card.dart';

/// Tela de Exibição / Sugestão Diária de Looks ("Daily Outfit Recommendation")
/// Conforme AGENTS.md:
/// - Estruturada com CustomScrollView e Slivers
/// - Cabeçalho editorial "Sugestão do Dia" em Playfair Display Italic
/// - Exibição em carrossel/pilha de combinações recomendadas com medidor IHE
class DailyOutfitScreen extends StatefulWidget {
  const DailyOutfitScreen({super.key});

  @override
  State<DailyOutfitScreen> createState() => _DailyOutfitScreenState();
}

class _DailyOutfitScreenState extends State<DailyOutfitScreen> {
  late List<OutfitCombination> _outfits;
  int _activeOutfitIndex = 0;

  @override
  void initState() {
    super.initState();
    _outfits = List.from(mockOutfits);
  }

  void _onApproveOutfit(OutfitCombination outfit) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.iheGold, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Look "${outfit.title}" aprovado para o seu dia!',
                style: AppTypography.bodyReading(color: AppColors.surfaceCanvas),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDiscardOutfit(OutfitCombination outfit) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_activeOutfitIndex < _outfits.length - 1) {
        _activeOutfitIndex++;
      } else {
        _activeOutfitIndex = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Cabeçalho Editorial: Sugestão do Dia & Data Formatada
            SliverToBoxAdapter(
              child: _buildEditorialHeader(context),
            ),

            // Bar de Contexto Climático & Formalidade Local
            SliverToBoxAdapter(
              child: _buildContextBanner(context),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),

            // Carrossel ou Pilha de Combinações do Dia
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final outfit = _outfits[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.elementGap * 1.5),
                      child: OutfitCompositionCard(
                        outfit: outfit,
                        onApprove: () => _onApproveOutfit(outfit),
                        onDiscard: () => _onDiscardOutfit(outfit),
                      ),
                    );
                  },
                  childCount: _outfits.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 48),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorialHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageMargin,
        MediaQuery.of(context).padding.top + 20,
        AppSpacing.pageMargin,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUARTA-FEIRA • 16 DE SETEMBRO',
                style: AppTypography.metadataBadge(
                  color: AppColors.accentTerracotta,
                ).copyWith(fontSize: 10, letterSpacing: 1.4),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle, width: 0.6),
                ),
                child: Text(
                  'PARIDADE PROVADOR',
                  style: AppTypography.metadataBadge(color: AppColors.textSecondary)
                      .copyWith(fontSize: 8.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Sugestão do Dia',
            style: AppTypography.subtitleCuratorial(color: AppColors.textPrimary).copyWith(
              fontSize: 32,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Harmonização morfocromática calculada para o seu acervo e agenda.',
            style: AppTypography.bodyReading(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContextBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.borderSubtle, width: 0.6),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.wb_sunny_outlined,
              size: 18,
              color: AppColors.iheGold,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CLIMA LOCAL & CONTEXTO',
                    style: AppTypography.metadataBadge(color: AppColors.textSecondary)
                        .copyWith(fontSize: 8.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '24°C Ensolarado • Ateliê & Eventos Culturais',
                    style: AppTypography.uiHeadline().copyWith(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceCanvas,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle, width: 0.6),
              ),
              child: Text(
                '3 LOOKS',
                style: AppTypography.metadataBadge(color: AppColors.textPrimary)
                    .copyWith(fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
