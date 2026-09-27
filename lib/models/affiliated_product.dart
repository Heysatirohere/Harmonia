import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Lojas Varejistas Parceiras para Afiliação (RF12 & RN03)
enum PartnerStore {
  cea,
  renner;

  String get displayName {
    switch (this) {
      case PartnerStore.cea:
        return 'C&A Modas';
      case PartnerStore.renner:
        return 'Lojas Renner';
    }
  }

  String get shortName {
    switch (this) {
      case PartnerStore.cea:
        return 'C&A';
      case PartnerStore.renner:
        return 'Renner';
    }
  }

  Color get badgeColor {
    switch (this) {
      case PartnerStore.cea:
        return const Color(0xFF0033A0); // Azul C&A
      case PartnerStore.renner:
        return const Color(0xFFE30613); // Vermelho Renner
    }
  }
}

/// Modelo de Produto Sugerido com Link de Afiliação Externa (RF12 & RN03)
class AffiliatedProduct {
  final String id;
  final PartnerStore store;
  final String name;
  final double price;
  final String imageUrl;
  final String affiliateUrl; // URL parametrizada com UTM/Afiliação
  final bool inStock;        // Regra de Negócio RN05/RN03: Estoque Ativo
  final String chromaticParityTag;
  final Color dominantColor;

  const AffiliatedProduct({
    required this.id,
    required this.store,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.affiliateUrl,
    required this.inStock,
    required this.chromaticParityTag,
    required this.dominantColor,
  });

  String get formattedPrice =>
      'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
}
