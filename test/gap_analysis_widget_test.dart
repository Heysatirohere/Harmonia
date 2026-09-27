import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/mocks/mock_gap_analysis.dart';
import 'package:harmonia_mvp/models/affiliated_product.dart';
import 'package:harmonia_mvp/presentation/screens/gap_analysis_screen.dart';
import 'package:harmonia_mvp/presentation/widgets/gap_analysis_sheet.dart';

void main() {
  group('GapAnalysisSheet Widget & RN03 Tests (RF11, RF12 & RN03)', () {
    testWidgets(
        'renders header, gap cards, estimated gain badges, and partner store cards',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GapAnalysisSheet(),
          ),
        ),
      );

      // Header Editorial
      expect(find.text('Otimização de Acervo'), findsOneWidget);
      expect(find.text('3 Lacunas Identificadas'), findsOneWidget);

      // Categorias de Lacunas
      expect(find.text('Camisa Linho Off-White'), findsOneWidget);
      expect(find.text('+14% IHE'), findsOneWidget);

      // Badges de Lojas Parceiras (C&A e Renner)
      expect(find.text('Renner'), findsAtLeastNWidgets(1));
      expect(find.text('C&A'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'RN03: Does NOT render out-of-stock products (inStock == false) in the UI',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GapAnalysisSheet(),
          ),
        ),
      );

      // Produtos em Estoque Rendidos
      expect(
          find.text('Camisa em Linho Desestruturada Off-White'), findsOneWidget);
      expect(find.text('Camisa Alfaiataria Viscose & Linho Areia'),
          findsOneWidget);

      // REGRA DE NEGÓCIO RN03: Produto com estoque esgotado NÃO deve existir na árvore de widgets
      expect(find.text('Camisa Manga Curta Linho Puro (Esgotado)'),
          findsNothing);
    });

    testWidgets(
        'tapping affiliate button triggers callback and opens link',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      AffiliatedProduct? launchedProduct;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GapAnalysisSheet(
              onLaunchAffiliate: (prod) => launchedProduct = prod,
            ),
          ),
        ),
      );

      // Clica no botão "Ver na loja" do primeiro produto
      final buttonFinder = find.text('Ver na loja').first;
      await tester.tap(buttonFinder);
      await tester.pump(const Duration(milliseconds: 300));

      expect(launchedProduct, isNotNull);
      expect(launchedProduct!.store, PartnerStore.renner);
      expect(launchedProduct!.affiliateUrl, contains('utm_source=harmonia'));
    });

    testWidgets('GapAnalysisScreen renders correctly with back button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GapAnalysisScreen(),
        ),
      );

      expect(find.text('Análise de Lacunas'), findsOneWidget);
      expect(find.text('Otimização de Acervo'), findsOneWidget);
    });
  });
}
