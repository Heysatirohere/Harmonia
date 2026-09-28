import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../mocks/mock_outfits.dart';
import '../../models/outfit_combination.dart';

/// Serviço de integração com o motor inteligente de looks e IHE da API FastAPI (RF07, RF13)
class OutfitApiService {
  final ApiClient _client;

  OutfitApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Solicita geração automática de looks a partir do acervo do usuário (RF07)
  Future<List<OutfitCombination>> generateDailyOutfits({
    String occasion = 'CASUAL',
    double temperatureCelsius = 22.0,
    bool isRaining = false,
    int limit = 5,
  }) async {
    try {
      final response = await _client.post(
        '/outfits/generate-daily',
        body: {
          'occasion': occasion,
          'temperature_celsius': temperatureCelsius,
          'is_raining': isRaining,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        if (list.isNotEmpty) {
          return list
              .map((item) => OutfitCombination.fromApiResponse(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[OutfitApiService] Falha ao comunicar com motor de looks da API ($e). Utilizando look curatorial mock.');
    }

    // Fallback gracioso com a curadoria de alta costura local
    return List.from(mockOutfits);
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
