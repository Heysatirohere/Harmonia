import 'package:flutter/material.dart';

/// Modelo de Peça do Acervo Pessoal / Guarda-Roupa Virtual
class ClothingItem {
  final String id;
  final String title;
  final String category;
  final String provenance;
  final Color dominantColor;
  final String? esgTag;
  final String? imageUrl;
  final int timesWorn;

  const ClothingItem({
    required this.id,
    required this.title,
    required this.category,
    required this.provenance,
    required this.dominantColor,
    this.esgTag,
    this.imageUrl,
    this.timesWorn = 0,
  });
}
