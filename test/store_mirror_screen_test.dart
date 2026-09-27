import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/presentation/screens/daily_outfit_screen.dart';
import 'package:harmonia_mvp/presentation/screens/store_mirror_screen.dart';
import 'package:harmonia_mvp/presentation/widgets/store_parity_sheet.dart';

void main() {
  group('StoreMirrorScreen Widget Tests (RF08 / RF09)', () {
    testWidgets('renders camera viewfinder HUD, controls, and custom shutter button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StoreMirrorScreen(),
        ),
      );

      // HUD Title
      expect(find.text('PROVADOR AR • MIRROR MODE'), findsOneWidget);

      // Peça detectada inicial (Blazer Linho Terracota)
      expect(find.text('Blazer Linho Terracota'), findsOneWidget);
      expect(find.text('Lojas Renner • Peça Detectada'), findsOneWidget);

      // Botão de simulação de alternância de loja
      expect(find.text('Simular: Blazer Linho Terracota (Lojas Renner)'),
          findsOneWidget);
    });

    testWidgets('toggling mock scenario switches detected store garment',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StoreMirrorScreen(),
        ),
      );

      // Toque no seletor de simulação de loja (alterna para C&A)
      await tester.tap(
          find.text('Simular: Blazer Linho Terracota (Lojas Renner)'));
      await tester.pumpAndSettle();

      expect(find.text('Calça Alfaiataria Areia'), findsOneWidget);
      expect(find.text('C&A Modas • Peça Detectada'), findsOneWidget);
    });

    testWidgets('pressing shutter button triggers haptic capture and opens parity sheet',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: StoreMirrorScreen(),
        ),
      );

      // Encontra e clica no Obturador Fotográfico
      final shutterFinder = find.byKey(const Key('shutter_button'));
      expect(shutterFinder, findsOneWidget);

      await tester.tap(shutterFinder);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Verifica se a StoreParitySheet foi aberta automaticamente
      expect(find.byType(StoreParitySheet), findsOneWidget);
      expect(find.text('Harmonia com seu Acervo'), findsOneWidget);
      expect(find.text('86%'), findsOneWidget);
    });

    testWidgets('DailyOutfitScreen AppBar action opens StoreMirrorScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DailyOutfitScreen(),
        ),
      );

      // Clica no ícone de Provador na AppBar
      final mirrorIconFinder = find.byIcon(Icons.center_focus_strong);
      expect(mirrorIconFinder, findsOneWidget);

      await tester.tap(mirrorIconFinder);
      await tester.pumpAndSettle();

      // Verifica se navegou para a StoreMirrorScreen
      expect(find.byType(StoreMirrorScreen), findsOneWidget);
      expect(find.text('PROVADOR AR • MIRROR MODE'), findsOneWidget);
    });
  });
}
