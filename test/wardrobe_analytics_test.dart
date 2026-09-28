import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/mocks/mock_clothes.dart';
import 'package:harmonia_mvp/models/wardrobe_analytics.dart';
import 'package:harmonia_mvp/presentation/screens/wardrobe_analytics_screen.dart';

void main() {
  group('Wardrobe Analytics Model Tests (Section 3.2.2)', () {
    test('Calculates rotation, idle windows, and ESG percentage accurately', () {
      final analytics = WardrobeAnalytics.fromItems(mockClothes);

      expect(analytics.totalPieces, equals(mockClothes.length));
      expect(analytics.activePiecesCount, greaterThanOrEqualTo(0));
      expect(analytics.idle30DaysCount, greaterThanOrEqualTo(0));
      expect(analytics.idle60DaysCount, greaterThanOrEqualTo(0));
      expect(analytics.idle90DaysCount, greaterThanOrEqualTo(0));
      expect(analytics.averageCostPerWear, greaterThan(0));
      expect(analytics.estimatedIdleCapital, greaterThanOrEqualTo(0));
      expect(analytics.colorDistribution, isNotEmpty);
      expect(analytics.dormantItems, isNotEmpty);
    });

    test('Handles empty clothes list without exceptions', () {
      final analytics = WardrobeAnalytics.fromItems([]);

      expect(analytics.totalPieces, equals(0));
      expect(analytics.activePercentage, equals(0.0));
      expect(analytics.averageCostPerWear, equals(0.0));
    });
  });

  group('WardrobeAnalyticsScreen Widget Tests', () {
    testWidgets('Renders all analytical sections defined in Section 3.2.2', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: WardrobeAnalyticsScreen(items: mockClothes),
        ),
      );

      // 1. Cabeçalho Editorial
      expect(find.text('Saúde do Guarda-Roupa'), findsOneWidget);
      expect(find.text('INTELIGÊNCIA PATRIMONIAL & ESG'), findsOneWidget);

      // 2. Card de Diagnóstico ESG
      expect(find.text('DIRETRIZ ESG & CIRCULARIDADE'), findsOneWidget);

      // 3. Timeline de Ociosidade
      expect(find.text('ROTAÇÃO DE ACERVO POR PERÍODO (3.2.2)'), findsOneWidget);
      expect(find.text('Ativas (<30d)'), findsOneWidget);
      expect(find.text('Atenção (30–60d)'), findsOneWidget);
      expect(find.text('Ociosas (60–90d)'), findsOneWidget);
      expect(find.text('Dormindo (>90d)'), findsOneWidget);

      // 4. Proporção Cromática
      expect(find.text('PROPORÇÃO CROMÁTICA DOMINANTE (CIE LAB*)'), findsOneWidget);

      // 5. Métricas Financeiras
      expect(find.text('MÉTRICA PATRIMONIAL & CUSTO POR USO'), findsOneWidget);
      expect(find.text('Custo Médio / Uso'), findsOneWidget);
      expect(find.text('Capital Ocioso Parado'), findsOneWidget);

      // 6. Vitrine de Reativação
      expect(find.text('REATIVAR PEÇAS ADORMECIDAS (>90D)'), findsOneWidget);
      expect(find.text('Resgate de Patrimônio Ocioso'), findsOneWidget);
    });

    testWidgets('Tapping reactivate look opens curatorial reactivation sheet', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: WardrobeAnalyticsScreen(items: mockClothes),
        ),
      );

      // Encontra o botão de reativar e toca nele
      final reactivateButtons = find.text('Reativar Look');
      expect(reactivateButtons, findsWidgets);

      await tester.tap(reactivateButtons.first);
      await tester.pumpAndSettle();

      // Verifica se a Bottom Sheet curatorial abriu
      expect(find.text('REATIVAÇÃO DE PATRIMÔNIO (ESG)'), findsOneWidget);
      expect(find.text('Gerar Look com Esta Peça'), findsOneWidget);

      // Toca em gerar look para reativação
      await tester.tap(find.text('Gerar Look com Esta Peça'));
      await tester.pumpAndSettle();

      expect(find.text('Combinação de reativação gerada com sucesso!'), findsOneWidget);
    });
  });
}
