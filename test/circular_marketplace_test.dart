import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/mocks/mock_clothes.dart';
import 'package:harmonia_mvp/models/circular_listing.dart';
import 'package:harmonia_mvp/models/clothing_item.dart';
import 'package:harmonia_mvp/models/wardrobe_analytics.dart';
import 'package:harmonia_mvp/presentation/screens/circular_marketplace_screen.dart';
import 'package:harmonia_mvp/presentation/screens/wardrobe_analytics_screen.dart';
import 'package:harmonia_mvp/presentation/screens/wardrobe_screen.dart';
import 'package:harmonia_mvp/theme/app_theme.dart';

import 'support/fake_wardrobe_service.dart';

void main() {
  group('CircularListing & CircularMarketplaceScreen (Seção 3.5.4)', () {
    test('serializa e desserializa CircularListing e converte para ClothingItem', () {
      final listing = CircularListing.fromJson(const {
        'item_id': 'item-123',
        'title': 'Blazer Linho',
        'category': 'Partes de cima',
        'image_url': '',
        'dominant_l': 54.0,
        'dominant_a': 30.0,
        'dominant_b': 26.0,
        'color_hex': '#A34836',
        'color_family': 'Terracota',
        'cut_type': 'ACINTURADO',
        'suggested_price_brl': 149.90,
        'palette_compatibility': 0.94,
        'is_own_listing': false,
      });

      expect(listing.compatibilityPercent, 94);
      expect(listing.isHighHarmony, isTrue);
      expect(listing.formattedPrice, 'R\$ 149,90');

      final converted = listing.toClothingItem();
      expect(converted.id, 'circular-item-123');
      expect(converted.isConsciousFashion, isTrue);
      expect(converted.disposalStatus, 'ACTIVE');
    });

    testWidgets('renderiza vitrine do Brechó Circular, filtra por categoria e incorpora peça ao acervo',
        (tester) async {
      final service = FakeWardrobeService(
        [
          mockClothes.first.copyWith(
            id: 'own-sell-1',
            name: 'Camisa Seda Própria',
            disposalStatus: 'SELL',
            price: 200.0,
          ),
        ],
      );

      ClothingItem? acquiredItem;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CircularMarketplaceScreen(
            service: service,
            localItems: service.items,
            onItemAcquired: (item) => acquiredItem = item,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Brechó Circular'), findsOneWidget);
      expect(find.text('SEU ANÚNCIO'), findsWidgets);
      expect(find.text('Camisa Seda Própria'), findsOneWidget);
      expect(find.text('Blazer Alfaiataria Linho Terracota'), findsOneWidget);

      // Filtra por Calçados
      await tester.tap(find.text('Calçados'));
      await tester.pumpAndSettle();
      expect(find.text('Mocassim Artesanal Couro Caramelo'), findsOneWidget);

      // Abre folha de detalhe do mocassim e incorpora ao acervo
      await tester.ensureVisible(find.text('Mocassim Artesanal Couro Caramelo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mocassim Artesanal Couro Caramelo'));
      await tester.pumpAndSettle();
      expect(find.text('Incorporar ao Meu Acervo'), findsOneWidget);

      await tester.tap(find.text('Incorporar ao Meu Acervo'));
      await tester.pumpAndSettle();

      expect(acquiredItem, isNotNull);
      expect(acquiredItem!.name, 'Mocassim Artesanal Couro Caramelo');
    });

    testWidgets('permite retirar anúncio próprio do Brechó Circular e reativar no acervo', (tester) async {
      final ownPiece = mockClothes.first.copyWith(
        id: 'own-sell-2',
        name: 'Jaqueta Jeans Própria',
        disposalStatus: 'SELL',
        price: 180.0,
      );
      final service = FakeWardrobeService([ownPiece]);
      ClothingItem? reactivated;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CircularMarketplaceScreen(
            service: service,
            localItems: [ownPiece],
            onItemAcquired: (item) => reactivated = item,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Jaqueta Jeans Própria'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jaqueta Jeans Própria'));
      await tester.pumpAndSettle();
      expect(find.text('Retirar do Brechó e Reativar'), findsOneWidget);

      await tester.tap(find.text('Retirar do Brechó e Reativar'));
      await tester.pumpAndSettle();

      expect(reactivated, isNotNull);
      expect(reactivated!.disposalStatus, 'ACTIVE');
    });

    testWidgets('navega do Guarda-Roupa e do Dashboard ESG para o Brechó Circular', (tester) async {
      final service = FakeWardrobeService(
        List.of(mockClothes),
        analytics: WardrobeAnalytics.fromJson(const {
          'total_pieces': 4,
          'active_count': 3,
          'idle_30_count': 1,
          'idle_60_count': 0,
          'dormant_count': 1,
          'never_worn_count': 1,
          'total_wears': 12,
          'color_distribution': [
            {'family': 'Neutros', 'count': 4, 'percentage': 100.0, 'L': 85.0, 'a': 0.0, 'b': 5.0},
          ],
          'dormant_items': [
            {
              'item': {
                'id': 'b1',
                'user_id': 'u1',
                'category': 'Partes de baixo',
                'subcategory': 'Saia de linho',
                'image_url': '',
                'dominant_l': 30.0,
                'dominant_a': 10.0,
                'dominant_b': 20.0,
                'formality_score': 0.5,
                'is_archived': false,
                'created_at': '2026-05-01T12:00:00Z',
              },
              'wear_count': 0,
              'last_worn_at': null,
              'days_idle': 157,
            },
          ],
        }),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: WardrobeScreen(service: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BRECHÓ CIRCULAR'), findsOneWidget);
      await tester.tap(find.text('BRECHÓ CIRCULAR'));
      await tester.pumpAndSettle();

      expect(find.text('Brechó Circular'), findsOneWidget);

      // Testa também a abertura a partir do Dashboard ESG
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: AppTheme.lightTheme,
          home: WardrobeAnalyticsScreen(service: service),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('open_circular_marketplace_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('open_circular_marketplace_btn')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('open_circular_marketplace_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Brechó Circular'), findsOneWidget);
    });
  });
}
