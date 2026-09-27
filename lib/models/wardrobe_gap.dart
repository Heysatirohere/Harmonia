import 'affiliated_product.dart';

class WardrobeGap {
  final String id;
  final String missingCategory;
  final String stylisticRationale;
  final double deltaIhe;
  final List<AffiliatedProduct> suggestedProducts;

  const WardrobeGap({
    required this.id,
    required this.missingCategory,
    required this.stylisticRationale,
    required this.deltaIhe,
    required this.suggestedProducts,
  });

  /// RN03: Strictly filters out unavailable (out-of-stock) products.
  /// The app UI must only render and allow clicks on available products.
  List<AffiliatedProduct> get availableProducts {
    return suggestedProducts.where((product) => product.inStock).toList();
  }
}
