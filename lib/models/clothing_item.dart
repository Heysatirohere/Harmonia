import 'package:flutter/material.dart';

/// Modelo de Dados da Peça de Vestuário no Inventário Virtual HarmonIA
/// Contém metadados editoriais de morfocromia (CIE Lab*), sustentabilidade e uso.
class ClothingItem {
  final String id;
  final String name;
  final String category; // 'Partes de cima', 'Partes de baixo', 'Calçados', 'Ocasião', etc.
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
  });

  String get title => name;
  String get storeName => storeNameOverride ?? brandOrProvenance;
  String get provenance => brandOrProvenance;
  String get formattedPrice => price != null ? 'R\$ ${price!.toStringAsFixed(2).replaceAll('.', ',')}' : 'R\$ 259,90';

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
    );
  }

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    final subcat = json['subcategory'] as String?;
    final category = json['category'] as String? ?? 'Partes de cima';
    final dominantL = (json['dominant_l'] as num?)?.toDouble() ?? 55.0;
    final dominantA = (json['dominant_a'] as num?)?.toDouble() ?? 20.0;
    final dominantB = (json['dominant_b'] as num?)?.toDouble() ?? 15.0;

    final approxGrey = ((dominantL / 100.0) * 255).clamp(40, 240).toInt();
    final color = Color.fromARGB(255, (approxGrey + 10).clamp(0, 255), approxGrey, (approxGrey - 10).clamp(0, 255));

    return ClothingItem(
      id: json['id'] as String? ?? '',
      name: subcat ?? category,
      category: category,
      dominantColor: color,
      labColorSpace: 'L* ${dominantL.toStringAsFixed(1)}, a* ${dominantA.toStringAsFixed(1)}, b* ${dominantB.toStringAsFixed(1)}',
      usageRate: (json['usage_rate'] as int?) ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
      brandOrProvenance: json['cut_type'] != null ? 'Corte ${json['cut_type']}' : 'Acervo Pessoal',
      isConsciousFashion: true,
      consciousNote: 'Algodão e Linho Certificado',
      iheScore: (json['ihe_score'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'category': category,
      'subcategory': name,
      'image_url': imageUrl,
      'dominant_l': 58.4,
      'dominant_a': 28.2,
      'dominant_b': 24.1,
      'formality_score': 0.65,
      'cut_type': 'acinturado',
    };
  }
}

