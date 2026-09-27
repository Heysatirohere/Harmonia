import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/presentation/screens/gap_analysis_screen.dart';

void main() {
  testWidgets('GapAnalysisScreen renders gap category and available affiliate products', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GapAnalysisScreen(),
      ),
    );

    expect(find.text('Otimização de Acervo'), findsOneWidget);
    expect(find.text('Camisa Linho Off-White'), findsOneWidget);
    expect(find.text('Lojas Renner'), findsWidgets);
    expect(find.text('C&A Brasil'), findsWidgets);

    // Verify out of stock item title is NOT present (RN03)
    expect(find.text('Camisa Linho Esgotada Edição Especial'), findsNothing);
  });
}
