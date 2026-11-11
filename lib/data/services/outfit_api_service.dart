import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/demo/demo_mode.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/recommended_look.dart';
import '../../domain/repositories/outfit_repository.dart';
import '../../mocks/mock_atelier_store.dart';
import '../../models/clothing_item.dart';
import '../../models/store_parity_result.dart';
import '../../models/wardrobe_gap.dart';

/// Falha ao gerar looks, com mensagem pronta para o usuário
class OutfitException implements Exception {
  final String message;

  /// Cota diária do plano gratuito esgotada (RN02): tentar de novo não adianta hoje
  final bool isQuotaExceeded;

  const OutfitException(this.message, {this.isQuotaExceeded = false});

  @override
  String toString() => message;
}

/// Retorno do usuário sobre um look sugerido (RF13)
enum LookFeedbackAction {
  approved('APPROVED'),
  discarded('DISCARDED');

  const LookFeedbackAction(this.apiValue);
  final String apiValue;
}

/// Serviço de integração com o motor inteligente de looks e IHE da API FastAPI (RF07, RF13)
class OutfitApiService implements OutfitRepository {
  final ApiClient _client;

  OutfitApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Gera looks a partir do acervo do usuário (RF07). Lista vazia: o acervo ainda não forma um look.
  /// Repetir a mesma consulta no mesmo dia não gasta a cota (RN02).
  @override
  Future<List<RecommendedLook>> generateDailyOutfits({
    String occasion = 'CASUAL',
    double temperatureCelsius = 22.0,
    bool isRaining = false,
    int limit = 5,
    String? anchorItemId,
  }) async {
    if (kDemoMode) {
      return MockAtelierStore.instance.generateDailyOutfits(
        occasion: occasion,
        anchorItemId: anchorItemId,
      );
    }
    final http.Response response;
    try {
      response = await _client.post(
        '/outfits/generate-daily',
        body: {
          'occasion': occasion,
          'temperature_celsius': temperatureCelsius,
          'is_raining': isRaining,
          'limit': limit,
          if (anchorItemId != null && anchorItemId.isNotEmpty) 'anchor_item_id': anchorItemId,
        },
      );
    } catch (e) {
      debugPrint('[OutfitApiService] Motor de looks indisponível: $e');
      throw const OutfitException('Não foi possível conectar ao ateliê. Verifique sua conexão.');
    }

    switch (response.statusCode) {
      case 200:
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return [for (final look in list) RecommendedLook.fromJson(look as Map<String, dynamic>)];
      case 403:
        throw const OutfitException(
          'Você usou as combinações de hoje do plano gratuito. Novas sugestões amanhã.',
          isQuotaExceeded: true,
        );
      case 401:
        throw const OutfitException('Sessão expirada. Entre novamente.');
      default:
        throw const OutfitException('Não foi possível compor o look agora.');
    }
  }

