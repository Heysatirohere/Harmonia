import '../models/affiliated_product.dart';
import '../models/wardrobe_gap.dart';

class MockGapAnalysis {
  static final List<WardrobeGap> gaps = [
    const WardrobeGap(
      id: 'gap_01',
      missingCategory: 'Camisa Linho Off-White',
      stylisticRationale: 'Destrava 14 novas combinações com suas partes de baixo de alfaiataria.',
      deltaIhe: 14.5,
      suggestedProducts: [
        AffiliatedProduct(
          id: 'prod_01',
          store: AffiliateStore.renner,
          name: 'Camisa 100% Linho MANGAS DOBRADAS',
          formattedPrice: 'R\$ 199,90',
          imageUrl: 'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=500',
          affiliateUrl: 'https://www.lojasrenner.com.br/item/camisa-linho?utm_source=harmonia',
          inStock: true,
        ),
        AffiliatedProduct(
          id: 'prod_02',
          store: AffiliateStore.cea,
          name: 'Camisa Linho Leve Off-White',
          formattedPrice: 'R\$ 179,99',
          imageUrl: 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=500',
          affiliateUrl: 'https://www.cea.com.br/item/camisa-linho-cea?utm_source=harmonia',
          inStock: true,
        ),
        AffiliatedProduct(
          id: 'prod_03_out_of_stock',
          store: AffiliateStore.renner,
          name: 'Camisa Linho Esgotada Edição Especial',
          formattedPrice: 'R\$ 229,90',
          imageUrl: 'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=500',
          affiliateUrl: 'https://www.lojasrenner.com.br/item/esgotada?utm_source=harmonia',
          inStock: false, // Must be filtered out by RN03
        ),
      ],
    ),
    const WardrobeGap(
      id: 'gap_02',
      missingCategory: 'Mule Couro Areia',
      stylisticRationale: 'Harmoniza o contraste entre saias midi e casacos de inverno.',
      deltaIhe: 9.8,
      suggestedProducts: [
        AffiliatedProduct(
          id: 'prod_04',
          store: AffiliateStore.cea,
          name: 'Mule Couro Trançado Areia',
          formattedPrice: 'R\$ 159,99',
          imageUrl: 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=500',
          affiliateUrl: 'https://www.cea.com.br/item/mule-couro?utm_source=harmonia',
          inStock: true,
        ),
      ],
    ),
  ];
}
