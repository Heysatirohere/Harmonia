enum AffiliateStore {
  cea,
  renner,
}

class AffiliatedProduct {
  final String id;
  final AffiliateStore store;
  final String name;
  final String formattedPrice;
  final String imageUrl;
  final String affiliateUrl;
  final bool inStock;

  const AffiliatedProduct({
    required this.id,
    required this.store,
    required this.name,
    required this.formattedPrice,
    required this.imageUrl,
    required this.affiliateUrl,
    this.inStock = true,
  });

  String get storeDisplayName {
    switch (store) {
      case AffiliateStore.cea:
        return 'C&A Brasil';
      case AffiliateStore.renner:
        return 'Lojas Renner';
    }
  }
}
