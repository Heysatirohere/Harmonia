import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/core/network/api_client.dart';
import 'package:harmonia_mvp/data/services/wardrobe_api_service.dart';
import 'package:harmonia_mvp/data/services/outfit_api_service.dart';

void main() {
  group('Network & API Services Tests (SOA Integration)', () {
    test('ApiClient initializes with proper base configuration', () {
      final client = ApiClient();
      expect(client.baseUrl, isNotEmpty);
    });

    test('WardrobeApiService sem API nem Supabase informa a falha em vez de inventar peças', () async {
      final service = WardrobeApiService();

      await expectLater(service.getClothingItems(), throwsA(isA<WardrobeException>()));
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
