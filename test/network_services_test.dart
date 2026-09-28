import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/core/network/api_client.dart';
import 'package:harmonia_mvp/data/services/wardrobe_api_service.dart';
import 'package:harmonia_mvp/data/services/outfit_api_service.dart';
import 'package:harmonia_mvp/mocks/mock_clothes.dart';

void main() {
  group('Network & API Services Tests (SOA Integration)', () {
    test('ApiClient initializes with proper base configuration', () {
      final client = ApiClient();
      expect(client.baseUrl, isNotEmpty);
      expect(client.currentUserId, isNotEmpty);
    });

    test('WardrobeApiService returns resilient fallback when offline', () async {
      final service = WardrobeApiService();
      final items = await service.getClothingItems();

      expect(items, isNotEmpty);
      expect(items.length, mockClothes.length);
    });

    test('WardrobeApiService filters items by category in fallback', () async {
      final service = WardrobeApiService();
      final tops = await service.getClothingItems(category: 'Partes de cima');

      expect(tops, isNotEmpty);
      expect(tops.every((item) => item.category == 'Partes de cima'), isTrue);
    });

    test('OutfitApiService returns valid outfits in fallback', () async {
      final service = OutfitApiService();
      final outfits = await service.generateDailyOutfits();

      expect(outfits, isNotEmpty);
      expect(outfits.first.topItem, isNotNull);
      expect(outfits.first.ihe.overallScore, greaterThan(0));
    });
  });
}
