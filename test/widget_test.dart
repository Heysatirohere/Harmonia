import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/domain/models/community_post.dart';
import 'package:harmonia_mvp/main.dart';
import 'package:harmonia_mvp/presentation/feed/widgets/community_feed_card.dart';

void main() {
  testWidgets('HarmonIA smoke test renders main app navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const HarmoniaApp());

    // Verifica se a tela inicial de Sugestão Diária é renderizada
    expect(find.text('Sugestão Diária'), findsOneWidget);
  });

  testWidgets('CommunityFeedCard renders editorial metadata and IHE badge', (WidgetTester tester) async {
    const post = CommunityPost(
      id: 'test-1',
      author: PostAuthor(
        id: 'a-1',
        name: 'Curadora Teste',
        handle: '@curadora',
        avatarUrl: '',
        styleArchetype: 'Minimalismo Quente',
      ),
      title: 'Look Editorial Alfaiataria',
      editorialDescription: 'Composição de linho cru com caimento fluido.',
      imageUrl: '',
      publishedAtAgo: 'há 1h',
      appreciationCount: 10,
      savesCount: 5,
      ihe: IheBreakdown(
        overallScore: 85,
        sColor: 0.9,
        sBio: 0.85,
        sOcasion: 0.8,
        sCos: 0.85,
        dominantColor: Color(0xFFA34836),
        paletteColors: [Color(0xFFA34836), Color(0xFFD9CDBF)],
        occasionContext: 'Café Cultural',
      ),
      garments: [
        GarmentHotspot(
          id: 'g-1',
          name: 'Camisa Linho',
          brandOrProvenance: 'Vintage',
          category: 'Superior',
          position: Offset(0.5, 0.5),
          dominantColor: Color(0xFFA34836),
          isConsciousFashion: true,
          consciousNote: '100% Linho Reciclado',
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CommunityFeedCard(post: post),
          ),
        ),
      ),
    );

    expect(find.text('Curadora Teste'), findsOneWidget);
    expect(find.text('Look Editorial Alfaiataria'), findsOneWidget);
    expect(find.text('LOOK FORTEMENTE RECOMENDADO'), findsOneWidget);
  });
}
