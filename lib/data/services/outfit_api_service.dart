import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/network/api_client.dart';
import '../../domain/models/recommended_look.dart';

/// Falha ao gerar looks, com mensagem pronta para o usuário
class OutfitException implements Exception {
  final String message;

  /// Cota diária do plano gratuito esgotada (RN02): tentar de novo não adianta hoje
  final bool isQuotaExceeded;

  const OutfitException(this.message, {this.isQuotaExceeded = false});

  @override
  String toString() => message;
}

/// Serviço de integração com o motor inteligente de looks e IHE da API FastAPI (RF07, RF13)
class OutfitApiService {
  final ApiClient _client;

  OutfitApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Gera looks a partir do acervo do usuário (RF07). Lista vazia: o acervo ainda não forma um look.
  /// Repetir a mesma consulta no mesmo dia não gasta a cota (RN02).
  Future<List<RecommendedLook>> generateDailyOutfits({
    String occasion = 'CASUAL',
    double temperatureCelsius = 22.0,
    bool isRaining = false,
    int limit = 5,
  }) async {
    final http.Response response;
    try {
      response = await _client.post(
        '/outfits/generate-daily',
        body: {
          'occasion': occasion,
          'temperature_celsius': temperatureCelsius,
          'is_raining': isRaining,
          'limit': limit,
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

  /// Calcula o IHE pontual para um conjunto arbitrário de peças ou atributos
  Future<Map<String, dynamic>?> calculateIhe(Map<String, dynamic> payload) async {
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
