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
}
