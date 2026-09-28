import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/presentation/screens/main_navigation_screen.dart';
import 'package:harmonia_mvp/presentation/screens/scan_item_screen.dart';
import 'package:harmonia_mvp/presentation/screens/store_mirror_screen.dart';

void main() {
  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));
    await tester.pump();
  }

  testWidgets('NavBar alterna entre as quatro abas pelos ícones', (tester) async {
    await pumpShell(tester);

    expect(find.text('Sugestão Diária'), findsOneWidget);

    await tester.tap(find.byTooltip('Editorial'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Editorial Gallery'), findsOneWidget);

    await tester.tap(find.byTooltip('Ateliê'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Ateliê & Perfil'), findsOneWidget);
    expect(find.text('Lacunas do Acervo (3.6.1)'), findsOneWidget);
    expect(find.text('Refazer Perfil de Estilo'), findsOneWidget);
    expect(find.text('Conta & Segurança'), findsOneWidget);
  });

  testWidgets('Ação central abre a bandeja de captura com Scan e Provador', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.bySemanticsLabel('Capturar peça ou abrir provador'));
    await tester.pumpAndSettle();
    expect(find.text('Digitalizar peça'), findsOneWidget);
    expect(find.text('Modo Provador'), findsOneWidget);

    await tester.tap(find.text('Digitalizar peça'));
    await tester.pumpAndSettle();
    expect(find.byType(ScanItemScreen), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Capturar peça ou abrir provador'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modo Provador'));
    await tester.pump(); // fecha a bandeja
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(); // empilha o provador
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(StoreMirrorScreen), findsOneWidget);
  });
}
