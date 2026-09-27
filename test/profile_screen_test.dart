import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/presentation/screens/profile_screen.dart';

void main() {
  testWidgets('ProfileScreen renders user profile, freemium card and recalibration items', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(),
      ),
    );

    expect(find.text('Ateliê & Perfil'), findsOneWidget);
    expect(find.text('Helena von Suttner'), findsOneWidget);
    expect(find.text('SAÚDE DA ASSINATURA (RN02)'), findsOneWidget);
    expect(find.text('Recalibrar Colorimetria'), findsOneWidget);
    expect(find.text('Ajustar Biótipo Corporal'), findsOneWidget);
  });
}
