import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/mocks/mock_clothes.dart';
import 'package:harmonia_mvp/presentation/atelier/atelier_room.dart';
import 'package:harmonia_mvp/presentation/atelier/room_scene.dart';
import 'package:harmonia_mvp/presentation/screens/wardrobe_screen.dart';
import 'package:harmonia_mvp/presentation/widgets/filter_chips_bar.dart';

import 'support/fake_wardrobe_service.dart';

const _emerald = AtelierRoom.silkEmerald;
const _bordeaux = AtelierRoom.velvetBordeaux;
const _ochre = AtelierRoom.gildedOchre;

RoomBlend _resolve(double scrollOffset, {bool reduceMotion = false}) => resolveRoomBlend(
      const [(0, _emerald), (1000, _bordeaux), (2000, _ochre)],
      scrollOffset: scrollOffset,
      viewportExtent: 800,
      fallback: AtelierRoom.tapestryNoir,
      reduceMotion: reduceMotion,
    );

void main() {
  group('resolveRoomBlend', () {
    test('sem seções usa a Sala de fallback', () {
      expect(
        resolveRoomBlend(const [], scrollOffset: 0, viewportExtent: 800, fallback: _ochre),
        const RoomBlend.solid(_ochre),
      );
    });

    // Tela de 800: a seção bordô (início em 1000) cruza 55% da tela (440) no scroll 560
    // e termina a troca 40% (320) depois, no scroll 880.
    test('enquanto a próxima seção não cruza o meio da tela, a Sala é sólida', () {
      expect(_resolve(0), const RoomBlend.solid(_emerald));
      expect(_resolve(560), const RoomBlend.solid(_emerald));
    });

    test('dissolve enquanto o início da seção sobe 40% da tela', () {
      final halfway = _resolve(720);
      expect(halfway.from, _emerald);
      expect(halfway.to, _bordeaux);
      expect(halfway.t, closeTo(0.5, 0.03));

      final start = _resolve(580);
      expect(start.t, inExclusiveRange(0, 0.05), reason: 'curva suave: sem salto no início');
    });

    test('completa a troca e segue para a Sala seguinte', () {
      expect(_resolve(880), const RoomBlend.solid(_bordeaux));
      expect(_resolve(1900), const RoomBlend.solid(_ochre));
    });

    test('com animações reduzidas, troca por corte no meio do trajeto', () {
      expect(_resolve(700, reduceMotion: true), const RoomBlend.solid(_emerald));
      expect(_resolve(740, reduceMotion: true), const RoomBlend.solid(_bordeaux));
    });

    test('seções consecutivas na mesma Sala não geram dissolução', () {
      final blend = resolveRoomBlend(
        const [(0, _emerald), (1000, _emerald)],
        scrollOffset: 720,
        viewportExtent: 800,
        fallback: _ochre,
      );
      expect(blend, const RoomBlend.solid(_emerald));
    });
  });

  group('RoomScene', () {
    Future<RoomSceneState> pumpScene(WidgetTester tester, ScrollController controller) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: RoomScene(
            room: AtelierRoom.tapestryNoir,
            child: CustomScrollView(
              controller: controller,
              slivers: const [
                RoomMarker(room: _emerald),
                SliverToBoxAdapter(child: SizedBox(height: 1000)),
                RoomMarker(room: _bordeaux),
                SliverToBoxAdapter(child: SizedBox(height: 1000)),
                RoomMarker(room: _ochre),
                SliverToBoxAdapter(child: SizedBox(height: 1000)),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.state<RoomSceneState>(find.byType(RoomScene));
    }

    testWidgets('segue os marcadores de seção conforme o scroll', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final scene = await pumpScene(tester, controller);

      expect(scene.blend.value, const RoomBlend.solid(_emerald));

      controller.jumpTo(720);
      await tester.pump();
      expect(scene.blend.value.from, _emerald);
      expect(scene.blend.value.to, _bordeaux);
      expect(scene.blend.value.t, closeTo(0.5, 0.03));

      controller.jumpTo(1900);
      await tester.pump();
      expect(scene.blend.value, const RoomBlend.solid(_ochre));

      controller.jumpTo(0);
      await tester.pump();
      expect(scene.blend.value, const RoomBlend.solid(_emerald));
    });
  });

  group('WardrobeScreen', () {
    Future<void> pumpWardrobe(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: WardrobeScreen(service: FakeWardrobeService(mockClothes))));
      await tester.pumpAndSettle();
    }

    testWidgets('cada categoria abre uma seção com a sua Sala', (tester) async {
      await pumpWardrobe(tester);

      final categories = mockClothes.map((i) => i.category).toSet();
      final markers = tester.widgetList<RoomMarker>(find.byType(RoomMarker, skipOffstage: false));
      expect(
        markers.map((m) => m.room).skip(1).toList(),
        [
          for (final category in ['Partes de cima', 'Partes de baixo', 'Calçados', 'Peças únicas'])
            if (categories.contains(category)) WardrobeScreen.roomFor(category),
          for (final category in categories)
            if (!['Partes de cima', 'Partes de baixo', 'Calçados', 'Peças únicas'].contains(category))
              WardrobeScreen.roomFor(category),
        ],
      );
    });

    testWidgets('filtro dissolve a tela inteira para a Sala da categoria', (tester) async {
      await pumpWardrobe(tester);
      final scene = tester.state<RoomSceneState>(find.byType(RoomScene));
      expect(scene.blend.value, const RoomBlend.solid(_emerald));

      final chips = tester.widget<FilterChipsBar>(find.byType(FilterChipsBar));
      chips.onCategorySelected(chips.categories.indexOf('Calçados'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(scene.blend.value.to, _ochre, reason: 'dissolução em andamento');
      expect(scene.blend.value.t, inExclusiveRange(0, 1));

      await tester.pumpAndSettle();
      expect(scene.blend.value, const RoomBlend.solid(_ochre));
      expect(find.byType(RoomMarker, skipOffstage: false), findsNWidgets(2));
    });
  });
}
