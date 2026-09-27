import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/affiliated_product.dart';
import '../models/wardrobe_gap.dart';

/// Serviço de Mocks para Análise de Lacunas do Acervo (RF11, RF12 & RN03)
class GapAnalysisMockService {
  GapAnalysisMockService._();

  static List<WardrobeGap> get gaps => [
        // Lacuna 1: Camisa Linho Off-White
        WardrobeGap(
          id: 'gap_01',
          missingCategory: 'Camisa Linho Off-White',
          rationale:
              'A ausência desta parte de cima neutra limita a versatilidade das suas 3 pantalonas. Sua adição destrava até 14 novas coordenações.',
          estimatedIheGain: 0.14, // +14% Δ IHE
          suggestedProducts: [
            const AffiliatedProduct(
              id: 'prod_ren_01',
              store: PartnerStore.renner,
              name: 'Camisa em Linho Desestruturada Off-White',
              price: 179.90,
              imageUrl:
                  'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=600&auto=format&fit=crop&q=80',
              affiliateUrl:
                  'https://www.lojasrenner.com.br/p/camisa-linho-offwhite?utm_source=harmonia&utm_medium=affiliate&utm_campaign=gap_analysis',
              inStock: true,
              chromaticParityTag: '96% Harmonia Tonal',
              dominantColor: Color(0xFFF7F3EC),
            ),
            const AffiliatedProduct(
              id: 'prod_cea_01',
              store: PartnerStore.cea,
              name: 'Camisa Alfaiataria Viscose & Linho Areia',
              price: 159.99,
              imageUrl:
                  'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=600&auto=format&fit=crop&q=80',
              affiliateUrl:
                  'https://www.cea.com.br/p/camisa-viscose-linho?utm_source=harmonia&utm_medium=affiliate&utm_campaign=gap_analysis',
              inStock: true,
              chromaticParityTag: '93% Harmonia Tonal',
              dominantColor: AppColors.accentSand,
            ),
            // Produto Esgotado para Teste da Regra de Negócio RN03
            const AffiliatedProduct(
              id: 'prod_ren_02_soldout',
              store: PartnerStore.renner,
              name: 'Camisa Manga Curta Linho Puro (Esgotado)',
              price: 199.90,
              imageUrl:
                  'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=600&auto=format&fit=crop&q=80',
              affiliateUrl:
                  'https://www.lojasrenner.com.br/p/camisa-esgotada?utm_source=harmonia',
              inStock: false, // RN03: Deve ser ocultado da UI
              chromaticParityTag: '90% Harmonia',
              dominantColor: Color(0xFFEBE5DB),
            ),
          ],
        ),

        // Lacuna 2: Mocassim Couro Caramelo
        WardrobeGap(
          id: 'gap_02',
          missingCategory: 'Mocassim Couro Caramelo',
          rationale:
              'Calçado atemporal que eleva composições casuais e harmoniza nativamente com a sua cartela Outono Suave.',
          estimatedIheGain: 0.10, // +10% Δ IHE
          suggestedProducts: [
            const AffiliatedProduct(
              id: 'prod_cea_02',
              store: PartnerStore.cea,
              name: 'Mocassim Tradicional Couro Caramelo',
              price: 219.99,
              imageUrl:
                  'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=600&auto=format&fit=crop&q=80',
              affiliateUrl:
                  'https://www.cea.com.br/p/mocassim-couro-caramelo?utm_source=harmonia&utm_medium=affiliate',
              inStock: true,
              chromaticParityTag: '91% Harmonia Tonal',
              dominantColor: Color(0xFF965638),
            ),
            const AffiliatedProduct(
              id: 'prod_ren_03',
              store: PartnerStore.renner,
              name: 'Loafer Minimalista em Suede Terroso',
              price: 249.90,
              imageUrl:
                  'https://images.unsplash.com/photo-1533867617858-e7b97e060509?w=600&auto=format&fit=crop&q=80',
              affiliateUrl:
                  'https://www.lojasrenner.com.br/p/loafer-suede?utm_source=harmonia&utm_medium=affiliate',
              inStock: true,
              chromaticParityTag: '88% Harmonia Tonal',
              dominantColor: Color(0xFF804428),
            ),
          ],
        ),

        // Lacuna 3: Trench Coat Bege Editorial
        WardrobeGap(
          id: 'gap_03',
          missingCategory: 'Trench Coat Bege Editorial',
          rationale:
              'Sobreposição pesada para transições térmicas com a sua paleta terracota, garantindo elegância em dias de 18°C.',
          estimatedIheGain: 0.12, // +12% Δ IHE
          suggestedProducts: [
            const AffiliatedProduct(
              id: 'prod_ren_04',
              store: PartnerStore.renner,
              name: 'Trench Coat Midi Abotoamento Duplo Bege',
              price: 399.90,
              imageUrl:
                  'https://images.unsplash.com/photo-1548624149-f1b9626d9c66?w=600&auto=format&fit=crop&q=80',
              affiliateUrl:
                  'https://www.lojasrenner.com.br/p/trench-coat-bege?utm_source=harmonia&utm_medium=affiliate',
              inStock: true,
              chromaticParityTag: '95% Harmonia Tonal',
              dominantColor: Color(0xFFC7B299),
            ),
          ],
        ),
      ];
}
