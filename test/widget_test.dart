import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/main.dart';
import 'package:harmonia_mvp/presentation/screens/daily_outfit_screen.dart';
import 'package:harmonia_mvp/presentation/screens/scan_item_screen.dart';
import 'package:harmonia_mvp/presentation/widgets/color_extractor_chips.dart';
import 'package:harmonia_mvp/presentation/widgets/ihe_score_gauge.dart';
import 'package:harmonia_mvp/presentation/widgets/outfit_composition_card.dart';
import 'package:harmonia_mvp/presentation/widgets/segmentation_preview.dart';

void main() {
  testWidgets('HarmonIA DailyOutfitScreen & IHE Gauge smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HarmoniaApp());

    // Verifica a inicialização da tela Sugestão do Dia
    expect(find.text('Sugestão do Dia'), findsOneWidget);
    expect(find.byType(DailyOutfitScreen), findsOneWidget);
    expect(find.byType(OutfitCompositionCard), findsWidgets);
    expect(find.byType(IheScoreGauge), findsWidgets);
    expect(find.text('✦ LOOK FORTEMENTE RECOMENDADO'), findsWidgets);
  });

  testWidgets('HarmonIA ScanItemScreen & SegmentationPreview smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScanItemScreen(),
      ),
    );

    expect(find.text('Digitalizar Peça'), findsOneWidget);
    expect(find.byType(SegmentationPreview), findsOneWidget);
    expect(find.byType(ColorExtractorChips), findsOneWidget);

    final ctaFinder = find.widgetWithText(ElevatedButton, 'Catalogar no Acervo');
    await tester.scrollUntilVisible(
      ctaFinder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(ctaFinder, findsOneWidget);
  });
}
