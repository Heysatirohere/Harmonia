import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/domain/models/style_profile.dart';
import 'package:harmonia_mvp/models/user_style_profile.dart';

void main() {
  group('StyleProfile', () {
    test('lê o perfil da API e as cotas RN02', () {
      final profile = StyleProfile.fromJson({
        'body_shape': 'TRIANGULO_INVERTIDO',
        'seasonal_palette': 'INVERNO_BRILHANTE',
        'items_count': 30,
        'looks_generated_today': 2,
        'max_items_allowed': 30,
        'max_daily_looks_allowed': 5,
        'is_premium': false,
      });

      expect(profile.silhouette, BodySilhouetteType.trianguloInvertido);
      expect(profile.palette, SeasonalPaletteType.invernoVivo);
      expect(profile.isComplete, isTrue);
      expect(profile.isItemsQuotaReached, isTrue);
      expect(profile.isDailyLooksQuotaReached, isFalse);
      expect(profile.dailyLooksRatio, closeTo(0.4, 1e-9));
    });

    test('perfil sem biótipo ou cartela está incompleto', () {
      final profile = StyleProfile.fromJson({'body_shape': null, 'seasonal_palette': 'VERAO_FRIO'});

      expect(profile.silhouette, isNull);
      expect(profile.isComplete, isFalse);
    });

    test('premium não tem limite de cota', () {
      const profile = StyleProfile(itemsCount: 99, looksToday: 99, isPremium: true);

      expect(profile.isItemsQuotaReached, isFalse);
      expect(profile.isDailyLooksQuotaReached, isFalse);
    });

    test('toda opção do app tem uma chave única no motor do IHE', () {
      final silhouettes = BodySilhouetteType.values.map((t) => t.apiKey).toSet();
      final palettes = SeasonalPaletteType.values.map((t) => t.apiKey).toSet();

      expect(silhouettes, hasLength(BodySilhouetteType.values.length));
      expect(palettes, hasLength(SeasonalPaletteType.values.length));
      for (final type in SeasonalPaletteType.values) {
        expect(SeasonalPaletteExtension.fromApiKey(type.apiKey), type);
      }
    });
  });
}
