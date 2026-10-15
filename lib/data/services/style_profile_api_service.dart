import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/network/api_client.dart';
import '../../domain/models/colorimetry_result.dart';
import '../../domain/models/style_profile.dart';
import '../../domain/repositories/style_profile_repository.dart';
import '../../models/user_style_profile.dart';

/// Perfil de estilo persistido na API FastAPI (`/users/me`)
class StyleProfileApiService implements StyleProfileRepository {
  final ApiClient _client;

  StyleProfileApiService({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<StyleProfile> fetch() => _send(() => _client.get('/users/me'));

  @override
  Future<StyleProfile> update({
    BodySilhouetteType? silhouette,
    SeasonalPaletteType? palette,
    bool? isPublic,
  }) {
    return _send(() => _client.patch('/users/me', body: {
          'body_shape': ?silhouette?.apiKey,
          'seasonal_palette': ?palette?.apiKey,
          'is_public': ?isPublic,
        }));
  }

  @override
  Future<ColorimetryResult> analyzeSelfie(Uint8List bytes, String fileName) async {
    final http.Response response;
    try {
      response = await _client.postFile(
        '/users/me/colorimetry',
        bytes: bytes,
        fileName: fileName,
        contentType: fileName.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg',
      );
    } catch (_) {
      throw const StyleProfileFailure('Não foi possível conectar ao ateliê. Verifique sua conexão.');
    }
    switch (response.statusCode) {
      case 200:
        return ColorimetryResult.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
      case 401:
        throw const StyleProfileFailure('Sessão expirada. Entre novamente.');
      case 422:
        // Rosto fora do oval ou arquivo inválido: o servidor explica o que refazer
        final detail = (jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>)['detail'];
        throw StyleProfileFailure(detail is String ? detail : 'Não foi possível analisar a selfie.');
      default:
        throw const StyleProfileFailure('Não foi possível analisar a selfie agora.');
    }
  }

  Future<StyleProfile> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request();
    } catch (_) {
      throw const StyleProfileFailure('Não foi possível conectar ao ateliê. Verifique sua conexão.');
    }

    if (response.statusCode == 401) {
      throw const StyleProfileFailure('Sessão expirada. Entre novamente.');
    }
    if (response.statusCode != 200) {
      throw const StyleProfileFailure('Não foi possível carregar o seu perfil de estilo.');
    }
    return StyleProfile.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }
}
