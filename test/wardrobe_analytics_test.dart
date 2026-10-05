import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/data/services/wardrobe_api_service.dart';
import 'package:harmonia_mvp/models/wardrobe_analytics.dart';
import 'package:harmonia_mvp/presentation/screens/wardrobe_analytics_screen.dart';

import 'support/fake_wardrobe_service.dart';

/// Resposta de GET /wardrobe/analytics no formato da API
Map<String, dynamic> analyticsJson({int total = 4, List<Map<String, dynamic>>? dormant}) => {
      'total_pieces': total,
      'active_count': total == 0 ? 0 : 2,
      'idle_30_count': total == 0 ? 0 : 1,
      'idle_60_count': 0,
      'dormant_count': total == 0 ? 0 : 1,
      'never_worn_count': 1,
      'total_wears': 7,
      'color_distribution': total == 0
          ? []
          : [
              {'family': 'Azuis', 'count': 3, 'percentage': 75.0, 'L': 32.0, 'a': 25.2, 'b': -58.2},
              {'family': 'Pretos e carvão', 'count': 1, 'percentage': 25.0, 'L': 2.7, 'a': 0.0, 'b': 0.0},
            ],
      'dormant_items': dormant ??
          (total == 0
              ? []
              : [
                  {
                    'item': {
                      'id': 'b1',
                      'user_id': 'u1',
                      'category': 'Partes de baixo',
                      'subcategory': 'Saia de linho',
                      'image_url': '',
                      'dominant_l': 30.0,
                      'dominant_a': 10.0,
                      'dominant_b': 20.0,
                      'formality_score': 0.5,
                      'is_archived': false,
                      'created_at': '2026-05-01T12:00:00Z',
                    },
                    'wear_count': 0,
                    'last_worn_at': null,
                    'days_idle': 157,
                  },
                ]),
    };

Future<FakeWardrobeService> pumpScreen(WidgetTester tester, {WardrobeAnalytics? analytics, WardrobeException? failure}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final service = FakeWardrobeService([], analytics: analytics, failure: failure);
  await tester.pumpWidget(MaterialApp(home: WardrobeAnalyticsScreen(service: service)));
  await tester.pump();
  return service;
}

void main() {
  group('WardrobeAnalytics.fromJson (Seção 3.2.2)', () {
    test('lê rotação, cores e peças adormecidas da API', () {
      final analytics = WardrobeAnalytics.fromJson(analyticsJson());

      expect(analytics.totalPieces, 4);
      expect(analytics.activePiecesCount, 2);
      expect(analytics.idle90DaysCount, 1);
      expect(analytics.activePercentage, 50.0);
      expect(analytics.totalWears, 7);
      expect(analytics.colorDistribution.map((c) => c.colorName), ['Azuis', 'Pretos e carvão']);
      expect(analytics.colorDistribution.first.labCoordinates, contains('L*'));
      final dormant = analytics.dormantItems.single;
      expect(dormant.item.name, 'Saia de linho');
      expect(dormant.idleLabel, 'Nunca usada · 157 dias no acervo');
    });

    test('peça já usada mostra há quanto tempo foi o último uso', () {
      final json = analyticsJson();
      (json['dormant_items'] as List).first['wear_count'] = 3;
      final analytics = WardrobeAnalytics.fromJson(json);

      expect(analytics.dormantItems.single.idleLabel, 'Último uso há 157 dias');
    });
  });

  group('WardrobeAnalyticsScreen', () {
    testWidgets('mostra as seções com os dados reais do acervo', (tester) async {
      await pumpScreen(tester, analytics: WardrobeAnalytics.fromJson(analyticsJson()));

      expect(find.text('Saúde do Acervo'), findsOneWidget);
      expect(find.text('DIRETRIZ ESG & CIRCULARIDADE'), findsOneWidget);
      expect(find.text('50% ATIVO'), findsOneWidget);
      expect(find.text('2 das 4 peças em circulação frequente'), findsOneWidget);

      expect(find.text('ROTAÇÃO DE ACERVO POR PERÍODO (3.2.2)'), findsOneWidget);
      expect(find.text('Em uso (<30d)'), findsOneWidget);
      expect(find.text('Dormindo (>90d)'), findsOneWidget);

      expect(find.text('PROPORÇÃO CROMÁTICA DOMINANTE (CIE LAB*)'), findsOneWidget);
      expect(find.text('Azuis'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('7 usos registrados'), findsOneWidget);

      expect(find.text('Saia de linho'), findsOneWidget);
      expect(find.text('Nunca usada · 157 dias no acervo'), findsOneWidget);
    });

    testWidgets('não mostra métricas sem base real (custo por uso)', (tester) async {
      await pumpScreen(tester, analytics: WardrobeAnalytics.fromJson(analyticsJson()));

      expect(find.textContaining('Custo'), findsNothing);
      expect(find.textContaining('R\$'), findsNothing);
    });

    testWidgets('sem peças adormecidas, diz que o armário está em rotação', (tester) async {
      await pumpScreen(tester, analytics: WardrobeAnalytics.fromJson(analyticsJson(dormant: [])));

      expect(find.textContaining('O armário inteiro está em rotação'), findsOneWidget);
    });

    testWidgets('acervo vazio convida a digitalizar', (tester) async {
      await pumpScreen(tester, analytics: WardrobeAnalytics.fromJson(analyticsJson(total: 0)));

      expect(find.text('Seu acervo ainda está vazio'), findsOneWidget);
      expect(find.text('ROTAÇÃO DE ACERVO POR PERÍODO (3.2.2)'), findsNothing);
    });

    testWidgets('API fora do ar mostra o erro e tenta de novo', (tester) async {
      await pumpScreen(
        tester,
        analytics: WardrobeAnalytics.fromJson(analyticsJson()),
        failure: const WardrobeException('Não foi possível ler a saúde do seu acervo agora.'),
      );

      expect(find.text('O ateliê não respondeu'), findsOneWidget);
      expect(find.text('Não foi possível ler a saúde do seu acervo agora.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(find.text('O ateliê não respondeu'), findsNothing);
      expect(find.text('50% ATIVO'), findsOneWidget);
    });
  });
}
