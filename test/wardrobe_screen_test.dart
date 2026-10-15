import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/data/services/wardrobe_api_service.dart';
import 'package:harmonia_mvp/mocks/mock_clothes.dart';
import 'package:harmonia_mvp/presentation/screens/wardrobe_screen.dart';

import 'support/fake_wardrobe_service.dart';

void main() {
  Future<void> pumpWardrobe(WidgetTester tester, FakeWardrobeService service) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
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
}
