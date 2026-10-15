import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/data/services/outfit_api_service.dart';
import 'package:harmonia_mvp/models/garment_segmentation.dart';
import 'package:harmonia_mvp/presentation/screens/store_mirror_screen.dart';
import 'package:harmonia_mvp/presentation/widgets/store_parity_sheet.dart';
import 'package:image_picker/image_picker.dart';

import 'support/fake_outfit_service.dart';
import 'support/fake_wardrobe_service.dart';

/// PNG 1x1 transparente
final _pixel = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

final _segmentation = GarmentSegmentation(
  cutoutPng: _pixel,
  width: 1,
  height: 1,
  colors: const [GarmentColor(l: 45, a: 32, b: 25, hex: '#A34836', percentage: 80, name: 'Terracota')],
  processingMs: 900,
  styleEmbedding: List.filled(512, 0.044),
);

void main() {
  late List<ImageSource> sources;

  Future<void> pumpMirror(
    WidgetTester tester, {
    required FakeWardrobeService wardrobe,
    required FakeOutfitService outfits,
    bool cancel = false,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    sources = [];
    await tester.pumpWidget(MaterialApp(
      home: StoreMirrorScreen(
        wardrobeService: wardrobe,
        outfitService: outfits,
        capturePhoto: (source) async {
          sources.add(source);
          return cancel ? null : (bytes: _pixel, name: 'loja.jpg');
        },
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('HUD, categorias e obturador ocupam a tela inteira', (tester) async {
    await pumpMirror(tester, wardrobe: FakeWardrobeService(const []), outfits: FakeOutfitService(const []));

    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(tester.getSize(find.byKey(const Key('mirror_backdrop'))), screen);
    expect(tester.getBottomLeft(find.byKey(const Key('shutter_button'))).dy, greaterThan(screen.height * 0.75));
    expect(find.text('MIRROR MODE • PROVADOR'), findsOneWidget);
    for (final category in ['Partes de cima', 'Partes de baixo', 'Calçados', 'Peças únicas']) {
      expect(find.text(category), findsOneWidget);
    }
  });

  testWidgets('fotografar compara a peça com o acervo e abre a bandeja', (tester) async {
    final outfits = FakeOutfitService(const []);
    await pumpMirror(
      tester,
      wardrobe: FakeWardrobeService(const [], segmentation: _segmentation),
      outfits: outfits,
    );

    await tester.tap(find.text('Partes de baixo'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('shutter_button')));
    await tester.pumpAndSettle();

    expect(sources, [ImageSource.camera]);
    final sent = outfits.parityRequests.single;
    expect(sent.category, 'Partes de baixo');
    expect(sent.labCoordinates, (45.0, 32.0, 25.0));
    expect(sent.styleEmbedding, hasLength(512));
    expect(find.byType(StoreParitySheet), findsOneWidget);
    expect(find.text('86%'), findsWidgets);
    expect(find.text('Cores em harmonia com a sua cartela.'), findsOneWidget);
  });

  testWidgets('galeria usa o mesmo fluxo', (tester) async {
    await pumpMirror(
      tester,
      wardrobe: FakeWardrobeService(const [], segmentation: _segmentation),
      outfits: FakeOutfitService(const []),
    );

    await tester.tap(find.byIcon(Icons.photo_library_outlined));
    await tester.pumpAndSettle();

    expect(sources, [ImageSource.gallery]);
    expect(find.byType(StoreParitySheet), findsOneWidget);
  });

  testWidgets('cancelar a câmera não chama a API', (tester) async {
    final outfits = FakeOutfitService(const []);
    await pumpMirror(
      tester,
      wardrobe: FakeWardrobeService(const [], segmentation: _segmentation),
      outfits: outfits,
      cancel: true,
    );

    await tester.tap(find.byKey(const Key('shutter_button')));
    await tester.pumpAndSettle();

    expect(outfits.parityRequests, isEmpty);
    expect(find.byType(StoreParitySheet), findsNothing);
  });

  testWidgets('falha no recorte informa e não abre a bandeja', (tester) async {
    final outfits = FakeOutfitService(const []);
    await pumpMirror(tester, wardrobe: FakeWardrobeService(const []), outfits: outfits);

    await tester.tap(find.byKey(const Key('shutter_button')));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível analisar a foto.'), findsOneWidget);
    expect(outfits.parityRequests, isEmpty);
    expect(find.byType(StoreParitySheet), findsNothing);
  });

  testWidgets('falha da API de paridade informa e não abre a bandeja', (tester) async {
    await pumpMirror(
      tester,
      wardrobe: FakeWardrobeService(const [], segmentation: _segmentation),
      outfits: FakeOutfitService(const [], failure: const OutfitException('Não foi possível comparar a peça agora.')),
    );

    await tester.tap(find.byKey(const Key('shutter_button')));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível comparar a peça agora.'), findsOneWidget);
    expect(find.byType(StoreParitySheet), findsNothing);
  });
}
