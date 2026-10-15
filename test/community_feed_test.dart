import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/data/services/community_api_service.dart';
import 'package:harmonia_mvp/models/community_post.dart';
import 'package:harmonia_mvp/models/user_style_profile.dart';
import 'package:harmonia_mvp/presentation/screens/community_feed_screen.dart';
import 'package:harmonia_mvp/presentation/widgets/filter_chips_bar.dart';
import 'package:harmonia_mvp/presentation/widgets/share_outfit_sheet.dart';

import 'support/fake_community_service.dart';

Map<String, dynamic> postJson({List<Map<String, dynamic>> pieces = const []}) => {
      'id': 'p1',
      'author_name': 'Ana Souza',
      'author_body_shape': 'AMPULHETA',
      'author_palette': null,
      'image_url': 'https://x.supabase.co/storage/v1/object/public/wardrobe-items/u/look.jpg',
      'caption': 'Linho cru',
      'occasion': 'TRABALHO',
      'style_tags': ['Minimal'],
      'ihe_percentage': 88.5,
      'pieces': pieces,
      'like_count': 2,
      'liked_by_me': true,
      'saved_by_me': false,
      'is_public': true,
      'is_mine': false,
      'created_at': '2026-10-05T12:00:00Z',
    };

Future<FakeCommunityService> pumpFeed(WidgetTester tester, FakeCommunityService service) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: CommunityFeedScreen(
      service: service,
      capturePhoto: (source) async => (bytes: samplePhotoBytes, name: 'look.jpg'),
    ),
  ));
  await tester.pumpAndSettle();
  return service;
}

