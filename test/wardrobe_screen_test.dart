import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/data/services/wardrobe_api_service.dart';
import 'package:harmonia_mvp/mocks/mock_clothes.dart';
import 'package:harmonia_mvp/models/outfit_combination.dart';
import 'package:harmonia_mvp/presentation/atelier/atelier_room.dart';
import 'package:harmonia_mvp/presentation/screens/wardrobe_screen.dart';
import 'package:harmonia_mvp/presentation/widgets/clothing_card.dart';
import 'package:harmonia_mvp/presentation/widgets/ihe_score_gauge.dart';

import 'support/fake_wardrobe_service.dart';

void main() {
  Future<void> pumpWardrobe(WidgetTester tester, FakeWardrobeService service) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: WardrobeScreen(service: service)));
    await tester.pumpAndSettle();
  }

  testWidgets('acervo vazio convida a digitalizar a primeira peça', (tester) async {
    await pumpWardrobe(tester, FakeWardrobeService(const []));

    expect(find.text('Sua arara está vazia'), findsOneWidget);
    expect(find.text('Digitalizar peça'), findsOneWidget);
  });

  testWidgets('falha da API aparece e permite tentar de novo', (tester) async {
    final service = FakeWardrobeService(
      mockClothes.take(2).toList(),
      failure: const WardrobeException('Não foi possível carregar o seu acervo.'),
    );
    await pumpWardrobe(tester, service);

    expect(find.text('O acervo não respondeu'), findsOneWidget);
    expect(find.text('Não foi possível carregar o seu acervo.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(find.text('O acervo não respondeu'), findsNothing);
    expect(find.text(mockClothes.first.name, skipOffstage: false), findsWidgets);
  });

  testWidgets('abre arara magnética, filtra por categoria e abre folha de detalhes e edição de metadados', (tester) async {
    final items = mockClothes.take(4).map((i) => i.copyWith()).toList();
    final service = FakeWardrobeService(items);
    await pumpWardrobe(tester, service);

    // 1. Abrir e fechar bancada de montagem (Arara Magnética)
    expect(find.text('MONTAR LOOK'), findsOneWidget);
    await tester.tap(find.text('MONTAR LOOK'));
    await tester.pumpAndSettle();
    expect(find.text('ARARA MAGNÉTICA • ARRASTE PEÇAS'), findsOneWidget);
    expect(find.text('FECHAR ARARA'), findsOneWidget);
    await tester.tap(find.text('FECHAR ARARA'));
    await tester.pumpAndSettle();

    // 2. Toque na primeira peça para abrir _GarmentDetailSheet
    await tester.tap(find.byType(ClothingCard).first);
    await tester.pumpAndSettle();

    expect(find.text('MORFOCROMIA (CIE L*a*b*)'), findsOneWidget);
    expect(find.text('Editar Atributos'), findsOneWidget);

    // 3. Abrir _EditGarmentSheet e editar preço, estação, cápsula e destinação ESG
    await tester.tap(find.text('Editar Atributos'));
    await tester.pumpAndSettle();

    expect(find.text('Ajuste Fino de Metadados'), findsOneWidget);
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.first, 'Blazer Linho Refinado');
    await tester.enterText(textFields.at(1), '320.00');

    await tester.tap(find.text('Inverno'));
    await tester.pump();
    await tester.tap(find.text('Trabalho'));
    await tester.pump();
    await tester.tap(find.text('Brechó'));
    await tester.pump();

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Blazer Linho Refinado'), findsWidgets);
    expect(find.text('Separada para Brechó / Venda'), findsOneWidget);
    expect(find.text('Inverno'), findsOneWidget);
  });

  testWidgets('permite excluir peça a partir da folha de detalhes (RN04)', (tester) async {
    final items = [mockClothes.first.copyWith()];
    final service = FakeWardrobeService(items);
    await pumpWardrobe(tester, service);

    await tester.tap(find.byType(ClothingCard).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Excluir Peça'), findsOneWidget);
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(service.items, isEmpty);
    expect(find.text('Sua arara está vazia'), findsOneWidget);
  });

  testWidgets('IheScoreGauge e AtelierIheGauge exibem os 4 pilares e o modal detalhado', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    const subScores = IheSubScores(
      overallScore: 89,
      sColor: 0.92,
      sBio: 0.88,
      sOcasion: 0.85,
      sCos: 0.90,
      dominantColor: Color(0xFFA34836),
      occasionContext: '22°C • Casual Chic',
      paletteColors: [Color(0xFFA34836), Color(0xFFE9E4D6)],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const AtelierIheGauge(
                  ihePercentage: 89,
                  sCor: 0.92,
                  sBio: 0.88,
                  sOcasion: 0.85,
                  sCos: 0.90,
                  dominantColor: Color(0xFFA34836),
                  dominantLabLabel: 'L* 54 · a* 32 · b* 28',
                  stylingAdvice: 'Contraste harmônico.',
                  room: AtelierRoom.velvetBordeaux,
                ),
                const AtelierIheGauge(
                  ihePercentage: 62,
                  sCor: 0.65,
                  sBio: 0.60,
                  sOcasion: 0.60,
                  sCos: 0.62,
                  dominantColor: Color(0xFF4B5842),
                ),
                const IheScoreGauge(ihe: subScores),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('89%'), findsWidgets);
    expect(find.text('Harmonia Equilibrada'), findsOneWidget);
    expect(find.text('✦ LOOK FORTEMENTE RECOMENDADO'), findsWidgets);

    // Tocar no IheScoreGauge abre _IhePillarsDetailSheet com a decomposição dos 4 pilares
    await tester.tap(find.text('89%').last);
    await tester.pumpAndSettle();

    expect(find.text('DECOMPOSIÇÃO DOS 4 PILARES ANALÍTICOS'), findsOneWidget);
    expect(find.text('1. Harmonia Cromática (S_cor)'), findsOneWidget);
    expect(find.text('2. Compensação Morfológica (S_bio)'), findsOneWidget);
    expect(find.text('3. Contexto & Clima (S_ocasion)'), findsOneWidget);
    expect(find.text('4. Ressonância Vetorial (S_cos)'), findsOneWidget);
  });
}
