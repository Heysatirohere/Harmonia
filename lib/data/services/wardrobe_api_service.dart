import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/network/api_client.dart';
import '../../core/supabase/supabase_config.dart';
import '../../mocks/mock_clothes.dart';
import '../../models/clothing_item.dart';
import '../../models/garment_segmentation.dart';
import 'supabase_auth_service.dart';
import 'supabase_storage_service.dart';

/// Serviço de integração com o módulo de Acervo Virtual (Wardrobe) da API e Supabase (RF03, RF04, RF06, RN01, RN02)
class WardrobeApiService {
  final ApiClient _client;

  WardrobeApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Busca peças do guarda-roupa via API com fallback gracioso para mock local caso offline
  Future<List<ClothingItem>> getClothingItems({
    String? category,
    double? minFormality,
    double? maxFormality,
  }) async {
    // 1. Tentar via API FastAPI
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
      debugPrint('[WardrobeApiService] Falha de conexão com backend API ($e). Tentando Supabase Database...');
    }

    // 2. Tentar via Supabase Database diretamente
    try {
      final supabase = SupabaseConfig.client;
      if (supabase != null) {
        var query = supabase.from('clothing_items').select();
        if (category != null && category.isNotEmpty && category != 'Todos') {
          query = query.eq('category', category);
        }
        final data = await query;
        if (data is List && data.isNotEmpty) {
          return data.map((json) => ClothingItem.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('[WardrobeApiService] Falha ao consultar Supabase diretamente ($e). Utilizando fallback local.');
    }

    // 3. Fallback gracioso com curadoria mock local
    if (category != null && category.isNotEmpty && category != 'Todos') {
      return mockClothes.where((i) => i.category == category).toList();
    }
    return List.from(mockClothes);
  }

  /// Cadastra nova peça de vestuário no backend
  Future<ClothingItem?> createClothingItem(ClothingItem item) async {
    // 1. Tenta cadastrar via API FastAPI
    try {
      final response = await _client.post(
        '/wardrobe/items',
        body: item.toApiJson(),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ClothingItem.fromJson(data as Map<String, dynamic>);
      } else {
        debugPrint('[WardrobeApiService] Erro ao cadastrar peça via API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('[WardrobeApiService] Backend API offline ($e). Tentando persistência direta no Supabase...');
    }

    // 2. Fallback de persistência direta no Supabase PostgreSQL
    try {
      final supabase = SupabaseConfig.client;
      final userId = SupabaseAuthService().currentUserId;
      if (supabase != null && userId != null) {
        final res = await supabase.from('clothing_items').insert({
          ...item.toApiJson(),
          'user_id': userId,
          'is_archived': false,
        }).select().single();
        return ClothingItem.fromJson(res);
      }
    } catch (e) {
      debugPrint('[WardrobeApiService] Falha ao persistir no Supabase: $e');
    }

    return item;
  }

  /// Realiza o fluxo completo: Upload da foto no Supabase Storage e persistência da peça no acervo
  Future<ClothingItem> uploadAndCatalogGarment({
    Uint8List? imageBytes,
    String? fileName,
    required ClothingItem item,
  }) async {
    String finalImageUrl = item.imageUrl;

    // 1. Upload para o Supabase Storage se houver imagem binária
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final name = fileName ?? 'garment_${DateTime.now().millisecondsSinceEpoch}.png';
      final uploadedUrl = await SupabaseStorageService().uploadClothingImage(
        imageBytes: imageBytes,
        fileName: name,
      );
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        finalImageUrl = uploadedUrl;
      }
    }

    final itemWithUrl = item.copyWith(imageUrl: finalImageUrl);

    // 2. Persistência da peça no banco de dados (API ou Supabase)
    final savedItem = await createClothingItem(itemWithUrl);
    return savedItem ?? itemWithUrl;
  }

  /// Remove o fundo da foto e extrai as cores dominantes em CIE L*a*b* (RF04, RF05).
  /// Lança [SegmentationException] com mensagem pronta para o usuário em caso de falha.
  Future<GarmentSegmentation> segmentGarment({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final http.Response response;
    try {
      response = await _client.postFile(
        '/wardrobe/segment',
        bytes: imageBytes,
        fileName: fileName,
        contentType: _imageContentType(fileName),
        // A primeira chamada carrega o modelo de recorte na memória do servidor
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint('[WardrobeApiService] Falha de rede na segmentação: $e');
      throw const SegmentationException('Não foi possível conectar ao servidor de análise.');
    }

    if (response.statusCode == 200) {
      return GarmentSegmentation.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    debugPrint('[WardrobeApiService] Segmentação recusada: ${response.statusCode} - ${response.body}');
    String? detail;
    try {
      detail = (jsonDecode(response.body) as Map<String, dynamic>)['detail'] as String?;
    } catch (_) {}
    throw SegmentationException(detail ?? 'Não foi possível analisar a foto.');
  }

  static String _imageContentType(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
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
