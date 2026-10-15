import 'clothing_item.dart';

/// Faixas de formalidade do filtro, sobre o grau de 0.0 (casual) a 1.0 (formal)
enum FormalityBand {
  casual('Casual'),
  balanced('Equilibrada'),
  formal('Formal');

  const FormalityBand(this.label);
  final String label;

  bool contains(double score) => switch (this) {
        FormalityBand.casual => score < 0.35,
        FormalityBand.balanced => score >= 0.35 && score <= 0.65,
        FormalityBand.formal => score > 0.65,
      };
}

/// Frequência de uso, com as janelas de ociosidade do dashboard (Seção 3.2.2)
enum UsageBand {
  active('Usadas no mês'),
  idle('Ociosas 30+ dias'),
  dormant('Adormecidas 90+ dias'),
  neverWorn('Nunca usadas');

  const UsageBand(this.label);
  final String label;

  bool contains(ClothingItem item) {
    final idle = item.daysIdle;
    return switch (this) {
      UsageBand.active => idle != null && idle < 30,
      UsageBand.idle => idle != null && idle >= 30 && idle < 90,
      UsageBand.dormant => idle != null && idle >= 90,
      UsageBand.neverWorn => item.usageRate == 0,
    };
  }
}

/// Filtros multicritério do acervo (RF06, Seção 3.2.1), aplicados sobre as peças já carregadas.
/// Dentro de um critério, as opções se somam (azuis ou verdes); entre critérios, todas valem.
class WardrobeFilters {
  final Set<String> colorFamilies;
  final Set<FormalityBand> formality;
  final Set<UsageBand> usage;

  const WardrobeFilters({this.colorFamilies = const {}, this.formality = const {}, this.usage = const {}});

  static const none = WardrobeFilters();

  bool get isEmpty => colorFamilies.isEmpty && formality.isEmpty && usage.isEmpty;

  int get activeCount => colorFamilies.length + formality.length + usage.length;

  bool matches(ClothingItem item) {
    if (colorFamilies.isNotEmpty && !colorFamilies.contains(item.colorFamily)) return false;
    if (formality.isNotEmpty) {
      final score = item.formalityScore;
      if (score == null || !formality.any((band) => band.contains(score))) return false;
    }
    if (usage.isNotEmpty && !usage.any((band) => band.contains(item))) return false;
    return true;
  }

  WardrobeFilters toggleColor(String family) => WardrobeFilters(
        colorFamilies: _toggle(colorFamilies, family),
        formality: formality,
        usage: usage,
      );

  WardrobeFilters toggleFormality(FormalityBand band) => WardrobeFilters(
        colorFamilies: colorFamilies,
        formality: _toggle(formality, band),
        usage: usage,
      );

  WardrobeFilters toggleUsage(UsageBand band) => WardrobeFilters(
        colorFamilies: colorFamilies,
        formality: formality,
        usage: _toggle(usage, band),
      );

  static Set<T> _toggle<T>(Set<T> set, T value) => set.contains(value) ? ({...set}..remove(value)) : {...set, value};
}
