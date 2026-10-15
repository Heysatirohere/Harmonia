import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/data/services/outfit_api_service.dart';
import 'package:harmonia_mvp/models/wardrobe_gap.dart';
import 'package:harmonia_mvp/presentation/screens/gap_analysis_screen.dart';

import 'gap_analysis_test.dart' show gapsJson;
import 'support/fake_outfit_service.dart';

Future<FakeOutfitService> pumpScreen(WidgetTester tester, {Map<String, WardrobeGapReport>? reports, OutfitException? failure}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final service = FakeOutfitService(const [], failure: failure);
  service.gapReports.addAll(reports ?? {'CASUAL': WardrobeGapReport.fromJson(gapsJson())});
  await tester.pumpWidget(MaterialApp(home: GapAnalysisScreen(service: service)));
  await tester.pump();
  return service;
}

void main() {
  testWidgets('mostra as lacunas do acervo e onde comprar', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Otimização de Acervo'), findsOneWidget);
    expect(find.text('IHE MÉDIO 57%'), findsOneWidget);
    expect(find.text('Pantalona caramelo'), findsOneWidget);
    expect(find.text('MELHOR LOOK 61%'), findsOneWidget);
    expect(find.text('+4.4 PTS NO IHE'), findsOneWidget);
    expect(find.text('LOJAS RENNER'), findsOneWidget);
    expect(find.text('Calça pantalona caramelo'), findsOneWidget);
  });

  testWidgets('trocar a ocasião pede as lacunas dessa ocasião', (tester) async {
    final service = await pumpScreen(tester);

    await tester.tap(find.text('Trabalho'));
    await tester.pump();

    expect(service.gapOccasions, ['CASUAL', 'TRABALHO']);
    expect(find.text('Pantalona caramelo'), findsNothing);
    expect(find.text('Nenhuma lacuna por aqui'), findsOneWidget);
  });

  testWidgets('falha da API mostra o erro e tentar de novo recarrega', (tester) async {
    final service = await pumpScreen(tester, failure: const OutfitException('Sem conexão com o ateliê.'));

    expect(find.text('O ateliê não respondeu'), findsOneWidget);
    expect(find.text('Sem conexão com o ateliê.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Tentar de novo'));
    await tester.pump();

    expect(service.gapOccasions, ['CASUAL', 'CASUAL']);
    expect(find.text('Pantalona caramelo'), findsOneWidget);
  });

  testWidgets('acervo que ainda não forma looks pede para digitalizar peças', (tester) async {
    await pumpScreen(tester, reports: {
      'CASUAL': const WardrobeGapReport(occasion: 'CASUAL', baselineIhe: null, gaps: []),
    });

    expect(find.text('Seu acervo ainda não forma looks'), findsOneWidget);
  });
}
