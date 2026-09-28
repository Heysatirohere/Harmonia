import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../mocks/mock_clothes.dart';
import '../../models/clothing_item.dart';

/// Serviço de integração com o módulo de Acervo Virtual (Wardrobe) da API FastAPI (RF06, RN01, RN02)
class WardrobeApiService {
  final ApiClient _client;

  WardrobeApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Busca peças do guarda-roupa via API com fallback gracioso para mock local caso offline
  Future<List<ClothingItem>> getClothingItems({
    String? category,
    double? minFormality,
    double? maxFormality,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null && category.isNotEmpty && category != 'Todos') {
        queryParams['category'] = category;
      }
      if (minFormality != null) {
        queryParams['min_formality'] = minFormality.toString();
      }
      if (maxFormality != null) {
        queryParams['max_formality'] = maxFormality.toString();
      }

      final response = await _client.get('/wardrobe/items', queryParams: queryParams.isNotEmpty ? queryParams : null);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        if (list.isNotEmpty) {
          return list.map((item) => ClothingItem.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('[WardrobeApiService] Falha de conexão com backend API ($e). Utilizando fallback local editorial.');
    }

    // Fallback gracioso com curadoria mock local
    if (category != null && category.isNotEmpty && category != 'Todos') {
      return mockClothes.where((i) => i.category == category).toList();
    }
    return List.from(mockClothes);
  }

  /// Cadastra nova peça de vestuário no backend
  Future<ClothingItem?> createClothingItem(ClothingItem item) async {
    try {
      final response = await _client.post(
        '/wardrobe/items',
        body: item.toApiJson(),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ClothingItem.fromJson(data as Map<String, dynamic>);
      } else {
        debugPrint('[WardrobeApiService] Erro ao cadastrar peça: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('[WardrobeApiService] Falha de rede ao cadastrar peça: $e');
    }
    return null;
  }

  /// Exclui peça do acervo no backend
  Future<bool> deleteClothingItem(String itemId) async {
    try {
      final response = await _client.delete('/wardrobe/items/$itemId');
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('[WardrobeApiService] Falha ao deletar peça: $e');
      return false;
    }
  }
}
