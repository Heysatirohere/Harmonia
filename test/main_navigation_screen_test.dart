import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/core/demo/demo_mode.dart';
import 'package:harmonia_mvp/mocks/mock_atelier_store.dart';
import 'package:harmonia_mvp/presentation/screens/main_navigation_screen.dart';
import 'package:harmonia_mvp/presentation/screens/scan_item_screen.dart';
import 'package:harmonia_mvp/presentation/screens/store_mirror_screen.dart';
import 'package:harmonia_mvp/presentation/widgets/editorial_nav_bar.dart';

void main() {
  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));
    await tester.pump();
  }

  testWidgets('NavBar alterna entre as 3 abas enxutas e avatar abre gaveta lateral do Ateliê (estilo X)', (tester) async {
    await pumpShell(tester);

    expect(find.text('Look do Dia'), findsOneWidget);
    expect(MainNavigationScreen.destinations.length, 3);

    await tester.tap(find.byTooltip('Acervo'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Guarda-roupa'), findsOneWidget);

    await tester.tap(find.byTooltip('Editorial'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Editorial'), findsOneWidget);

    // Avatar no canto superior esquerdo abre a gaveta lateral (estilo X mobile)
    await tester.tap(find.byTooltip('Ateliê').hitTestable().first);
    await tester.pumpAndSettle();

    expect(find.text('Ateliê & Perfil de Estilo'), findsOneWidget);
    expect(find.text('Saúde do Acervo & ESG'), findsOneWidget);
    expect(find.text('Lacunas do Acervo (3.6.1)'), findsOneWidget);
    expect(find.text('Brechó Circular'), findsOneWidget);
    expect(find.text('Conta & Segurança'), findsOneWidget);

    // Tocar em Ateliê & Perfil de Estilo na gaveta abre a tela completa de Perfil
    await tester.tap(find.text('Ateliê & Perfil de Estilo'));
    await tester.pumpAndSettle();
    expect(find.text('ATELIÊ & PERFIL'), findsOneWidget);
    expect(find.text('Recalibrar Colorimetria'), findsOneWidget);
    expect(find.text('Refazer Perfil de Estilo'), findsOneWidget);
  });

  testWidgets('FAB flutuante de captura (estilo X) abre a bandeja com Scan, Provador e Editorial', (tester) async {
    await pumpShell(tester);

    expect(find.byType(AtelierCaptureFab), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Capturar peça ou abrir provador'));
    await tester.pumpAndSettle();
    expect(find.text('Digitalizar peça'), findsOneWidget);
    expect(find.text('Modo Provador'), findsOneWidget);
    expect(find.text('Publicar no Editorial'), findsOneWidget);

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

  testWidgets('Modo Demo Offline (MockAtelierStore) opera 100% sem servidor com dados e interações', (tester) async {
    setDemoModeForTesting(true);
    MockAtelierStore.instance.reset();
    addTearDown(() => setDemoModeForTesting(false));

    await pumpShell(tester);
    await tester.pumpAndSettle();

    // Clima e Look do Dia carregados instantaneamente em memória
    expect(find.textContaining('SÃO PAULO'), findsOneWidget);
    expect(find.text('Blazer Desestruturado em Linho'), findsOneWidget);

    // Aprovar look em memória sem servidor
    await tester.ensureVisible(find.text('Aprovar look do dia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aprovar look do dia'));
    await tester.pumpAndSettle();
    expect(find.text('Look aprovado'), findsOneWidget);

    // Alterna para o Acervo e verifica peças carregadas offline
    await tester.tap(find.byTooltip('Acervo'));
    await tester.pumpAndSettle();
    expect(find.text('Camisa Regata Seda Areia'), findsOneWidget);

    // Gaveta lateral restaura dados da demo em 1 toque
    await tester.tap(find.byTooltip('Ateliê').hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.text('Restaurar Dados da Demo'), findsOneWidget);
    await tester.tap(find.text('Restaurar Dados da Demo'));
    await tester.pumpAndSettle();
    expect(find.text('Dados de demonstração restaurados com sucesso.'), findsOneWidget);
  });
}
