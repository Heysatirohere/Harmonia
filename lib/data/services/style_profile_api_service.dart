import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/api_client.dart';
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
          if (silhouette != null) 'body_shape': silhouette.apiKey,
          if (palette != null) 'seasonal_palette': palette.apiKey,
          if (isPublic != null) 'is_public': isPublic,
        }));
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
