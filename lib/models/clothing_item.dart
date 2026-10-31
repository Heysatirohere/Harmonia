import 'package:flutter/material.dart';

import '../core/color/lab_color.dart';

/// Modelo de Dados da Peça de Vestuário no Inventário Virtual HarmonIA
/// Contém metadados editoriais de morfocromia (CIE Lab*), sustentabilidade e uso.
class ClothingItem {
  final String id;
  final String name;
  final String category; // 'Partes de cima', 'Partes de baixo', 'Calçados' ou 'Peças únicas'
  final Color dominantColor;
  final String labColorSpace; // Ex: 'L* 64.2, a* 22.8, b* 18.5'
  final int usageRate; // Quantidade de vezes em que a peça foi combinada/usada
  final String imageUrl; // URL da imagem segmentada em PNG com canal alfa transparente
  final String brandOrProvenance; // Ex: 'Linho Italiano', 'Brechó Vintage 1994'
  final bool isConsciousFashion; // Selo de consumo consciente / ESG
  final String? consciousNote; // Ex: '100% Cânhamo Sustentável'
  final int? iheScore; // Score IHE de harmonização pré-calculado
  final double? price;
  final String? storeNameOverride;
  final double? labL; // Coordenadas numéricas da cor dominante (persistidas na API)
  final double? labA;
  final double? labB;
  final double? formalityScore; // 0.0 (casual) a 1.0 (formal)
  final List<double>? styleEmbedding; // Vetor de estilo (512d) do recorte, só no cadastro; a API não o devolve
  final String? colorFamily; // Família cromática calculada pela API (ex: 'Azuis'), para o filtro por cor
  final int? daysIdle; // Dias desde o último uso (ou desde o cadastro), calculados pela API
  final String? pattern; // Estampa (ex: 'Liso', 'Listrado', 'Xadrez')
  final String? season; // Estação ('Todas', 'Verão', 'Inverno', 'Meia-estação')
  final String? thermalCategory; // Faixa térmica ('LEVE', 'MEDIA', 'PESADA')
  final String? cutType; // Corte morfológico (ex: 'Cintura Alta', 'Decote V', 'Reto')
  final String? disposalStatus; // Destinação consciente ESG ('ACTIVE', 'DONATE', 'SELL', 'RECYCLE')
  final List<String> capsules; // Coleções cápsula (ex: ['Trabalho', 'Viagem'])

