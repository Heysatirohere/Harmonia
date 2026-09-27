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

    // Clica na aba Feed
    await tester.tap(find.text('Feed'));
    await tester.pump();

    expect(find.text('FEED COMUNITÁRIO • EDITORIAL GALLERY'), findsOneWidget);

    // Clica na aba Perfil
    await tester.tap(find.text('Perfil'));
    await tester.pump();

    expect(find.text('Perfil & Governança'), findsOneWidget);
  });
}
