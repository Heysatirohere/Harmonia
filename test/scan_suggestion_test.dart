import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/models/garment_segmentation.dart';
import 'package:harmonia_mvp/presentation/screens/scan_item_screen.dart';

import 'support/fake_wardrobe_service.dart';

// PNG 1x1 transparente
final _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

GarmentSegmentation segmentation({GarmentSuggestion? suggestion}) => GarmentSegmentation(
      cutoutPng: _pngBytes,
      width: 1,
      height: 1,
      processingMs: 900,
      colors: const [GarmentColor(l: 20, a: 0, b: -2, hex: '#303134', percentage: 100, name: 'Grafite')],
      suggestion: suggestion,
    );

const _stripedSkirt = GarmentSuggestion(
  category: 'Partes de baixo',
  name: 'Saia com listras',
  pattern: 'striped',
  formality: 0.5,
  confidence: 0.95,
);

Future<void> pickPhoto(WidgetTester tester, FakeWardrobeService service) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: ScanItemScreen(
      service: service,
      capturePhoto: (source) async => (bytes: _pngBytes, name: 'saia.png'),
    ),
  ));
  await tester.tap(find.text('Fotografe a peça'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Galeria de Fotos'));
  await tester.pumpAndSettle();
}

String nameField(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField).first).controller!.text;

void main() {
  testWidgets('a sugestão da IA preenche nome e categoria e avisa para conferir', (tester) async {
    await pickPhoto(tester, FakeWardrobeService([], segmentation: segmentation(suggestion: _stripedSkirt)));

    expect(nameField(tester), 'Saia com listras');
    expect(find.text('Nome, categoria e formalidade sugeridos pela IA. Confira antes de catalogar.', skipOffstage: false), findsOneWidget);
  });

  testWidgets('o nome que a pessoa digitou não é trocado pela sugestão', (tester) async {
    final service = FakeWardrobeService([], segmentation: segmentation(suggestion: _stripedSkirt));
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: ScanItemScreen(service: service, capturePhoto: (source) async => (bytes: _pngBytes, name: 'saia.png')),
    ));
    await tester.enterText(find.byType(TextField).first, 'Saia da vovó');

    await tester.tap(find.text('Fotografe a peça'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galeria de Fotos'));
    await tester.pumpAndSettle();

    expect(nameField(tester), 'Saia da vovó');
  });

  testWidgets('sem sugestão, o nome fica vazio para a pessoa escrever', (tester) async {
    await pickPhoto(tester, FakeWardrobeService([], segmentation: segmentation()));

    expect(nameField(tester), isEmpty);
    expect(find.textContaining('sugeridos pela IA', skipOffstage: false), findsNothing);
  });
}
