import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/mocks/mock_gap_analysis.dart';
import 'package:harmonia_mvp/models/affiliated_product.dart';
import 'package:harmonia_mvp/models/wardrobe_gap.dart';

void main() {
  group('Gap Analysis Models & RN03 Unit Tests (RF11, RF12 & RN03)', () {
    test('PartnerStore enum formats names and badge colors correctly', () {
      expect(PartnerStore.cea.displayName, 'C&A Modas');
      expect(PartnerStore.cea.shortName, 'C&A');
      expect(PartnerStore.renner.displayName, 'Lojas Renner');
      expect(PartnerStore.renner.shortName, 'Renner');
    });

    test('AffiliatedProduct formats price and holds affiliate metadata', () {
      const product = AffiliatedProduct(
        id: 'p1',
        store: PartnerStore.renner,
        name: 'Camisa Linho Off-White',
        price: 179.90,
        imageUrl: 'https://example.com/img.png',
        affiliateUrl: 'https://lojasrenner.com.br/item?utm_source=harmonia',
        inStock: true,
        chromaticParityTag: '96% Harmonia Tonal',
        dominantColor: TestColors.sand,
      );

      expect(product.formattedPrice, 'R\$ 179,90');
      expect(product.inStock, isTrue);
      expect(product.affiliateUrl, contains('utm_source=harmonia'));
    });

    test('RN03: WardrobeGap strictly filters out-of-stock products from availableProducts', () {
      const availableProd = AffiliatedProduct(
        id: 'in_stock_1',
        store: PartnerStore.cea,
        name: 'Camisa Disponível',
        price: 120.0,
        imageUrl: 'https://example.com/img1.png',
        affiliateUrl: 'https://cea.com.br/item1',
        inStock: true,
        chromaticParityTag: '95% Harmonia',
        dominantColor: TestColors.sand,
      );

      const outOfStockProd = AffiliatedProduct(
        id: 'out_of_stock_1',
        store: PartnerStore.renner,
        name: 'Camisa Esgotada',
        price: 150.0,
        imageUrl: 'https://example.com/img2.png',
        affiliateUrl: 'https://renner.com.br/item2',
        inStock: false, // Esgotado
        chromaticParityTag: '90% Harmonia',
        dominantColor: TestColors.sand,
      );

      const gap = WardrobeGap(
        id: 'g1',
        missingCategory: 'Camisa Linho Off-White',
        rationale: 'Destrava 14 novas combinações',
        estimatedIheGain: 0.14,
        suggestedProducts: [availableProd, outOfStockProd],
      );

      // Total de sugestões originais: 2
      expect(gap.suggestedProducts.length, 2);

      // REGRA DE NEGÓCIO RN03: Apenas o produto com estoque ativo deve estar em availableProducts
      expect(gap.availableProducts.length, 1);
      expect(gap.availableProducts.first.id, 'in_stock_1');
      expect(gap.outOfStockCount, 1);
      expect(gap.formattedGain, '+14% IHE');
    });

    test('GapAnalysisMockService delivers valid gaps with RN03 compliance', () {
      final gaps = GapAnalysisMockService.gaps;

      expect(gaps.length, 3);
      expect(gaps.first.missingCategory, 'Camisa Linho Off-White');
      expect(gaps.first.outOfStockCount, 1); // Contém 1 item esgotado filtrado por RN03
      expect(gaps.first.availableProducts.length, 2); // 2 itens disponíveis
    });
  });
}

class TestColors {
  static const Color sand = Color(0xFFD9CDBF);
}
