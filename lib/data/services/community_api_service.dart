import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/network/api_client.dart';
import '../../models/community_post.dart';
import 'supabase_storage_service.dart';

/// Falha no feed comunitário, com mensagem pronta para o usuário
class CommunityException implements Exception {
  final String message;

  const CommunityException(this.message);

  @override
  String toString() => message;
}

/// Recortes do feed (RF15, Seção 3.5.3)
enum FeedFilter {
  all('all'),
  bodyShape('body_shape'),
  palette('palette'),
  saved('saved'),
  mine('mine');

  const FeedFilter(this.apiValue);
  final String apiValue;
}

/// Envio da foto ao Storage; separado para os testes não dependerem do Supabase
typedef PhotoUploader = Future<String?> Function(Uint8List bytes, String fileName);

/// Serviço do feed comunitário (RF14, RF15, RN05)
class CommunityApiService {
  final ApiClient _client;
  final PhotoUploader _uploadPhoto;

  CommunityApiService({ApiClient? client, PhotoUploader? uploadPhoto})
      : _client = client ?? ApiClient(),
        _uploadPhoto = uploadPhoto ?? _uploadToStorage;

  static Future<String?> _uploadToStorage(Uint8List bytes, String fileName) {
    return SupabaseStorageService().uploadClothingImage(
      imageBytes: bytes,
      fileName: fileName,
      contentType: 'image/jpeg',
    );
  }

  Future<CommunityFeedPage> fetchFeed({
    FeedFilter filter = FeedFilter.all,
    String? occasion,
    String? query,
    DateTime? before,
  }) async {
    final response = await _send(() => _client.get('/community/posts', queryParams: {
          'filter': filter.apiValue,
          'occasion': ?occasion,
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          if (before != null) 'before': before.toUtc().toIso8601String(),
        }));
    _expect(response, 200, 'Não foi possível carregar o feed agora.');
    return CommunityFeedPage.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  /// Envia a foto para a pasta do usuário e publica (RF14). Com [feedbackId], o post leva as
  /// peças e o IHE do look aprovado; [isPublic] nulo segue a visibilidade do perfil (RN05).
  Future<CommunityPost> publish({
    required Uint8List photo,
    required String caption,
    required String occasion,
    List<String> styleTags = const [],
    String? feedbackId,
    bool? isPublic,
  }) async {
    final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final imageUrl = await _uploadPhoto(photo, fileName);
    if (imageUrl == null || imageUrl.isEmpty) {
      throw const CommunityException('Não foi possível enviar a foto. Tente novamente.');
    }
    final response = await _send(() => _client.post('/community/posts', body: {
          'image_url': imageUrl,
          'caption': caption,
          'occasion': occasion,
          'style_tags': styleTags,
          'feedback_id': ?feedbackId,
          'is_public': ?isPublic,
        }));
    _expect(response, 201, 'Não foi possível publicar agora.');
    return CommunityPost.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  Future<void> setLiked(String postId, bool liked) => _toggle('/community/posts/$postId/like', liked);

  /// Salvar no moodboard privado (Seção 3.5.2)
  Future<void> setSaved(String postId, bool saved) => _toggle('/community/posts/$postId/save', saved);

  Future<void> delete(String postId) async {
    final response = await _send(() => _client.delete('/community/posts/$postId'));
    _expect(response, 204, 'Não foi possível apagar a publicação agora.');
  }

  Future<void> _toggle(String path, bool on) async {
    final response = await _send(() => on ? _client.put(path) : _client.delete(path));
    _expect(response, 204, 'Não foi possível atualizar agora.');
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } catch (e) {
      debugPrint('[CommunityApiService] Sem conexão: $e');
      throw const CommunityException('Não foi possível conectar ao ateliê. Verifique sua conexão.');
    }
  }

  static void _expect(http.Response response, int status, String fallback) {
    if (response.statusCode == status) return;
    if (response.statusCode == 401) throw const CommunityException('Sessão expirada. Entre novamente.');
    if (response.statusCode == 404) throw const CommunityException('Esta publicação não está mais disponível.');
    debugPrint('[CommunityApiService] ${response.statusCode}: ${response.body}');
    throw CommunityException(fallback);
  }
}
