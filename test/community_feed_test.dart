import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/mocks/mock_community_feed.dart';
<<<<<<< HEAD
import 'package:harmonia_mvp/presentation/screens/community_feed_screen.dart';

void main() {
  group('Community Feed Tests (RF14/RF15 & RN05)', () {
    test('mock posts have valid properties and privacy flags', () {
      final posts = MockCommunityFeed.posts;
      expect(posts, isNotEmpty);
      expect(posts.first.isPublic, isTrue);
      expect(posts.first.garmentHotspots, isNotEmpty);
    });

    testWidgets('CommunityFeedScreen renders editorial gallery and filter chips', (WidgetTester tester) async {
=======
import 'package:harmonia_mvp/models/community_post.dart';
import 'package:harmonia_mvp/presentation/screens/community_feed_screen.dart';
import 'package:harmonia_mvp/presentation/widgets/editorial_feed_card.dart';
import 'package:harmonia_mvp/presentation/widgets/share_outfit_sheet.dart';

void main() {
  group('CommunityFeed Models & Mocks Tests (RF14 / RF15 / RN05)', () {
    test('CommunityPost holds metadata and supports copyWith', () {
      final post = MockCommunityFeed.posts.first;

      expect(post.bodyType, 'Ampulheta');
      expect(post.colorPalette, 'Outono Suave');
      expect(post.occasionTag, 'Trabalho & Ateliê');
      expect(post.isPublic, isTrue);

      final updated = post.copyWith(isPublic: false, savesCount: 99);
      expect(updated.isPublic, isFalse);
      expect(updated.savesCount, 99);
    });

    test('MockCommunityFeed provides realistic editorial items', () {
      final posts = MockCommunityFeed.posts;
      expect(posts.length, greaterThanOrEqualTo(3));
      expect(posts.any((p) => p.bodyType == 'Ampulheta'), isTrue);
      expect(posts.any((p) => p.bodyType == 'Retângulo'), isTrue);
      expect(posts.any((p) => p.bodyType == 'Triângulo Invertido'), isTrue);
    });
  });

  group('EditorialFeedCard Widget Tests (RF14)', () {
    testWidgets('renders author, look details, and handles applaud / save taps',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final post = MockCommunityFeed.posts.first;
      bool applauded = false;
      bool saved = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorialFeedCard(
              post: post,
              onApplaud: () => applauded = true,
              onSave: () => saved = true,
            ),
          ),
        ),
      );

      // Autor e Título
      expect(find.text('Helena Vasconcelos'), findsOneWidget);
      expect(find.text('Sobreposições Terracota em Linho Cru'), findsOneWidget);
      expect(find.text('LOOK FORTEMENTE RECOMENDADO'), findsOneWidget);

      // Reações
      await tester.tap(find.byIcon(Icons.favorite_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      expect(applauded, isTrue);

      await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      expect(saved, isTrue);
    });
  });

  group('ShareOutfitSheet Widget Tests (RF14 & RN05)', () {
    testWidgets('allows toggling privacy switch (RN05) and publishing outfit',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      CommunityPost? publishedPost;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShareOutfitSheet(
              onPublish: (post) => publishedPost = post,
            ),
          ),
        ),
      );

      expect(find.text('Publicar Look no Feed'), findsOneWidget);
      expect(find.text('Visibilidade Pública'), findsOneWidget);

      // Alterna Chave de Privacidade para Privado (RN05)
      await tester.tap(find.byType(Switch));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Visibilidade Privada'), findsOneWidget);

      // Clica em Publicar
      await tester.tap(find.text('Salvar no Acervo Privado'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(publishedPost, isNotNull);
      expect(publishedPost!.isPublic, isFalse);
    });
  });

  group('CommunityFeedScreen Integration Tests (RF14 / RF15)', () {
    testWidgets('renders feed title, filter chips, and filters posts by biotype',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

>>>>>>> feat/social-feed-rf14-rf15
      await tester.pumpWidget(
        const MaterialApp(
          home: CommunityFeedScreen(),
        ),
      );

<<<<<<< HEAD
      expect(find.text('Editorial Gallery'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Meu Biótipo'), findsOneWidget);

      // Tap filter chip
      await tester.tap(find.text('Meu Biótipo'));
      await tester.pump(const Duration(milliseconds: 300));
=======
      // Header Editorial
      expect(find.text('HarmonIA'), findsOneWidget);
      expect(find.text('FEED COMUNITÁRIO • EDITORIAL GALLERY'), findsOneWidget);

      // Chips de Filtro
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Ampulheta'), findsOneWidget);
      expect(find.text('Retângulo'), findsOneWidget);

      // Filtra por 'Retângulo'
      await tester.tap(find.text('Retângulo'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Geometrias Naturais & Textura Botânica'), findsOneWidget);
      expect(find.text('Sobreposições Terracota em Linho Cru'), findsNothing);
>>>>>>> feat/social-feed-rf14-rf15
    });
  });
}
