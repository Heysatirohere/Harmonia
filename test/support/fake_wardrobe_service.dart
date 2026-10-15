import 'dart:typed_data';

import 'package:harmonia_mvp/data/services/wardrobe_api_service.dart';
import 'package:harmonia_mvp/models/clothing_item.dart';
import 'package:harmonia_mvp/models/garment_segmentation.dart';
import 'package:harmonia_mvp/models/wardrobe_analytics.dart';

/// Acervo em memória para testes de widget; [failure] simula a API fora do ar
class FakeWardrobeService extends WardrobeApiService {
  final List<ClothingItem> items;
  WardrobeException? failure;

  /// Resultado do recorte; nulo simula falha da segmentação
  GarmentSegmentation? segmentation;

  /// Saúde do acervo devolvida por [getAnalytics]
  WardrobeAnalytics? analytics;

  FakeWardrobeService(this.items, {this.failure, this.segmentation, this.analytics});

  @override
  Future<List<ClothingItem>> getClothingItems({
    String? category,
    double? minFormality,
    double? maxFormality,
  }) async {
    final queued = failure;
    if (queued != null) {
      failure = null;
      throw queued;
    }
    return items;
  }

  @override
  Future<WardrobeAnalytics> getAnalytics() async {
    final queued = failure;
    if (queued != null) {
      failure = null;
      throw queued;
    }
    return analytics!;
  }

  @override
  Future<GarmentSegmentation> segmentGarment({required Uint8List imageBytes, required String fileName}) async {
    final result = segmentation;
    if (result == null) throw const SegmentationException('Não foi possível analisar a foto.');
    return result;
  }

  @override
  Future<bool> deleteClothingItem(String itemId) async {
    items.removeWhere((item) => item.id == itemId);
    return true;
  }

  @override
  Future<ClothingItem?> updateClothingItem(ClothingItem item) async {
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      items[index] = item;
    }
    return item;
  }
}

