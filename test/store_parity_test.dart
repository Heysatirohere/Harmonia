import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/core/theme/app_colors.dart';
import 'package:harmonia_mvp/mocks/mock_clothes.dart';
import 'package:harmonia_mvp/mocks/mock_store_parity.dart';
import 'package:harmonia_mvp/models/store_parity_result.dart';
import 'package:harmonia_mvp/presentation/widgets/store_parity_sheet.dart';

void main() {
  group('StoreParity Models & Mocks Tests (RF08 / RF09)', () {
    test('StoreGarment formats price correctly', () {
      const garment = StoreGarment(
        id: 'test_01',
        title: 'Blazer Linho Terracota',
        storeName: 'Lojas Renner',
        price: 299.90,
        category: 'ALFAIATARIA (SUPERIOR)',
        dominantColor: AppColors.accentTerracotta,
      );

      expect(garment.formattedPrice, 'R\$ 299,90');
    });

    test('ParityMatchItem calculates match percentage correctly', () {
      final closetItem = MockClothes.items.first;
      final match = ParityMatchItem(
        closetItem: closetItem,
        parityScore: 0.94,
        matchReason: 'Contraste excelente',
      );

      expect(match.parityPercentage, 94);
      expect(match.formattedPercentage, '94%');
      expect(match.isHighMatch, isTrue);
    });

    test('StoreParityResult validates overall score and strong recommendation',
        () {
      final mock = MockStoreParity.blazerTerracotaRenner;

      expect(mock.overallPercentage, 86);
      expect(mock.formattedOverallScore, '86%');
      expect(mock.isStronglyRecommended, isTrue);
      expect(mock.compatibleMatches.length, 4);
      expect(mock.storeGarment.storeName, 'Lojas Renner');
    });
  });

  group('StoreParitySheet Widget Tests (RF09)', () {
    testWidgets(
        'renders parity sheet with overall score, header and compatible closet matches',
        (WidgetTester tester) async {
      final parityResult = MockStoreParity.blazerTerracotaRenner;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreParitySheet(
              parityResult: parityResult,
            ),
          ),
        ),
      );

      // Header da loja e peça
      expect(find.text('LOJAS RENNER'), findsOneWidget);
      expect(find.text('Blazer Linho Terracota'), findsOneWidget);
      expect(find.text('R\$ 299,90'), findsOneWidget);

      // Score de Paridade Global
      expect(find.text('86%'), findsOneWidget);
      expect(find.text('Compatibilidade'), findsOneWidget);
      expect(find.text('PARIDADE CONFIRMADA • PEÇA RECOMENDADA PARA SEU ACERVO'),
          findsOneWidget);

      // Lista de compatibilidade com acervo residencial
      expect(find.text('Harmonia com seu Acervo'), findsOneWidget);
      expect(find.text('Pantalona Ampla Off-White'), findsOneWidget);
      expect(find.text('Regata Seda Areia'), findsOneWidget);
      expect(find.text('94%'), findsOneWidget);
    });

    testWidgets('tapping match card expands chromatic and morphological score details',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final parityResult = MockStoreParity.blazerTerracotaRenner;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreParitySheet(
              parityResult: parityResult,
            ),
          ),
        ),
      );

      // Clica no primeiro card de peça compatível
      await tester.tap(find.text('Pantalona Ampla Off-White'));
      await tester.pumpAndSettle();

      // Verifica expansão dos detalhes S_cor e S_bio
      expect(find.text('HARMONIA CROMÁTICA'), findsOneWidget);
      expect(find.text('SILHUETA & BIÓTIPO'), findsOneWidget);
      expect(find.text('96%'), findsOneWidget); // S_cor
      expect(find.text('92%'), findsOneWidget); // S_bio
    });
  });
}
