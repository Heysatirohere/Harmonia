import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/data/services/community_api_service.dart';
import 'package:harmonia_mvp/data/services/outfit_api_service.dart';
import 'package:harmonia_mvp/data/services/style_profile_api_service.dart';
import 'package:harmonia_mvp/data/services/wardrobe_api_service.dart';
import 'package:harmonia_mvp/domain/repositories/style_profile_repository.dart';
import 'package:harmonia_mvp/models/clothing_item.dart';
import 'package:harmonia_mvp/models/garment_segmentation.dart';
import 'package:harmonia_mvp/models/user_style_profile.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Camada HTTP dos serviços contra respostas no formato da API, sem servidor:
/// o cliente padrão do pacote http é trocado por um MockClient só dentro de [body].
Future<T> withApi<T>(Future<T> Function() body, http.Response Function(http.Request request) respond,
    {List<http.BaseRequest>? log}) {
  return http.runWithClient(body, () => MockClient((request) async {
        log?.add(request);
        return respond(request);
      }));
}

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

Map<String, dynamic> itemJson({String id = 'i1', String category = 'Partes de cima'}) => {
      'id': id,
      'user_id': 'u1',
      'category': category,
      'subcategory': 'Camisa de linho',
      'image_url': 'https://cdn.example/$id.png',
      'dominant_l': 60.0,
      'dominant_a': 15.0,
      'dominant_b': 18.0,
      'formality_score': 0.6,
      'cut_type': null,
      'is_archived': false,
      'created_at': '2026-10-01T12:00:00Z',
      'color_family': 'Bege e areia',
      'usage_rate': 3,
      'days_idle': 12,
    };

Map<String, dynamic> lookJson() => {
      'items': [itemJson(), itemJson(id: 'i2', category: 'Partes de baixo')],
      'ihe_percentage': 81.4,
      's_cor': 0.9,
      's_bio': 1.0,
      's_ocasion': 0.8,
      's_cos': 0.5,
      'is_strongly_recommended': true,
      'styling_advice': '✦ Look Fortemente Recomendado',
      'occasion': 'CASUAL',
    };

