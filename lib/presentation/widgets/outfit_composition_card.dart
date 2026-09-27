import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/clothing_item.dart';
import '../../models/outfit_combination.dart';
import '../../theme/app_theme.dart';
import 'ihe_score_gauge.dart';

/// Card Visual de Composição de Look Harmonizado
/// Conforme AGENTS.md:
/// - Fundo de tela estético com arara virtual ("The Floating Canvas")
/// - Exibição de peças recortadas em PNG (alfa transparente) sem BoxShadow retangular
/// - Integração com IheScoreGauge e decomposição analítica
/// - Microinteração de expansão com AppMotion.editorialDecel
/// - Botões de ação rápida com HapticFeedback (Aprovar em Terracota / Descartar)
class OutfitCompositionCard extends StatefulWidget {
  final OutfitCombination outfit;
  final VoidCallback? onApprove;
  final VoidCallback? onSave;
  final VoidCallback? onDiscard;

  const OutfitCompositionCard({
    super.key,
    required this.outfit,
    this.onApprove,
    this.onSave,
    this.onDiscard,
  });

  @override
  State<OutfitCompositionCard> createState() => _OutfitCompositionCardState();
}

class _OutfitCompositionCardState extends State<OutfitCompositionCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _handleApprove() {
    HapticFeedback.mediumImpact();
    widget.onApprove?.call();
  }

  void _handleDiscard() {
    HapticFeedback.selectionClick();
    widget.onDiscard?.call();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 0.8,
        ),
        boxShadow: AppColors.editorialShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabeçalho Editorial com Nome da Ocasião e Título
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.outfit.occasion.toUpperCase(),
                        style: AppTypography.metadataBadge(
                          color: AppColors.accentTerracotta,
                        ).copyWith(fontSize: 10, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.outfit.title,
                        style: AppTypography.displayEditorial().copyWith(
                          fontSize: 20,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _toggleExpanded,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCanvas,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderSubtle, width: 0.6),
                    ),
                    child: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: AppMotion.fast,
                      curve: AppMotion.editorialDecel,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Medidor Visual de Harmonia IHE Integrado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: IheScoreGauge(ihe: widget.outfit.ihe),
          ),

          const SizedBox(height: 16),

          // 3. Arara Virtual Flutuante de Silhuetas (Top + Bottom + Calçado)
          GestureDetector(
            onTap: _toggleExpanded,
            child: Container(
              height: 220,
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceCanvas,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 0.6,
                ),
              ),
              child: Row(
                children: [
                  // Peça Superior (Top)
                  Expanded(
                    child: _GarmentCanvasSlot(
                      item: widget.outfit.topItem,
                      dpr: dpr,
                      slotLabel: 'SUPERIOR',
                    ),
                  ),
                  Container(
                    width: 0.6,
                    height: 140,
                    color: AppColors.borderSubtle,
                  ),
                  // Peça Inferior (Bottom)
                  Expanded(
                    child: _GarmentCanvasSlot(
                      item: widget.outfit.bottomItem,
                      dpr: dpr,
                      slotLabel: 'INFERIOR',
                    ),
                  ),
                  Container(
                    width: 0.6,
                    height: 140,
                    color: AppColors.borderSubtle,
                  ),
                  // Calçado
                  Expanded(
                    child: _GarmentCanvasSlot(
                      item: widget.outfit.footwearItem,
                      dpr: dpr,
                      slotLabel: 'CALÇADO',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Seção Expansível com Citação Curatorial & Detalhes das Peças
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: 14),
                  Text(
                    'NOTA CURATORIAL',
                    style: AppTypography.metadataBadge(color: AppColors.textSecondary)
                        .copyWith(fontSize: 9.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.outfit.editorialNote,
                    style: AppTypography.bodyReading(),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'COMPOSIÇÃO TÊXTIL DO LOOK',
                    style: AppTypography.metadataBadge(color: AppColors.textSecondary)
                        .copyWith(fontSize: 9.5),
                  ),
                  const SizedBox(height: 8),
                  for (final garment in widget.outfit.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: garment.dominantColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              garment.name,
                              style: AppTypography.bodySmall(color: AppColors.textPrimary)
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            garment.brandOrProvenance,
                            style: AppTypography.bodySmall(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            crossFadeState:
                _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: AppMotion.medium,
            firstCurve: AppMotion.editorialDecel,
            secondCurve: AppMotion.editorialDecel,
          ),

          const SizedBox(height: 16),

          // 5. Botões de Ação Rápida (Aprovar em Terracota / Descartar)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              children: [
                // Botão Descartar
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _handleDiscard,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        ),
                      ),
                      child: Text(
                        'Passar Look',
                        style: AppTypography.uiHeadline(color: AppColors.textSecondary)
                            .copyWith(fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botão Aprovar Look
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _handleApprove,
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.surfaceCanvas,
                        size: 18,
                      ),
                      label: Text(
                        'Aprovar este Look',
                        style: AppTypography.uiHeadline(color: AppColors.surfaceCanvas)
                            .copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentTerracotta,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Slot da Peça Recortada na Arara Virtual do Card
class _GarmentCanvasSlot extends StatelessWidget {
  final ClothingItem item;
  final double dpr;
  final String slotLabel;

  const _GarmentCanvasSlot({
    required this.item,
    required this.dpr,
    required this.slotLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          slotLabel,
          style: AppTypography.metadataBadge(color: AppColors.textMuted)
              .copyWith(fontSize: 8.5, letterSpacing: 0.6),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final targetWidth = (constraints.maxWidth * dpr).round();
              final targetHeight = (constraints.maxHeight * dpr).round();

              return Center(
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium, // Reamostragem limpa conforme AGENTS.md
                  cacheWidth: targetWidth > 0 ? targetWidth : null,
                  cacheHeight: targetHeight > 0 ? targetHeight : null,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.checkroom_outlined,
                    color: AppColors.textMuted,
                    size: 24,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.name,
          style: AppTypography.bodySmall(color: AppColors.textPrimary)
              .copyWith(fontSize: 10, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
