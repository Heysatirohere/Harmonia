import 'package:flutter/material.dart';

import '../core/color/lab_color.dart';
import 'clothing_item.dart';

/// Peça seminova anunciada no Brechó Circular C2C (Seção 3.5.4 da Documentação)
class CircularListing {
  final String itemId;
  final String title;
  final String category;
  final String imageUrl;
  final double dominantL;
  final double dominantA;
  final double dominantB;
  final String colorHex;
  final String colorFamily;
  final String? cutType;
  final double suggestedPriceBrl;
  final double paletteCompatibility; // 0.0 a 1.0 (S_cor no espaço CIE L*a*b*)
  final bool isOwnListing;

  const CircularListing({
    required this.itemId,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.dominantL,
    required this.dominantA,
    required this.dominantB,
    required this.colorHex,
    required this.colorFamily,
    this.cutType,
    required this.suggestedPriceBrl,
    required this.paletteCompatibility,
    this.isOwnListing = false,
  });

  Color get dominantColor => hexToColor(colorHex);
  String get labLabel => formatLab(dominantL, dominantA, dominantB);
  int get compatibilityPercent => (paletteCompatibility * 100).round();
  bool get isHighHarmony => paletteCompatibility >= 0.75;
  String get formattedPrice => 'R\$ ${suggestedPriceBrl.toStringAsFixed(2).replaceAll('.', ',')}';

  factory CircularListing.fromJson(Map<String, dynamic> json) {
    final l = (json['dominant_l'] as num).toDouble();
    final a = (json['dominant_a'] as num).toDouble();
    final b = (json['dominant_b'] as num).toDouble();
    return CircularListing(
      itemId: json['item_id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      dominantL: l,
      dominantA: a,
      dominantB: b,
      colorHex: json['color_hex'] as String? ?? '#A34836',
      colorFamily: json['color_family'] as String? ?? 'Neutros',
      cutType: json['cut_type'] as String?,
      suggestedPriceBrl: (json['suggested_price_brl'] as num).toDouble(),
      paletteCompatibility: (json['palette_compatibility'] as num).toDouble(),
      isOwnListing: (json['is_own_listing'] as bool?) ?? false,
    );
  }

  /// Converte uma peça própria marcada com disposalStatus == 'SELL' em anúncio circular
  factory CircularListing.fromClothingItem(ClothingItem item, {bool isOwnListing = true}) {
    final (l, a, b) = item.labCoordinates;
    final rawPrice = item.price;
    final suggestedPrice = (rawPrice != null && rawPrice > 0) ? (rawPrice * 0.6) : 89.90;
    final score = item.iheScore != null ? (item.iheScore! / 100.0).clamp(0.0, 1.0) : 0.88;
    return CircularListing(
      itemId: item.id,
      title: item.name,
      category: item.category,
      imageUrl: item.imageUrl,
      dominantL: l,
      dominantA: a,
      dominantB: b,
      colorHex: '#${item.dominantColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
      colorFamily: item.colorFamily ?? 'Tons de Ateliê',
      cutType: item.cutType,
      suggestedPriceBrl: suggestedPrice,
      paletteCompatibility: score,
      isOwnListing: isOwnListing,
    );
  }

  ClothingItem toClothingItem({String disposalStatus = 'ACTIVE'}) {
    return ClothingItem(
      id: isOwnListing ? itemId : 'circular-$itemId',
      name: title,
      category: category,
      dominantColor: dominantColor,
      labColorSpace: labLabel,
      labL: dominantL,
      labA: dominantA,
      labB: dominantB,
      usageRate: 1,
      imageUrl: imageUrl,
      brandOrProvenance: isOwnListing ? 'Acervo Pessoal' : 'Brechó Circular HarmonIA • C2C',
      isConsciousFashion: true,
      consciousNote: 'Reuso Circular C2C • Compatibilidade $compatibilityPercent%',
      iheScore: compatibilityPercent,
      price: suggestedPriceBrl,
      cutType: cutType,
      colorFamily: colorFamily,
      disposalStatus: disposalStatus,
    );
  }

  static const List<CircularListing> demoListings = [
    CircularListing(
      itemId: 'circ-1',
      title: 'Blazer Alfaiataria Linho Terracota',
      category: 'Partes de cima',
      imageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600&auto=format&fit=crop&q=80',
      dominantL: 54.0,
      dominantA: 30.0,
      dominantB: 26.0,
      colorHex: '#A34836',
      colorFamily: 'Terracota e Terras',
      cutType: 'ACINTURADO',
      suggestedPriceBrl: 149.90,
      paletteCompatibility: 0.94,
    ),
    CircularListing(
      itemId: 'circ-2',
      title: 'Pantalona Fluida Seda Off-White',
      category: 'Partes de baixo',
      imageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&auto=format&fit=crop&q=80',
      dominantL: 92.0,
      dominantA: 1.0,
      dominantB: 5.0,
      colorHex: '#EBE6DC',
      colorFamily: 'Neutros e Marfim',
      cutType: 'PANTALONA',
      suggestedPriceBrl: 129.90,
      paletteCompatibility: 0.91,
    ),
    CircularListing(
      itemId: 'circ-3',
      title: 'Sobrecamisa Cânhamo Verde Oliva',
      category: 'Partes de cima',
      imageUrl: 'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=600&auto=format&fit=crop&q=80',
      dominantL: 39.0,
      dominantA: -12.0,
      dominantB: 15.0,
      colorHex: '#4B5842',
      colorFamily: 'Verdes Musgo',
      cutType: 'RETO',
      suggestedPriceBrl: 114.90,
      paletteCompatibility: 0.87,
    ),
    CircularListing(
      itemId: 'circ-4',
      title: 'Mocassim Artesanal Couro Caramelo',
      category: 'Calçados',
      imageUrl: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=600&auto=format&fit=crop&q=80',
      dominantL: 46.0,
      dominantA: 16.0,
      dominantB: 31.0,
      colorHex: '#8C5E37',
      colorFamily: 'Caramelo e Ocre',
      cutType: 'RETO',
      suggestedPriceBrl: 139.90,
      paletteCompatibility: 0.84,
    ),
    CircularListing(
      itemId: 'circ-5',
      title: 'Vestido Envelope Crepe Vinho',
      category: 'Peças únicas',
      imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600&auto=format&fit=crop&q=80',
      dominantL: 28.0,
      dominantA: 36.0,
      dominantB: 12.0,
      colorHex: '#6B212E',
      colorFamily: 'Bordô e Vinho',
      cutType: 'VESTIDO_ENVELOPE',
      suggestedPriceBrl: 159.90,
      paletteCompatibility: 0.79,
    ),
  ];
}