  const ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.dominantColor,
    required this.labColorSpace,
    required this.usageRate,
    required this.imageUrl,
    required this.brandOrProvenance,
    this.isConsciousFashion = false,
    this.consciousNote,
    this.iheScore,
    this.price,
    this.storeNameOverride,
    this.labL,
    this.labA,
    this.labB,
    this.formalityScore,
    this.styleEmbedding,
    this.colorFamily,
    this.daysIdle,
    this.pattern,
    this.season,
    this.thermalCategory,
    this.cutType,
    this.disposalStatus,
    this.capsules = const [],
  });

  String get title => name;
  String get storeName => storeNameOverride ?? brandOrProvenance;
  String get provenance => brandOrProvenance;
  String get formattedPrice => price != null ? 'R\$ ${price!.toStringAsFixed(2).replaceAll('.', ',')}' : 'R\$ 259,90';

  /// Custo por Uso (CPU = Preço / Quantidade de usos, Seção 3.2.2)
  double? get costPerUse =>
      (price != null && price! > 0) ? (usageRate > 0 ? price! / usageRate : price!) : null;

  String? get formattedCostPerUse =>
      costPerUse != null ? 'R\$ ${costPerUse!.toStringAsFixed(2).replaceAll('.', ',')}/uso' : null;

  ClothingItem copyWith({
    String? id,
    String? name,
    String? category,
    Color? dominantColor,
    String? labColorSpace,
    int? usageRate,
    String? imageUrl,
    String? brandOrProvenance,
    bool? isConsciousFashion,
    String? consciousNote,
    int? iheScore,
    double? price,
    String? storeNameOverride,
    double? labL,
    double? labA,
    double? labB,
    double? formalityScore,
    List<double>? styleEmbedding,
    String? colorFamily,
    int? daysIdle,
    String? pattern,
    String? season,
    String? thermalCategory,
    String? cutType,
    String? disposalStatus,
    List<String>? capsules,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      dominantColor: dominantColor ?? this.dominantColor,
      labColorSpace: labColorSpace ?? this.labColorSpace,
      usageRate: usageRate ?? this.usageRate,
      imageUrl: imageUrl ?? this.imageUrl,
      brandOrProvenance: brandOrProvenance ?? this.brandOrProvenance,
      isConsciousFashion: isConsciousFashion ?? this.isConsciousFashion,
      consciousNote: consciousNote ?? this.consciousNote,
      iheScore: iheScore ?? this.iheScore,
      price: price ?? this.price,
      storeNameOverride: storeNameOverride ?? this.storeNameOverride,
      labL: labL ?? this.labL,
      labA: labA ?? this.labA,
      labB: labB ?? this.labB,
      formalityScore: formalityScore ?? this.formalityScore,
      styleEmbedding: styleEmbedding ?? this.styleEmbedding,
      colorFamily: colorFamily ?? this.colorFamily,
      daysIdle: daysIdle ?? this.daysIdle,
      pattern: pattern ?? this.pattern,
      season: season ?? this.season,
      thermalCategory: thermalCategory ?? this.thermalCategory,
      cutType: cutType ?? this.cutType,
      disposalStatus: disposalStatus ?? this.disposalStatus,
      capsules: capsules ?? this.capsules,
    );
  }

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    final subcat = json['subcategory'] as String?;
    final category = json['category'] as String? ?? 'Partes de cima';
    final dominantL = (json['dominant_l'] as num?)?.toDouble() ?? 55.0;
    final dominantA = (json['dominant_a'] as num?)?.toDouble() ?? 20.0;
    final dominantB = (json['dominant_b'] as num?)?.toDouble() ?? 15.0;

    return ClothingItem(
      id: json['id'] as String? ?? '',
      name: subcat ?? category,
      category: category,
      dominantColor: labToColor(dominantL, dominantA, dominantB),
      labColorSpace: formatLab(dominantL, dominantA, dominantB),
      labL: dominantL,
      labA: dominantA,
      labB: dominantB,
      formalityScore: (json['formality_score'] as num?)?.toDouble(),
      usageRate: (json['usage_rate'] as int?) ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
      brandOrProvenance: (json['brand'] as String?) ??
          (json['cut_type'] != null ? 'Corte ${json['cut_type']}' : 'Acervo Pessoal'),
      isConsciousFashion: (json['is_conscious_fashion'] as bool?) ?? false,
      consciousNote: (json['conscious_note'] as String?) ?? (json['fabric_composition'] as String?),
      iheScore: (json['ihe_score'] as num?)?.toInt(),
      price: (json['purchase_price'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble(),
      colorFamily: json['color_family'] as String?,
      daysIdle: (json['days_idle'] as num?)?.toInt(),
      pattern: json['pattern'] as String?,
      season: json['season'] as String?,
      thermalCategory: json['thermal_category'] as String?,
      cutType: json['cut_type'] as String?,
      disposalStatus: json['disposal_status'] as String?,
      capsules: (json['capsules'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  /// Coordenadas L*a*b* numéricas; peças antigas/mock só têm o rótulo em [labColorSpace].
  (double, double, double) get labCoordinates {
    if (labL != null && labA != null && labB != null) return (labL!, labA!, labB!);
    final values = RegExp(r'-?\d+(?:\.\d+)?')
        .allMatches(labColorSpace)
        .map((m) => double.parse(m.group(0)!))
        .toList();
    if (values.length != 3) {
      throw FormatException('Coordenadas L*a*b* ausentes na peça "$name": $labColorSpace');
    }
    return (values[0], values[1], values[2]);
  }

  Map<String, dynamic> toApiJson() {
    final (l, a, b) = labCoordinates;
    return {
      'category': category,
      'subcategory': name,
      'image_url': imageUrl,
      'dominant_l': l,
      'dominant_a': a,
      'dominant_b': b,
      'formality_score': formalityScore ?? 0.5,
      if (styleEmbedding != null) 'style_embedding': styleEmbedding,
      if (price != null) 'purchase_price': price,
      if (isConsciousFashion) 'is_conscious_fashion': isConsciousFashion,
      if (consciousNote != null && consciousNote!.isNotEmpty) 'fabric_composition': consciousNote,
      if (pattern != null && pattern!.isNotEmpty) 'pattern': pattern,
      if (season != null && season!.isNotEmpty) 'season': season,
      if (thermalCategory != null && thermalCategory!.isNotEmpty) 'thermal_category': thermalCategory,
      if (cutType != null && cutType!.isNotEmpty) 'cut_type': cutType,
      if (disposalStatus != null && disposalStatus!.isNotEmpty) 'disposal_status': disposalStatus,
      if (capsules.isNotEmpty) 'capsules': capsules,
    };
  }
}

