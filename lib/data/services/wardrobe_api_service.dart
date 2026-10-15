import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/network/api_client.dart';
import '../../core/supabase/supabase_config.dart';
import '../../models/clothing_item.dart';
import '../../models/garment_segmentation.dart';
import '../../models/wardrobe_analytics.dart';
import 'supabase_storage_service.dart';

/// Falha ao ler ou salvar o acervo, com mensagem pronta para o usuário
class WardrobeException implements Exception {
  final String message;

  const WardrobeException(this.message);

  @override
  String toString() => message;
}

/// Serviço de integração com o módulo de Acervo Virtual (Wardrobe) da API e Supabase (RF03, RF04, RF06, RN01, RN02)
class WardrobeApiService {
  final ApiClient _client;

  WardrobeApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Busca peças do guarda-roupa via API, com o Supabase como segunda via.
  /// Lança [WardrobeException] quando nenhuma das duas responde.
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
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((item) => ClothingItem.fromJson(item as Map<String, dynamic>)).toList();
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
        return data.map(ClothingItem.fromJson).toList();
      }
    } catch (e) {
      debugPrint('[WardrobeApiService] Falha ao consultar Supabase diretamente ($e).');
    }

    throw const WardrobeException('Não foi possível carregar o seu acervo. Verifique sua conexão.');
  }

  /// Saúde do acervo (Seção 3.2.2), calculada pela API a partir das peças e dos looks aprovados.
  /// Sem segunda via no Supabase: o cálculo de uso só existe no backend.
  Future<WardrobeAnalytics> getAnalytics() async {
    try {
      final response = await _client.get('/wardrobe/analytics');
      if (response.statusCode == 200) {
        return WardrobeAnalytics.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
      }
      debugPrint('[WardrobeApiService] Saúde do acervo recusada: ${response.statusCode}');
    } catch (e) {
      debugPrint('[WardrobeApiService] Falha ao carregar a saúde do acervo: $e');
    }
    throw const WardrobeException('Não foi possível ler a saúde do seu acervo agora. Verifique sua conexão.');
  }

  /// Cadastra nova peça de vestuário no backend. Retorna null se nada foi salvo.
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
        debugPrint('[WardrobeApiService] Erro ao cadastrar peça via API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Sem segunda via direta no Supabase: com a API lenta, o servidor ainda salvava a peça
      // e a segunda via criava uma cópia, além de pular a cota de peças (RN02)
      debugPrint('[WardrobeApiService] Falha ao cadastrar peça via API: $e');
    }
    return null;
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
      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        throw const WardrobeException('Não foi possível enviar a foto da peça. Tente novamente.');
      }
      finalImageUrl = uploadedUrl;
    }

    final itemWithUrl = item.copyWith(imageUrl: finalImageUrl);

    // 2. Persistência da peça no banco de dados (API ou Supabase)
    final savedItem = await createClothingItem(itemWithUrl);
    if (savedItem == null) {
      throw const WardrobeException('Não foi possível salvar a peça no acervo. Tente novamente.');
    }
    return savedItem;
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

  /// Exclui peça do acervo no backend com isolamento multi-tenant (RN01, RN04).
  /// Sem segunda via no Supabase: só a API apaga a foto do Storage junto com o registro.
  Future<bool> deleteClothingItem(String itemId) async {
    try {
      final response = await _client.delete('/wardrobe/items/$itemId');
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('[WardrobeApiService] Falha ao deletar peça via API: $e');
      return false;
    }
  }

  /// Atualiza atributos taxonômicos da peça (categoria, nome, formalidade) no backend (RF05, 3.2.3)
  Future<ClothingItem?> updateClothingItem(ClothingItem item) async {
    try {
      final response = await _client.patch(
        '/wardrobe/items/${item.id}',
        body: {
          'category': item.category,
          'subcategory': item.name,
          if (item.formalityScore != null) 'formality_score': item.formalityScore,
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return ClothingItem.fromJson(data);
      }
    } catch (e) {
      debugPrint('[WardrobeApiService] Falha ao atualizar peça via API: $e');
    }

    // Fallback Supabase
    try {
      final supabase = SupabaseConfig.client;
      if (supabase != null) {
        final res = await supabase.from('clothing_items').update({
          'category': item.category,
          'subcategory': item.name,
          if (item.formalityScore != null) 'formality_score': item.formalityScore,
        }).eq('id', item.id).select().single();
        return ClothingItem.fromJson(res);
      }
    } catch (e) {
      debugPrint('[WardrobeApiService] Falha ao atualizar no Supabase: $e');
    }
    return null;
  }
}
