import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/core/color/lab_color.dart';
import 'package:harmonia_mvp/models/clothing_item.dart';
import 'package:harmonia_mvp/models/garment_segmentation.dart';
import 'package:harmonia_mvp/presentation/widgets/segmentation_preview.dart';

// PNG 1x1 transparente
final _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  group('Conversão L*a*b* -> sRGB', () {
    test('reproduz os valores do backend (colour-science)', () {
      expect(labToColor(42.29, 36.35, 28.95), const Color(0xFFA34836));
      expect(labToColor(100, 0, 0), const Color(0xFFFFFFFF));
      expect(labToColor(0, 0, 0), const Color(0xFF000000));
    });

    test('satura cores fora do gamut sRGB', () {
      final c = labToColor(50, 127, -128);
      expect(c.a, 1.0);
    });
  });

  group('GarmentSegmentation.fromJson', () {
    test('decodifica recorte PNG e cores da API', () {
      final seg = GarmentSegmentation.fromJson({
        'image_png_base64': base64Encode(_pngBytes),
        'width': 1,
        'height': 1,
        'processing_ms': 1093,
        'colors': [
          {'L': 42.3, 'a': 36.3, 'b': 29.0, 'hex': '#A34836', 'percentage': 88, 'name': 'Terracota'},
        ],
      });

      expect(seg.cutoutPng, _pngBytes);
      expect(seg.colors.single.color, const Color(0xFFA34836));
      expect(seg.colors.single.labLabel, 'L* 42.3, a* 36.3, b* 29.0');
    });
  });

  group('ClothingItem.toApiJson', () {
    const base = ClothingItem(
      id: 'x',
      name: 'Camisa',
      category: 'Partes de cima',
      dominantColor: Color(0xFFA34836),
      labColorSpace: 'L* 58.4, a* -2.5, b* 24.1',
      usageRate: 0,
      imageUrl: 'https://example.com/a.png',
      brandOrProvenance: 'Acervo Pessoal',
    );

    test('envia as coordenadas e a formalidade reais da peça', () {
      final json = base.copyWith(labL: 42.3, labA: 36.3, labB: 29.0, formalityScore: 0.8).toApiJson();

      expect(json['dominant_l'], 42.3);
      expect(json['dominant_a'], 36.3);
      expect(json['dominant_b'], 29.0);
      expect(json['formality_score'], 0.8);
      expect(json.containsKey('cut_type'), isFalse);
    });

    test('peças sem coordenadas numéricas usam o rótulo L*a*b*', () {
      final json = base.toApiJson();

      expect(json['dominant_l'], 58.4);
      expect(json['dominant_a'], -2.5);
      expect(json['dominant_b'], 24.1);
    });

    test('fromJson converte L*a*b* para a cor real, não para cinza', () {
      final item = ClothingItem.fromJson({
        'id': '1',
        'category': 'top',
        'image_url': '',
        'dominant_l': 42.29,
        'dominant_a': 36.35,
        'dominant_b': 28.95,
        'formality_score': 0.7,
      });

      expect(item.dominantColor, const Color(0xFFA34836));
      expect(item.formalityScore, 0.7);
    });
  });

  group('SegmentationPreview', () {
    Future<void> pump(WidgetTester tester, SegmentationPreview preview) {
      return tester.pumpWidget(MaterialApp(home: Scaffold(body: preview)));
    }

    testWidgets('mostra o recorte e alterna para a foto original', (tester) async {
      await pump(tester, SegmentationPreview(originalBytes: _pngBytes, cutoutBytes: Uint8List.fromList(_pngBytes)));

      expect(find.text('IA SEGMENTADA • CANAL ALFA'), findsOneWidget);
      await tester.tap(find.text('VER FOTO ORIGINAL'));
      await tester.pumpAndSettle();
      expect(find.text('FOTO ORIGINAL (COM FUNDO)'), findsOneWidget);
      expect(find.text('VER RECORTE'), findsOneWidget);
    });

    testWidgets('exibe shimmer durante o processamento', (tester) async {
      await pump(tester, SegmentationPreview(originalBytes: _pngBytes, isProcessing: true));

      expect(find.text('REMOVENDO FUNDO E ISOLANDO CANAL ALFA...'), findsOneWidget);
      expect(find.text('TROCAR FOTO'), findsNothing);
    });

    testWidgets('exibe o erro com opção de tentar de novo', (tester) async {
      var retries = 0;
      await pump(
        tester,
        SegmentationPreview(
          originalBytes: _pngBytes,
          errorMessage: 'Nenhuma peça foi identificada na foto.',
          onRetry: () => retries++,
        ),
      );

      expect(find.text('Nenhuma peça foi identificada na foto.'), findsOneWidget);
      await tester.tap(find.text('TENTAR DE NOVO'));
      expect(retries, 1);
    });
  });
}
