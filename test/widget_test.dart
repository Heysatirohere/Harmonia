import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/main.dart';
import 'package:harmonia_mvp/presentation/screens/daily_outfit_screen.dart';
import 'package:harmonia_mvp/presentation/screens/onboarding_profile_screen.dart';
import 'package:harmonia_mvp/presentation/screens/scan_item_screen.dart';
import 'package:harmonia_mvp/presentation/widgets/color_extractor_chips.dart';
import 'package:harmonia_mvp/presentation/widgets/color_palette_preview.dart';
import 'package:harmonia_mvp/presentation/widgets/segmentation_preview.dart';

void main() {
  testWidgets('HarmonIA DailyOutfitScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HarmoniaApp());

    // Verifica a inicialização da tela Sugestão Diária
    expect(find.text('Sugestão Diária'), findsOneWidget);
    expect(find.byType(DailyOutfitScreen), findsOneWidget);
    expect(find.text('LOOK FORTEMENTE RECOMENDADO'), findsWidgets);
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

  testWidgets('HarmonIA OnboardingProfileScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingProfileScreen(),
      ),
    );

    expect(find.text('HarmonIA'), findsOneWidget);
    expect(find.text('CONSULTORIA DE ESTILO & MORFOCROMIA'), findsOneWidget);
  });
}