  /// Registra a aprovação ou o descarte de um look (RF13). Retorna o id do registro, para desfazer.
  /// Um look descartado não volta a ser sugerido.
  @override
  Future<String> sendLookFeedback(RecommendedLook look, LookFeedbackAction action) async {
    if (kDemoMode) return MockAtelierStore.instance.recordLookFeedback(look, action);
    final http.Response response;
    try {
      response = await _client.post(
        '/outfits/feedback',
        body: {
          'item_ids': [for (final item in look.items) item.id],
          'action': action.apiValue,
          'occasion': look.occasion,
          'ihe_percentage': look.ihePercentage,
        },
      );
    } catch (e) {
      debugPrint('[OutfitApiService] Feedback não enviado: $e');
      throw const OutfitException('Não foi possível registrar agora. Verifique sua conexão.');
    }
    if (response.statusCode != 201) {
      throw const OutfitException('Não foi possível registrar agora.');
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['id'] as String;
  }

  /// Desfaz uma aprovação ou um descarte
  @override
  Future<void> undoLookFeedback(String feedbackId) async {
    if (kDemoMode) {
      MockAtelierStore.instance.undoLookFeedback(feedbackId);
      return;
    }
    final http.Response response;
    try {
      response = await _client.delete('/outfits/feedback/$feedbackId');
    } catch (e) {
      debugPrint('[OutfitApiService] Desfazer feedback falhou: $e');
      throw const OutfitException('Não foi possível desfazer agora. Verifique sua conexão.');
    }
    if (response.statusCode != 204) {
      throw const OutfitException('Não foi possível desfazer agora.');
    }
  }

  /// Compara uma peça fotografada na loja com o acervo (RF08, RF09). Não gasta a cota RN02.
  /// [storeGarment] precisa ter as coordenadas L*a*b* extraídas do recorte.
  @override
  Future<StoreParityResult> analyzeStoreParity({
    required ClothingItem storeGarment,
    String occasion = 'CASUAL',
  }) async {
    if (kDemoMode) return MockAtelierStore.instance.analyzeStoreParity(storeGarment);
    final (l, a, b) = storeGarment.labCoordinates;
    final http.Response response;
    try {
      response = await _client.post(
        '/outfits/store-parity',
        body: {
          'category': storeGarment.category,
          'dominant_l': l,
          'dominant_a': a,
          'dominant_b': b,
          'formality_score': storeGarment.formalityScore ?? 0.5,
          if (storeGarment.cutType != null && storeGarment.cutType!.isNotEmpty) 'cut_type': storeGarment.cutType,
          if (storeGarment.pattern != null && storeGarment.pattern!.isNotEmpty) 'pattern': storeGarment.pattern,
          if (storeGarment.thermalCategory != null && storeGarment.thermalCategory!.isNotEmpty)
            'thermal_category': storeGarment.thermalCategory,
          'occasion': occasion,
          // Com o vetor, a paridade também mede a proximidade com o estilo que o usuário aprova (S_cos)
          if (storeGarment.styleEmbedding != null) 'style_embedding': storeGarment.styleEmbedding,
        },
      );
    } catch (e) {
      debugPrint('[OutfitApiService] Paridade indisponível: $e');
      throw const OutfitException('Não foi possível conectar ao ateliê. Verifique sua conexão.');
    }

    switch (response.statusCode) {
      case 200:
        return StoreParityResult.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
          storeGarment: storeGarment,
        );
      case 401:
        throw const OutfitException('Sessão expirada. Entre novamente.');
      default:
        throw const OutfitException('Não foi possível comparar a peça agora.');
    }
  }

  /// Peças-chave que faltam no acervo e onde comprá-las nos parceiros (RF11, RF12).
  /// Produtos esgotados nunca vêm (RN03) e a consulta não gasta a cota (RN02).
  @override
  Future<WardrobeGapReport> getWardrobeGaps({String occasion = 'CASUAL'}) async {
    if (kDemoMode) return MockAtelierStore.instance.getWardrobeGaps(occasion: occasion);
    final http.Response response;
    try {
      response = await _client.get('/outfits/gaps', queryParams: {'occasion': occasion});
    } catch (e) {
      debugPrint('[OutfitApiService] Lacunas indisponíveis: $e');
      throw const OutfitException('Não foi possível conectar ao ateliê. Verifique sua conexão.');
    }

    switch (response.statusCode) {
      case 200:
        return WardrobeGapReport.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
      case 401:
        throw const OutfitException('Sessão expirada. Entre novamente.');
      default:
        throw const OutfitException('Não foi possível mapear as lacunas do acervo agora.');
    }
  }

  /// Calcula o IHE pontual para um conjunto arbitrário de peças ou atributos
  @override
  Future<Map<String, dynamic>?> calculateIhe(Map<String, dynamic> payload) async {
    if (kDemoMode) {
      return const {
        'ihe_score': 92.0,
        's_cor': 0.94,
        's_bio': 0.91,
        's_ocasion': 0.90,
        's_cos': 0.93,
      };
    }
    try {
      final response = await _client.post(
        '/outfits/calculate-ihe',
        body: payload,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[OutfitApiService] Falha no cálculo pontual do IHE: $e');
    }
    return null;
  }
}