/// A barra de chips é uma lista horizontal preguiçosa: rola até o chip antes de tocar
Future<void> tapChip(WidgetTester tester, String label) async {
  final chip = find.descendant(of: find.byType(FilterChipsBar), matching: find.text(label));
  await tester.scrollUntilVisible(
    chip,
    120,
    scrollable: find.descendant(of: find.byType(FilterChipsBar), matching: find.byType(Scrollable)),
  );
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

/// O rótulo do botão de curtir vem junto com a contagem
final likeButton = find.bySemanticsLabel(RegExp(r'^Curtir'));

FakeCommunityService feedWith(List<CommunityPost> posts) =>
    FakeCommunityService({(FeedFilter.all, null, ''): posts});

void main() {
  group('CommunityPost.fromJson (RF14)', () {
    test('lê autor, IHE, peças e interações da API', () {
      final post = CommunityPost.fromJson(postJson(pieces: [
        {
          'id': 'i1', 'category': 'top', 'subcategory': 'Camisa de linho', 'image_url': '',
          'dominant_l': 60.0, 'dominant_a': 10.0, 'dominant_b': 15.0,
        },
      ]));

      expect(post.authorBodyShape, BodySilhouetteType.ampulheta);
      expect(post.authorPalette, isNull);
      expect(post.authorTraits, 'Ampulheta');
      expect(post.occasionLabel, 'Trabalho');
      expect(post.isStronglyRecommended, isTrue);
      expect(post.pieces.single.name, 'Camisa de linho');
      expect(post.pieces.single.labLabel, contains('L*'));
      expect((post.likeCount, post.likedByMe), (2, true));
    });

    test('post sem look aprovado não tem selo', () {
      final post = CommunityPost.fromJson({...postJson(), 'ihe_percentage': null});
      expect(post.isStronglyRecommended, isFalse);
    });
  });

  group('CommunityFeedScreen', () {
    testWidgets('mostra os posts da API com legenda, ocasião e tags', (tester) async {
      await pumpFeed(tester, feedWith([samplePost(ihe: 88)]));

      expect(find.text('Editorial'), findsOneWidget);
      expect(find.text('Linho cru para o escritório'), findsOneWidget);
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('Trabalho'), findsWidgets);
      expect(find.text('#Minimal'), findsOneWidget);
      expect(find.text('✦ 88%'), findsOneWidget);
    });

    testWidgets('cada chip pede o recorte certo à API (RF15)', (tester) async {
      final service = await pumpFeed(tester, feedWith([]));

      for (final label in ['Meu biótipo', 'Festa', 'Salvos', 'Meus looks']) {
        await tapChip(tester, label);
      }

      expect(
        service.fetches.map((f) => (f.filter, f.occasion)).toList(),
        [
          (FeedFilter.all, null),
          (FeedFilter.bodyShape, null),
          (FeedFilter.all, 'FESTA'),
          (FeedFilter.saved, null),
          (FeedFilter.mine, null),
        ],
      );
      expect(find.text('Você ainda não publicou'), findsOneWidget);
    });

    testWidgets('a busca envia o texto digitado', (tester) async {
      final service = FakeCommunityService({
        (FeedFilter.all, null, ''): [samplePost()],
        (FeedFilter.all, null, 'linho'): [samplePost(id: 'p2', caption: 'Só linho')],
      });
      await pumpFeed(tester, service);

      await tester.enterText(find.byType(TextField), 'linho');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(service.fetches.last.query, 'linho');
      expect(find.text('Só linho'), findsOneWidget);
      expect(find.text('Linho cru para o escritório'), findsNothing);
    });

    testWidgets('curtir muda na hora e avisa a API', (tester) async {
      final service = await pumpFeed(tester, feedWith([samplePost(likeCount: 3)]));

      await tester.tap(likeButton);
      await tester.pumpAndSettle();

      expect(service.likes, [('p1', true)]);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('falha ao curtir desfaz a mudança e avisa', (tester) async {
      final service = await pumpFeed(tester, feedWith([samplePost(likeCount: 3)]));
      service.failure = const CommunityException('Não foi possível atualizar agora.');

      await tester.tap(likeButton);
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Não foi possível atualizar agora.'), findsOneWidget);
    });

    testWidgets('tirar dos salvos no recorte "Salvos" tira o post da lista', (tester) async {
      final service = FakeCommunityService({
        (FeedFilter.all, null, ''): [],
        (FeedFilter.saved, null, ''): [samplePost(savedByMe: true)],
      });
      await pumpFeed(tester, service);
      await tapChip(tester, 'Salvos');

      await tester.tap(find.bySemanticsLabel('Remover do moodboard'));
      await tester.pumpAndSettle();

      expect(service.saves, [('p1', false)]);
      expect(find.text('Seu moodboard está vazio'), findsOneWidget);
    });

    testWidgets('só os próprios posts podem ser apagados, com confirmação', (tester) async {
      final service = await pumpFeed(tester, feedWith([samplePost(id: 'meu', isMine: true), samplePost(id: 'dela')]));

      expect(find.bySemanticsLabel('Apagar publicação'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Apagar publicação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar'));
      await tester.pumpAndSettle();

      expect(service.deleted, ['meu']);
      expect(find.text('Publicação apagada.'), findsOneWidget);
    });

    testWidgets('API fora do ar mostra o erro e tenta de novo', (tester) async {
      final service = feedWith([samplePost()])..failure = const CommunityException('Sem conexão.');
      await pumpFeed(tester, service);

      expect(find.text('O ateliê não respondeu'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(find.text('Linho cru para o escritório'), findsOneWidget);
    });

    testWidgets('rolar até o fim carrega a próxima página', (tester) async {
      final first = [for (var i = 0; i < 4; i++) samplePost(id: 'p$i', caption: 'look $i')];
      final service = FakeCommunityService(
        {(FeedFilter.all, null, ''): first},
        nextPage: [samplePost(id: 'old', caption: 'look antigo')],
        firstPageNextBefore: DateTime.utc(2026, 10, 1),
      );
      await pumpFeed(tester, service);

      await tester.scrollUntilVisible(find.text('look antigo'), 600, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(service.fetches.last.before, DateTime.utc(2026, 10, 1));
      expect(find.text('look antigo'), findsOneWidget);
    });

    testWidgets('as peças do look aprovado abrem numa folha', (tester) async {
      final piece = PostPiece.fromJson({
        'id': 'i1', 'category': 'top', 'subcategory': 'Camisa de linho', 'image_url': '',
        'dominant_l': 60.0, 'dominant_a': 10.0, 'dominant_b': 15.0,
      });
      await pumpFeed(tester, feedWith([samplePost(pieces: [piece])]));

      await tester.tap(find.bySemanticsLabel('Ver 1 peça do acervo'));
      await tester.pumpAndSettle();

      expect(find.text('COMPOSIÇÃO DO LOOK'), findsOneWidget);
      expect(find.text('Camisa de linho'), findsOneWidget);
    });
  });

  group('ShareOutfitSheet (RF14)', () {
    Future<void> openSheet(WidgetTester tester, FakeCommunityService service) async {
      await pumpFeed(tester, service);
      await tester.tap(find.bySemanticsLabel('Compartilhar look'));
      await tester.pumpAndSettle();
    }

    testWidgets('publica foto, legenda, ocasião e tags e põe o post no topo', (tester) async {
      final service = feedWith([samplePost()]);
      await openSheet(tester, service);

      await tester.tap(find.text('GALERIA'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'Minha alfaiataria');
      await tester.tap(find.descendant(of: find.byType(ShareOutfitSheet), matching: find.text('Festa')));
      await tester.enterText(find.byType(TextField).at(2), 'Minimal, Linho ,');
      await tester.ensureVisible(find.text('PUBLICAR LOOK'));
      await tester.tap(find.text('PUBLICAR LOOK'));
      await tester.pumpAndSettle();

      final sent = service.published.single;
      expect(sent.caption, 'Minha alfaiataria');
      expect(sent.occasion, 'FESTA');
      expect(sent.styleTags, ['Minimal', 'Linho']);
      expect(sent.feedbackId, isNull);
      expect(sent.isPublic, isTrue);
      expect(find.text('Look publicado na comunidade.'), findsOneWidget);
      expect(find.text('Minha alfaiataria'), findsOneWidget);
    });

    testWidgets('sem foto não publica e explica', (tester) async {
      final service = feedWith([]);
      await openSheet(tester, service);

      await tester.enterText(find.byType(TextField).at(1), 'Legenda');
      await tester.ensureVisible(find.text('PUBLICAR LOOK'));
      await tester.tap(find.text('PUBLICAR LOOK'));
      await tester.pumpAndSettle();

      expect(service.published, isEmpty);
      expect(find.text('Escolha a foto do look.'), findsOneWidget);
    });

    testWidgets('falha ao publicar mantém a folha aberta com o erro', (tester) async {
      final service = feedWith([]);
      await openSheet(tester, service);
      service.failure = const CommunityException('Não foi possível enviar a foto. Tente novamente.');

      await tester.tap(find.text('CÂMERA'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'Legenda');
      await tester.ensureVisible(find.text('PUBLICAR LOOK'));
      await tester.tap(find.text('PUBLICAR LOOK'));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível enviar a foto. Tente novamente.'), findsOneWidget);
      expect(find.text('PUBLICAR LOOK'), findsOneWidget);
    });
  });
}
