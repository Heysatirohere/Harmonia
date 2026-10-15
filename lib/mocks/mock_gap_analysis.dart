import 'dart:ui';

import '../models/affiliated_product.dart';
import '../models/wardrobe_gap.dart';

/// Lacunas de exemplo para o modo demo (HARMONIA_DEMO); o app real lê de /outfits/gaps
class MockGapAnalysis {
  static const report = WardrobeGapReport(occasion: 'CASUAL', baselineIhe: 56.8, gaps: gaps);

  static const List<WardrobeGap> gaps = [
    WardrobeGap(
      id: 'camisa-linho-off-white',
      title: 'Camisa de linho off-white',
      category: 'top',
      stylisticRationale: 'Destrava 4 looks fortemente recomendados com suas partes de baixo.',
      color: Color(0xFFEAE6DC),
      looksEvaluated: 6,
      strongLooks: 4,
      bestIhe: 81.5,
      deltaIhe: 24.7,
      suggestedProducts: [
        AffiliatedProduct(
          id: 'renner-camisa-linho-off',
          store: AffiliateStore.renner,
          name: 'Camisa de linho manga longa off-white',
          color: Color(0xFFEBE6DA),
          affiliateUrl: 'https://www.lojasrenner.com.br/b?Ntt=camisa+linho+off+white&utm_source=harmonia',
        ),
        AffiliatedProduct(
          id: 'cea-camisa-linho-off',
          store: AffiliateStore.cea,
          name: 'Camisa de linho off-white',
          color: Color(0xFFE8E3D9),
          affiliateUrl: 'https://www.cea.com.br/camisa%20linho%20off%20white?_q=camisa+linho+off+white&map=ft&utm_source=harmonia',
        ),
        AffiliatedProduct(
          id: 'renner-camisa-linho-esgotada',
          store: AffiliateStore.renner,
          name: 'Camisa de linho edição especial',
          color: Color(0xFFEBE6DA),
          affiliateUrl: 'https://www.lojasrenner.com.br/b?Ntt=camisa+linho&utm_source=harmonia',
          inStock: false, // RN03: nunca aparece
        ),
      ],
    ),
    WardrobeGap(
      id: 'mocassim-couro-caramelo',
      title: 'Mocassim de couro caramelo',
      category: 'shoes',
      stylisticRationale: 'Cria 3 looks acima da média do seu acervo com as peças que você já tem; o melhor chega a 68%.',
      color: Color(0xFF8C5E37),
      looksEvaluated: 5,
      strongLooks: 0,
      bestIhe: 68.2,
      deltaIhe: 11.4,
      suggestedProducts: [
        AffiliatedProduct(
          id: 'cea-mocassim-caramelo',
          store: AffiliateStore.cea,
          name: 'Mocassim caramelo',
          color: Color(0xFF8E5F39),
          affiliateUrl: 'https://www.cea.com.br/mocassim%20caramelo?_q=mocassim+caramelo&map=ft&utm_source=harmonia',
        ),
      ],
    ),
  ];
}
