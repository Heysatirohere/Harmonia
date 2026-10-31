import 'dart:typed_data';

import '../../models/clothing_item.dart';
import '../../models/garment_segmentation.dart';
import '../../models/wardrobe_analytics.dart';

/// Contrato de domínio do Acervo Virtual (Wardrobe — RF03, RF04, RF05, RF06, Seção 8 AGENTS.md)
abstract class WardrobeRepository {
  Future<List<ClothingItem>> getClothingItems({
    String? category,
    double? minFormality,
    double? maxFormality,
  });

  Future<WardrobeAnalytics> getAnalytics();

  Future<ClothingItem?> createClothingItem(ClothingItem item);

  Future<ClothingItem> uploadAndCatalogGarment({
    Uint8List? imageBytes,
    String? fileName,
    required ClothingItem item,
  });

  Future<GarmentSegmentation> segmentGarment({
    required Uint8List imageBytes,
    required String fileName,
  });

  Future<bool> deleteClothingItem(String itemId);

  Future<ClothingItem?> updateClothingItem(ClothingItem item);
}
