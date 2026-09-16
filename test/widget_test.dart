import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/main.dart';
import 'package:harmonia_mvp/presentation/screens/daily_outfit_screen.dart';
import 'package:harmonia_mvp/presentation/widgets/ihe_score_gauge.dart';
import 'package:harmonia_mvp/presentation/widgets/outfit_composition_card.dart';

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
}
