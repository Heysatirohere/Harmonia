import 'package:harmonia_mvp/data/services/wardrobe_api_service.dart';
import 'package:harmonia_mvp/models/clothing_item.dart';

/// Acervo em memória para testes de widget; [failure] simula a API fora do ar
class FakeWardrobeService extends WardrobeApiService {
  final List<ClothingItem> items;
  WardrobeException? failure;

  FakeWardrobeService(this.items, {this.failure});

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
}
