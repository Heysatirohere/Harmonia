import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/mocks/mock_gap_analysis.dart';
import 'package:harmonia_mvp/models/affiliated_product.dart';
import 'package:harmonia_mvp/models/wardrobe_gap.dart';

/// Resposta de GET /outfits/gaps no formato da API
Map<String, dynamic> gapsJson() => {
      'occasion': 'CASUAL',
      'baseline_ihe_percentage': 56.84,
      'gaps': [
        {
          'id': 'pantalona-caramelo',
          'title': 'Pantalona caramelo',
          'category': 'bottom',
          'rationale': 'Cria 1 look acima da média do seu acervo com suas partes de cima; o melhor chega a 61%.',
          'color_hex': '#9E7650',
          'looks_evaluated': 2,
          'strong_looks': 0,
          'best_ihe_percentage': 61.2,
          'delta_ihe': 4.4,
          'products': [
            {
              'id': 'renner-pantalona-caramelo',
              'store': 'RENNER',
              'store_name': 'Lojas Renner',
              'name': 'Calça pantalona caramelo',
              'color_hex': '#9E7650',
              'url': 'https://www.lojasrenner.com.br/b?Ntt=calca+pantalona+caramelo&utm_source=harmonia',
            },
          ],
        },
      ],
    };

void main() {
  group('WardrobeGapReport.fromJson', () {
    test('lê lacunas, cores e produtos no formato da API', () {
      final report = WardrobeGapReport.fromJson(gapsJson());

      expect(report.occasion, 'CASUAL');
      expect(report.baselineIhe, 56.84);
      final gap = report.gaps.single;
      expect(gap.title, 'Pantalona caramelo');
      expect(gap.color, const Color(0xFF9E7650));
      expect((gap.looksEvaluated, gap.strongLooks, gap.bestIhe, gap.deltaIhe), (2, 0, 61.2, 4.4));
      final product = gap.availableProducts.single;
      expect(product.store, AffiliateStore.renner);
      expect(product.storeDisplayName, 'Lojas Renner');
      expect(product.affiliateUrl, contains('utm_source=harmonia'));
    });

    test('acervo que ainda não forma looks vem sem média', () {
      final report = WardrobeGapReport.fromJson({'occasion': 'CASUAL', 'baseline_ihe_percentage': null, 'gaps': []});

      expect(report.baselineIhe, isNull);
      expect(report.gaps, isEmpty);
    });

    test('parceiro desconhecido é recusado', () {
      final json = gapsJson();
      ((json['gaps'] as List).first['products'] as List).first['store'] = 'AMAZON';

      expect(() => WardrobeGapReport.fromJson(json), throwsFormatException);
    });
  });

  test('availableProducts nunca devolve produto esgotado (RN03)', () {
    final gap = MockGapAnalysis.gaps.first;

    expect(gap.suggestedProducts.any((p) => !p.inStock), isTrue);
    expect(gap.availableProducts, isNotEmpty);
    expect(gap.availableProducts.every((p) => p.inStock), isTrue);
  });
}
