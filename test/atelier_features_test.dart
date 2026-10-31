import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/data/services/community_api_service.dart';
import 'package:harmonia_mvp/models/clothing_item.dart';
import 'package:harmonia_mvp/models/community_post.dart';
import 'package:harmonia_mvp/models/garment_segmentation.dart';
import 'package:harmonia_mvp/models/user_style_profile.dart';
import 'package:harmonia_mvp/models/wardrobe_analytics.dart';
import 'package:harmonia_mvp/models/wardrobe_filters.dart';
import 'package:harmonia_mvp/presentation/atelier/atelier_sheet.dart';
import 'package:harmonia_mvp/presentation/screens/community_feed_screen.dart';
import 'package:harmonia_mvp/presentation/screens/onboarding_profile_screen.dart';
import 'package:harmonia_mvp/presentation/screens/store_mirror_screen.dart';
import 'package:harmonia_mvp/presentation/screens/wardrobe_analytics_screen.dart';
import 'package:harmonia_mvp/presentation/widgets/ihe_score_gauge.dart';

import 'support/fake_community_service.dart';
import 'support/fake_outfit_service.dart';
import 'support/fake_wardrobe_service.dart';

final _pixel = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

void main() {
  group('AGENTS.md 7.2 — AtelierIheGauge & GoldSeal', () {
    testWidgets('exibe pontuação 56pt, 4 pilares (S_cor, S_bio, S_ocasion, S_cos) e GoldSeal >= 75%', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AtelierIheGauge(
            ihePercentage: 92,
            sCor: 0.95,
            sBio: 0.90,
            sOcasion: 0.88,
            sCos: 0.94,
            dominantColor: Color(0xFF3B1829),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('92%', findRichText: true), findsOneWidget);
      expect(find.byType(GoldSeal), findsOneWidget);
      expect(find.textContaining('LOOK FORTEMENTE RECOMENDADO'), findsOneWidget);
      expect(find.textContaining('S_cor • 95%'), findsOneWidget);
      expect(find.textContaining('S_bio • 90%'), findsOneWidget);
      expect(find.textContaining('S_ocasion • 88%'), findsOneWidget);
      expect(find.textContaining('S_cos • 94%'), findsOneWidget);
    });

    testWidgets('pontuação abaixo de 75% omite GoldSeal', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AtelierIheGauge(
            ihePercentage: 68,
            sCor: 0.70,
            sBio: 0.65,
            sOcasion: 0.70,
            sCos: 0.68,
            dominantColor: Color(0xFF3B1829),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('68%', findRichText: true), findsOneWidget);
      expect(find.byType(GoldSeal), findsNothing);
    });
  });

  group('12 Cartelas Sazonais Distintas (RF02)', () {
    test('cada uma das 12 estações possui 6 swatches únicos sem duplicatas entre sub-estações', () {
      final seenPalettes = <String>{};
      for (final palette in SeasonalPaletteType.values) {
        final swatches = palette.colorSwatches;
        expect(swatches, hasLength(6), reason: '${palette.name} deve ter 6 cores');
        final signature = swatches.map((c) => c.toARGB32().toRadixString(16)).join(',');
        expect(
          seenPalettes.add(signature),
          isTrue,
          reason: '${palette.name} compartilha swatches idênticos com outra estação',
        );
      }
      expect(seenPalettes, hasLength(12));
    });
  });

  group('ClothingItem & WardrobeFilters — Sazonalidade, Cápsulas, CPU e ESG (RF05 / 3.2.2)', () {
    test('calcula custo por uso (CPU) e serializa metadados estendidos quando presentes', () {
      final item = ClothingItem.fromJson({
        'id': 'c1',
        'subcategory': 'Trench Coat Lã',
        'category': 'Peças únicas',
        'dominant_l': 35.0,
        'dominant_a': 5.0,
        'dominant_b': 12.0,
        'usage_rate': 4,
        'purchase_price': 600.0,
        'season': 'Inverno',
        'capsules': ['Trabalho', 'Viagem'],
        'disposal_status': 'DONATE',
        'pattern': 'Liso',
        'thermal_category': 'Pesado',
        'cut_type': 'Estruturado',
      });

      expect(item.costPerUse, 150.0);
      expect(item.formattedCostPerUse, 'R\$ 150,00/uso');
      expect(item.season, 'Inverno');
      expect(item.capsules, ['Trabalho', 'Viagem']);
      expect(item.disposalStatus, 'DONATE');

      final filters = WardrobeFilters.none.toggleSeason('Inverno').selectCapsule('Viagem');
      expect(filters.matches(item), isTrue);
      expect(filters.toggleSeason('Inverno').toggleSeason('Verão').matches(item), isFalse);
    });
  });

  group('WardrobeAnalyticsScreen — Patrimônio, CPU e Reativação em 1 Toque', () {
    testWidgets('exibe patrimônio e custo por uso quando fornecidos pela API', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final analytics = WardrobeAnalytics.fromJson({
        'total_pieces': 3,
        'active_count': 2,
        'idle_30_count': 0,
        'idle_60_count': 0,
        'dormant_count': 1,
        'never_worn_count': 0,
        'total_wears': 10,
        'total_wardrobe_value': 1500.0,
        'average_cost_per_use': 42.5,
        'color_distribution': [],
        'dormant_items': [
          {
            'item': {
              'id': 'd1',
              'category': 'Partes de cima',
              'subcategory': 'Camisa Seda',
              'image_url': '',
              'dominant_l': 80.0,
              'dominant_a': 2.0,
              'dominant_b': 5.0,
            },
            'wear_count': 2,
            'days_idle': 110,
            'cost_per_use': 120.0,
          },
        ],
      });

      await tester.pumpWidget(MaterialApp(
        home: WardrobeAnalyticsScreen(service: FakeWardrobeService(const [], analytics: analytics)),
      ));
      await tester.pumpAndSettle();

      expect(find.text('INTELIGÊNCIA PATRIMONIAL & CUSTO POR USO'), findsOneWidget);
      expect(find.text('R\$ 42,50'), findsOneWidget);
      expect(find.text('Reativar em Look', skipOffstage: false), findsOneWidget);
    });
  });

  group('AGENTS.md 7.3 — Mirror Mode AR Overlay em 1 Toque', () {
    testWidgets('tocar em Sobrepor no Espelho (AR) projeta a peça sobre o visor da câmera', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final segmentation = GarmentSegmentation(
        cutoutPng: _pixel,
        width: 1,
        height: 1,
        colors: const [GarmentColor(l: 45, a: 32, b: 25, hex: '#A34836', percentage: 80, name: 'Terracota')],
        processingMs: 500,
        styleEmbedding: List.filled(512, 0.044),
      );

      await tester.pumpWidget(MaterialApp(
        home: StoreMirrorScreen(
          wardrobeService: FakeWardrobeService(const [], segmentation: segmentation),
          outfitService: FakeOutfitService(const []),
          capturePhoto: (_) async => (bytes: _pixel, name: 'mirror.jpg'),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shutter_button')));
      await tester.pumpAndSettle();

      expect(find.text('Sobrepor no Espelho (AR)'), findsWidgets);
      await tester.tap(find.text('Sobrepor no Espelho (AR)').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ar_mirror_overlay')), findsOneWidget);
      expect(find.text('SOBREPOSIÇÃO AR • ACERVO'), findsOneWidget);
    });
  });

  group('AGENTS.md 7.4 — Hotspots Editoriais e Controle de Visibilidade (RN05)', () {
    testWidgets('tocar no hotspot revela marca, tecido e L*a*b* em folha paperBone', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final piece = PostPiece.fromJson({
        'id': 'hp1',
        'category': 'Partes de cima',
        'subcategory': 'Blazer Alfaiataria',
        'image_url': '',
        'brand': 'Ateliê Milão',
        'fabric': 'Lã Fria 120s',
        'dominant_l': 25.0,
        'dominant_a': 2.0,
        'dominant_b': -12.0,
      });
      final service = FakeCommunityService({
        (FeedFilter.all, null, ''): [samplePost(id: 'p1', isMine: true, pieces: [piece])],
      });

      await tester.pumpWidget(MaterialApp(home: CommunityFeedScreen(service: service)));
      await tester.pumpAndSettle();

      // Alterna visibilidade (RN05)
      await tester.tap(find.text('PÚBLICO'));
      await tester.pumpAndSettle();
      expect(service.visibilityUpdates, [('p1', false)]);

      // Toca no hotspot circular gildedLeaf
      await tester.tap(find.byKey(const Key('hotspot_hp1')));
      await tester.pumpAndSettle();

      expect(find.text('COMPOSIÇÃO DO LOOK'), findsOneWidget);
      expect(find.textContaining('Ateliê Milão'), findsOneWidget);
      expect(find.textContaining('Lã Fria 120s'), findsOneWidget);
    });
  });

  group('Questionário Assistido de Biótipo no Onboarding (RF03)', () {
    testWidgets('responde 2 perguntas e seleciona automaticamente a silhueta recomendada', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      BodySilhouetteType? savedSilhouette;
      await tester.pumpWidget(MaterialApp(
        home: OnboardingProfileScreen(
          onCompleted: (silhouette, _) async {
            savedSilhouette = silhouette;
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Avança da etapa 0 para etapa 1
      await tester.tap(find.text('Iniciar Consultoria'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dúvida no biótipo? Questionário assistido em 2 toques'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quadril mais amplo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cintura marcada'));
      await tester.pumpAndSettle();

      // Avança até o resumo (etapa 3) e verifica a silhueta deduzida (Triângulo)
      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('TRIÂNGULO'), findsWidgets);
      await tester.tap(find.text('Entrar no HarmonIA'));
      await tester.pumpAndSettle();
      expect(savedSilhouette, BodySilhouetteType.triangulo);
    });
  });
}
