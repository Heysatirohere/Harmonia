import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/clothing_item.dart';

/// Mocks do Guarda-Roupa Residencial do Usuário conforme AGENTS.md
class MockClothes {
  MockClothes._();

  static const List<ClothingItem> items = [
    ClothingItem(
      id: 'cloth_01',
      title: 'Pantalona Ampla Off-White',
      category: 'BASE INFERIOR',
      provenance: 'Ateliê Sustentável Local',
      dominantColor: AppColors.accentSand,
      esgTag: 'Algodão Orgânico',
      timesWorn: 18,
    ),
    ClothingItem(
      id: 'cloth_02',
      title: 'Regata Seda Areia',
      category: 'BASE SUPERIOR',
      provenance: 'Brechó Vintage Paulistano',
      dominantColor: Color(0xFFE5DCD3),
      esgTag: 'Segunda Mão Certificada',
      timesWorn: 12,
    ),
    ClothingItem(
      id: 'cloth_03',
      title: 'Saia Mídia Plissada Oliva',
      category: 'BASE INFERIOR',
      provenance: 'Acervo Herança de Família',
      dominantColor: AppColors.accentOlive,
      esgTag: 'Reaproveitamento Têxtil',
      timesWorn: 9,
    ),
    ClothingItem(
      id: 'cloth_04',
      title: 'Camisa Alfaiataria Creme',
      category: 'SUPERIOR SOBREPOSIÇÃO',
      provenance: 'Marca Autoral Sustentável',
      dominantColor: Color(0xFFF2ECE1),
      esgTag: '100% Linho Reciclado',
      timesWorn: 14,
    ),
    ClothingItem(
      id: 'cloth_05',
      title: 'Mocassim Couro Caramelo',
      category: 'CALÇADO',
      provenance: 'Sapataria Artesanal',
      dominantColor: Color(0xFF965638),
      esgTag: 'Produção Consciente',
      timesWorn: 22,
    ),
    ClothingItem(
      id: 'cloth_06',
      title: 'Trench Coat Bege Editorial',
      category: 'SOBREPOSIÇÃO PESADA',
      provenance: 'Brechó Internacional',
      dominantColor: Color(0xFFC7B299),
      esgTag: 'Segunda Mão Certificada',
      timesWorn: 6,
    ),
  ];
}
