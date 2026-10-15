import 'dart:ui';

import '../core/color/lab_color.dart';

enum AffiliateStore {
  cea,
  renner;

  static AffiliateStore fromApi(String value) => switch (value) {
        'CEA' => AffiliateStore.cea,
        'RENNER' => AffiliateStore.renner,
        _ => throw FormatException('Parceiro desconhecido: $value'),
      };
}

/// Produto de parceiro para uma lacuna do acervo (RF12). Sem foto nem preço: esses dados
/// só valem vindos da loja, então o link leva à busca no e-commerce com UTM de afiliação.
class AffiliatedProduct {
  final String id;
  final AffiliateStore store;
  final String name;
  final Color color;
  final String affiliateUrl;
  final bool inStock;

  const AffiliatedProduct({
    required this.id,
    required this.store,
    required this.name,
    required this.color,
    required this.affiliateUrl,
    this.inStock = true,
  });

  /// A API só devolve produtos com estoque (RN03)
  factory AffiliatedProduct.fromJson(Map<String, dynamic> json) => AffiliatedProduct(
        id: json['id'] as String,
        store: AffiliateStore.fromApi(json['store'] as String),
        name: json['name'] as String,
        color: hexToColor(json['color_hex'] as String),
        affiliateUrl: json['url'] as String,
      );

  String get storeDisplayName => switch (store) {
        AffiliateStore.cea => 'C&A',
        AffiliateStore.renner => 'Lojas Renner',
      };
}
