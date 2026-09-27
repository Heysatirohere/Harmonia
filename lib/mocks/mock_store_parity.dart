import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../models/store_parity_result.dart';
import 'mock_clothes.dart';

class MockStoreParity {
  static final StoreParityResult sample = StoreParityResult(
    storeGarment: const ClothingItem(
      id: 'store_blazer_01',
      name: 'Blazer Linho Terracota',
      category: 'Blazer',
      dominantColor: Color(0xFFA34836),
      labColorSpace: 'L* 45.2, a* 32.1, b* 24.8',
      usageRate: 0,
      imageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600',
      brandOrProvenance: 'Lojas Renner',
      price: 259.90,
      storeNameOverride: 'Lojas Renner',
    ),
    overallScore: 0.86,
    editorialSummary: 'O Blazer Linho Terracota apresenta alta paridade morfológica e cromática com 3 peças chave do seu acervo. Destrava 8 novas combinações para ocasiões de trabalho e casual chic.',
    compatibleMatches: [
      ParityMatchItem(
        closetItem: mockClothes[0],
        harmonyScore: 0.92,
        rationale: 'Contraste caloroso de linho natural com linho terracota.',
        swatchColors: const [Color(0xFFFBF9F5), Color(0xFFA34836)],
        chromaticScore: 0.94,
        morphologicalScore: 0.90,
      ),
      ParityMatchItem(
        closetItem: mockClothes[1],
        harmonyScore: 0.85,
        rationale: 'Harmonia análoga terrosa de alfaiataria.',
        swatchColors: const [Color(0xFFD9CDBF), Color(0xFFA34836)],
        chromaticScore: 0.88,
        morphologicalScore: 0.82,
      ),
      ParityMatchItem(
        closetItem: mockClothes[2],
        harmonyScore: 0.78,
        rationale: 'Complementaridade sutil com verde oliva.',
        swatchColors: const [Color(0xFF4B5842), Color(0xFFA34836)],
        chromaticScore: 0.80,
        morphologicalScore: 0.76,
      ),
    ],
  );
}
