import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/models/clothing_item.dart';
import 'package:harmonia_mvp/models/store_parity_result.dart';

const _storeGarment = ClothingItem(
  id: 'store-1',
  name: 'Parte de cima terracota',
  category: 'Partes de cima',
  dominantColor: Color(0xFFA34836),
  labColorSpace: 'L* 45.0, a* 32.0, b* 25.0',
  usageRate: 0,
  imageUrl: '',
  brandOrProvenance: 'Peça da loja',
);

Map<String, dynamic> _match(String id, double ihe) => {
      'item': {
        'id': id,
        'category': 'bottom',
        'subcategory': 'Pantalona',
        'image_url': 'https://example.com/$id.png',
        'dominant_l': 40.0,
        'dominant_a': 10.0,
        'dominant_b': 15.0,
        'formality_score': 0.5,
      },
      'ihe_percentage': ihe,
      's_cor': 0.82,
      's_bio': 0.9,
      'is_strongly_recommended': ihe >= 75,
      'rationale': 'Cores em harmonia com a sua cartela.',
    };

void main() {
  group('StoreParityResult (RF08/RF09)', () {
    test('lê o ranking da API', () {
      final result = StoreParityResult.fromJson({
        'ihe_percentage': 81.6,
        'is_strongly_recommended': true,
        'palette_harmony': 0.74,
        'styling_advice': 'Coordenação equilibrada.',
        'looks_evaluated': 3,
        'strong_looks': 2,
        'matches': [_match('a', 81.6), _match('b', 70.2)],
      }, storeGarment: _storeGarment);

      expect(result.formattedOverallScore, '82%');
      expect(result.matches.map((m) => m.closetItem.id), ['a', 'b']);
      expect(result.matches.first.formattedPercentage, '82%');
      expect(result.matches.last.isStronglyRecommended, isFalse);
      expect(
        result.editorialSummary,
        'Forma 3 looks com o seu acervo, 2 com IHE de 75% ou mais. A cor tem 74% de harmonia com a sua cartela.',
      );
    });

    test('acervo sem combinações e conta sem cartela', () {
      final result = StoreParityResult.fromJson({
        'ihe_percentage': 0.0,
        'is_strongly_recommended': false,
        'palette_harmony': null,
        'styling_advice': null,
        'looks_evaluated': 0,
        'strong_looks': 0,
        'matches': [],
      }, storeGarment: _storeGarment);

      expect(result.matches, isEmpty);
      expect(result.editorialSummary, 'Seu acervo ainda não tem peças que formem um look com esta.');
    });
  });
}
