import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/models/clothing_item.dart';
import 'package:harmonia_mvp/models/wardrobe_filters.dart';
import 'package:harmonia_mvp/presentation/screens/wardrobe_screen.dart';

import 'support/fake_wardrobe_service.dart';

ClothingItem piece(String name, {String? family, double? formality, int uses = 0, int? daysIdle}) => ClothingItem(
      id: name,
      name: name,
      category: 'Partes de cima',
      dominantColor: Colors.blueGrey,
      labColorSpace: 'L* 40 a* 0 b* -20',
      usageRate: uses,
      imageUrl: '',
      brandOrProvenance: 'Acervo Pessoal',
      colorFamily: family,
      formalityScore: formality,
      daysIdle: daysIdle,
    );

void main() {
  final blazer = piece('Blazer marinho', family: 'Azuis', formality: 0.8, uses: 4, daysIdle: 5);
  final camiseta = piece('Camiseta verde', family: 'Verdes', formality: 0.2, uses: 0, daysIdle: 120);
  final camisa = piece('Camisa azul', family: 'Azuis', formality: 0.5, uses: 1, daysIdle: 40);

  group('WardrobeFilters', () {
    test('sem filtro, tudo passa', () {
      expect([blazer, camiseta, camisa].where(WardrobeFilters.none.matches), hasLength(3));
    });

    test('opções do mesmo critério se somam; critérios diferentes se cruzam', () {
      final filters = WardrobeFilters.none
          .toggleColor('Azuis')
          .toggleColor('Verdes')
          .toggleFormality(FormalityBand.formal)
          .toggleFormality(FormalityBand.casual);

      expect([blazer, camiseta, camisa].where(filters.matches), [blazer, camiseta]);
      expect(filters.activeCount, 4);
    });

    test('frequência de uso segue as janelas do dashboard', () {
      bool only(UsageBand band, ClothingItem item) => WardrobeFilters.none.toggleUsage(band).matches(item);

      expect(only(UsageBand.active, blazer), isTrue);
      expect(only(UsageBand.idle, camisa), isTrue);
      expect(only(UsageBand.dormant, camiseta), isTrue);
      expect(only(UsageBand.neverWorn, camiseta), isTrue);
      expect(only(UsageBand.neverWorn, blazer), isFalse);
    });

    test('peça sem dado não passa num filtro que depende dele', () {
      final unknown = piece('Sem dados');
      final filters = WardrobeFilters.none.toggleColor('Azuis');

      expect(filters.matches(unknown), isFalse);
      expect(WardrobeFilters.none.toggleUsage(UsageBand.dormant).matches(unknown), isFalse);
    });

    test('tocar de novo desmarca a opção', () {
      expect(WardrobeFilters.none.toggleColor('Azuis').toggleColor('Azuis').isEmpty, isTrue);
    });
  });

  testWidgets('refinar por cor filtra a arara e limpar volta tudo', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: WardrobeScreen(service: FakeWardrobeService([blazer, camiseta, camisa])),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('REFINAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verdes'));
    await tester.pumpAndSettle();
    expect(find.text('1 peça'), findsOneWidget);

    await tester.tap(find.text('Ver peças'));
    await tester.pumpAndSettle();
    expect(find.text('Camiseta verde', skipOffstage: false), findsWidgets);
    expect(find.text('Blazer marinho', skipOffstage: false), findsNothing);
    expect(find.bySemanticsLabel('REFINAR • 1'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('LIMPAR FILTROS'));
    await tester.pumpAndSettle();
    expect(find.text('Blazer marinho', skipOffstage: false), findsWidgets);
  });
}
