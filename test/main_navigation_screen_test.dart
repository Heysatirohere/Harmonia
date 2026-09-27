import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/presentation/screens/main_navigation_screen.dart';

void main() {
  testWidgets('MainNavigationScreen allows switching between screens', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: MainNavigationScreen(),
      ),
    );

    // Inicialmente exibe a Sugestão Diária
    expect(find.text('Sugestão Diária'), findsOneWidget);

    // Clica na aba Editorial
    await tester.tap(find.text('Editorial'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Editorial Gallery'), findsOneWidget);

    // Clica na aba Ateliê
    await tester.tap(find.text('Ateliê'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Ateliê & Perfil'), findsOneWidget);
  });
}