void main() {
  group('WardrobeApiService', () {
    test('lista as peças com família de cor e uso para os filtros (RF06)', () async {
      final log = <http.BaseRequest>[];
      final items = await withApi(
        () => WardrobeApiService().getClothingItems(category: 'Partes de cima'),
        (_) => json([itemJson()]),
        log: log,
      );

      expect(log.single.url.path, endsWith('/wardrobe/items'));
      expect(log.single.url.queryParameters['category'], 'Partes de cima');
      final item = items.single;
      expect((item.name, item.colorFamily, item.usageRate, item.daysIdle), ('Camisa de linho', 'Bege e areia', 3, 12));
    });

    test('lê a saúde do acervo e explica a falha', () async {
      final analytics = await withApi(
        () => WardrobeApiService().getAnalytics(),
        (_) => json({
          'total_pieces': 2,
          'active_count': 1,
          'idle_30_count': 0,
          'idle_60_count': 0,
          'dormant_count': 1,
          'never_worn_count': 1,
          'total_wears': 3,
          'color_distribution': [],
          'dormant_items': [],
        }),
      );
      expect((analytics.totalPieces, analytics.idle90DaysCount, analytics.totalWears), (2, 1, 3));

      await expectLater(
        withApi(() => WardrobeApiService().getAnalytics(), (_) => json({'detail': 'erro'}, 500)),
        throwsA(isA<WardrobeException>()),
      );
    });

    test('cadastra pela API e, se ela falhar, não insere uma cópia direto no banco', () async {
      final item = ClothingItem.fromJson(itemJson());
      final log = <http.BaseRequest>[];

      final saved = await withApi(() => WardrobeApiService().createClothingItem(item), (_) => json(itemJson(), 201), log: log);
      expect(saved!.id, 'i1');
      expect(jsonDecode((log.single as http.Request).body)['category'], 'Partes de cima');

      final failed = await withApi(() => WardrobeApiService().createClothingItem(item), (_) => json({}, 500));
      expect(failed, isNull);
    });

    test('apaga e edita a peça', () async {
      final log = <http.BaseRequest>[];
      final deleted = await withApi(() => WardrobeApiService().deleteClothingItem('i1'), (_) => http.Response('', 204), log: log);
      expect(deleted, isTrue);
      expect(log.single.method, 'DELETE');
      expect(log.single.url.path, endsWith('/wardrobe/items/i1'));

      final updated = await withApi(
        () => WardrobeApiService().updateClothingItem(ClothingItem.fromJson(itemJson()).copyWith(formalityScore: 0.8)),
        (request) {
          expect(jsonDecode(request.body)['formality_score'], 0.8);
          return json({...itemJson(), 'formality_score': 0.8});
        },
      );
      expect(updated!.formalityScore, 0.8);
    });

    test('segmenta a foto e traz a sugestão da IA; recusa explica o motivo (RF04, RF05)', () async {
      final png = Uint8List.fromList([137, 80, 78, 71]);
      final result = await withApi(
        () => WardrobeApiService().segmentGarment(imageBytes: png, fileName: 'peca.png'),
        (_) => json({
          'image_png_base64': base64Encode(png),
          'width': 1,
          'height': 1,
          'colors': [],
          'processing_ms': 900,
          'suggestion': {'category': 'Calçados', 'name': 'Tênis', 'pattern': 'solid', 'formality': 0.15, 'confidence': 0.98},
        }),
      );
      expect(result.suggestion!.name, 'Tênis');

      await expectLater(
        withApi(
          () => WardrobeApiService().segmentGarment(imageBytes: png, fileName: 'peca.png'),
          (_) => json({'detail': 'Nenhuma peça foi identificada na foto.'}, 422),
        ),
        throwsA(isA<SegmentationException>().having((e) => e.message, 'message', 'Nenhuma peça foi identificada na foto.')),
      );
    });
  });

  group('OutfitApiService', () {
    test('gera looks com o clima e a ocasião pedidos (RF07, RF16)', () async {
      final log = <http.BaseRequest>[];
      final looks = await withApi(
        () => OutfitApiService().generateDailyOutfits(occasion: 'TRABALHO', temperatureCelsius: 14, isRaining: true),
        (_) => json([lookJson()]),
        log: log,
      );

      final body = jsonDecode((log.single as http.Request).body);
      expect((body['occasion'], body['temperature_celsius'], body['is_raining']), ('TRABALHO', 14.0, true));
      expect((looks.single.ihePercentage, looks.single.isStronglyRecommended, looks.single.items.length), (81, true, 2));
    });

    test('cota esgotada e sessão expirada viram mensagens próprias (RN02)', () async {
      await expectLater(
        withApi(() => OutfitApiService().generateDailyOutfits(), (_) => json({}, 403)),
        throwsA(isA<OutfitException>().having((e) => e.isQuotaExceeded, 'isQuotaExceeded', isTrue)),
      );
      await expectLater(
        withApi(() => OutfitApiService().generateDailyOutfits(), (_) => json({}, 401)),
        throwsA(isA<OutfitException>().having((e) => e.message, 'message', contains('Sessão expirada'))),
      );
    });

    test('registra e desfaz o feedback de um look (RF13)', () async {
      final look = (await withApi(() => OutfitApiService().generateDailyOutfits(), (_) => json([lookJson()]))).single;
      final log = <http.BaseRequest>[];

      final id = await withApi(
        () => OutfitApiService().sendLookFeedback(look, LookFeedbackAction.approved),
        (_) => json({'id': 'fb-1'}, 201),
        log: log,
      );
      expect(id, 'fb-1');
      expect(jsonDecode((log.single as http.Request).body)['action'], 'APPROVED');

      await withApi(() => OutfitApiService().undoLookFeedback('fb-1'), (_) => http.Response('', 204));
      await expectLater(
        withApi(() => OutfitApiService().undoLookFeedback('fb-1'), (_) => http.Response('', 404)),
        throwsA(isA<OutfitException>()),
      );
    });

    test('lê as lacunas da ocasião pedida (RF11, RF12)', () async {
      final log = <http.BaseRequest>[];
      final report = await withApi(
        () => OutfitApiService().getWardrobeGaps(occasion: 'NOITE'),
        (_) => json({'occasion': 'NOITE', 'baseline_ihe_percentage': null, 'gaps': []}),
        log: log,
      );

      expect(log.single.url.queryParameters['occasion'], 'NOITE');
      expect(report.occasion, 'NOITE');
      expect(report.baselineIhe, isNull);
      expect(report.gaps, isEmpty);
    });

    test('compara a peça da loja com o acervo (RF08, RF09)', () async {
      final storeGarment = ClothingItem.fromJson(itemJson(id: 'loja'));
      final result = await withApi(
        () => OutfitApiService().analyzeStoreParity(storeGarment: storeGarment),
        (_) => json({
          'ihe_percentage': 77.0,
          'is_strongly_recommended': true,
          'palette_harmony': 0.8,
          'styling_advice': null,
          'looks_evaluated': 1,
          'strong_looks': 1,
          'matches': [],
        }),
      );

      expect((result.ihePercentage, result.strongLooks, result.storeGarment.id), (77, 1, 'loja'));
    });
  });

  group('StyleProfileApiService', () {
    final profileJson = {
      'body_shape': 'OVAL',
      'seasonal_palette': 'VERAO_SUAVE',
      'is_premium': false,
      'is_public': true,
      'items_count': 4,
      'max_items_allowed': 30,
      'looks_generated_today': 1,
      'max_daily_looks': 5,
    };

    test('lê e atualiza só os campos pedidos (RF02, RF18)', () async {
      final profile = await withApi(() => StyleProfileApiService().fetch(), (_) => json(profileJson));
      expect((profile.silhouette, profile.palette), (BodySilhouetteType.oval, SeasonalPaletteType.veraoSuave));

      final log = <http.BaseRequest>[];
      await withApi(
        () => StyleProfileApiService().update(palette: SeasonalPaletteType.invernoFrio),
        (_) => json({...profileJson, 'seasonal_palette': 'INVERNO_FRIO'}),
        log: log,
      );
      expect(jsonDecode((log.single as http.Request).body), {'seasonal_palette': 'INVERNO_FRIO'});
    });

    test('a selfie volta com a cartela sugerida, ou com o motivo da recusa (RF02)', () async {
      final selfie = Uint8List.fromList([255, 216, 255]);
      final result = await withApi(
        () => StyleProfileApiService().analyzeSelfie(selfie, 'selfie.jpg'),
        (_) => json({
          'palette': 'PRIMAVERA_QUENTE',
          'skin_hex': '#F2CCAA',
          'L': 84.5, 'a': 8.5, 'b': 21.9, 'hue': 68.8, 'chroma': 23.5, 'contrast': 41.2,
          'undertone': 'QUENTE',
          'depth': 'CLARA',
          'intensity': 'BRILHANTE',
        }),
      );
      expect((result.palette, result.skinColor), (SeasonalPaletteType.primaveraQuente, const Color(0xFFF2CCAA)));

      await expectLater(
        withApi(
          () => StyleProfileApiService().analyzeSelfie(selfie, 'selfie.jpg'),
          (_) => json({'detail': 'Enquadre o rosto no oval.'}, 422),
        ),
        throwsA(isA<StyleProfileFailure>().having((e) => e.message, 'message', 'Enquadre o rosto no oval.')),
      );
    });
  });

  group('CommunityApiService', () {
    test('lê o feed com filtro, busca e paginação (RF14, RF15)', () async {
      final log = <http.BaseRequest>[];
      final page = await withApi(
        () => CommunityApiService().fetchFeed(filter: FeedFilter.palette, query: ' linho '),
        (_) => json({'posts': [], 'next_before': '2026-10-10T12:00:00Z'}),
        log: log,
      );

      expect(log.single.url.queryParameters, {'filter': 'palette', 'q': 'linho'});
      expect(page.posts, isEmpty);
      expect(page.nextBefore, DateTime.utc(2026, 10, 10, 12));
    });

    test('curtir, salvar e apagar tratam publicação removida (RN05)', () async {
      final log = <http.BaseRequest>[];
      await withApi(() => CommunityApiService().setLiked('p1', true), (_) => http.Response('', 204), log: log);
      await withApi(() => CommunityApiService().setSaved('p1', false), (_) => http.Response('', 204), log: log);
      expect([for (final r in log) r.method], ['PUT', 'DELETE']);

      await expectLater(
        withApi(() => CommunityApiService().delete('p1'), (_) => http.Response('', 404)),
        throwsA(isA<CommunityException>().having((e) => e.message, 'message', contains('não está mais disponível'))),
      );
    });
  });
}
