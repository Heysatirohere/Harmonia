import 'package:flutter/material.dart';

import '../../models/clothing_item.dart';
import '../../models/wardrobe_filters.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_widgets.dart';
import 'ink_chip.dart';

/// Folha "Refinar" do acervo (RF06): cor, formalidade e frequência de uso.
/// Cada toque já filtra a arara atrás da folha; fechar não exige confirmação.
class WardrobeFilterSheet extends StatefulWidget {
  final List<ClothingItem> items;
  final WardrobeFilters initial;
  final ValueChanged<WardrobeFilters> onChanged;

  const WardrobeFilterSheet({super.key, required this.items, required this.initial, required this.onChanged});

  static Future<void> show(
    BuildContext context, {
    required List<ClothingItem> items,
    required WardrobeFilters filters,
    required ValueChanged<WardrobeFilters> onChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.tapestryNoir.withValues(alpha: 0.55),
      isScrollControlled: true,
      builder: (_) => WardrobeFilterSheet(items: items, initial: filters, onChanged: onChanged),
    );
  }

  @override
  State<WardrobeFilterSheet> createState() => _WardrobeFilterSheetState();
}

class _WardrobeFilterSheetState extends State<WardrobeFilterSheet> {
  late WardrobeFilters _filters = widget.initial;

  /// Só as famílias que existem no acervo, da mais frequente para a menos
  late final List<String> _families = () {
    final counts = <String, int>{};
    for (final item in widget.items) {
      final family = item.colorFamily;
      if (family != null) counts[family] = (counts[family] ?? 0) + 1;
    }
    return counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  }();

  void _update(WardrobeFilters filters) {
    setState(() => _filters = filters);
    widget.onChanged(filters);
  }

  Widget _section(String title, List<Widget> chips) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.metadataBadge()),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final count = widget.items.where(_filters.matches).length;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: AtelierSheet(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Refinar acervo', style: AppTypography.editorialTitleMedium()),
                const SizedBox(height: 20),
                if (_families.isNotEmpty)
                  _section('COR', [
                    for (final family in _families)
                      InkChip(
                        label: family,
                        selected: _filters.colorFamilies.contains(family),
                        onTap: () => _update(_filters.toggleColor(family)),
                      ),
                  ]),
                _section('FORMALIDADE', [
                  for (final band in FormalityBand.values)
                    InkChip(
                      label: band.label,
                      selected: _filters.formality.contains(band),
                      onTap: () => _update(_filters.toggleFormality(band)),
                    ),
                ]),
                _section('FREQUÊNCIA DE USO', [
                  for (final band in UsageBand.values)
                    InkChip(
                      label: band.label,
                      selected: _filters.usage.contains(band),
                      onTap: () => _update(_filters.toggleUsage(band)),
                    ),
                ]),
                const Divider(color: AppColors.hairlineInk, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        count == 1 ? '1 peça' : '$count peças',
                        style: AppTypography.uiHeadline(),
                      ),
                    ),
                    if (!_filters.isEmpty)
                      TextButton(
                        onPressed: () => _update(WardrobeFilters.none),
                        child: Text('Limpar', style: AppTypography.uiHeadline(color: AppColors.accentCinnabar)),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Ver peças', style: AppTypography.uiHeadline()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
