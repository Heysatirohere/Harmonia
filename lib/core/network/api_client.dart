import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../data/services/supabase_auth_service.dart';

/// Cliente HTTP Centralizado para consumo da API FastAPI do HarmonIA (SOA)
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  /// Origem da API definida no build, ex: --dart-define=API_BASE_URL=http://192.168.0.10:8000
  static const String _configuredOrigin = String.fromEnvironment('API_BASE_URL');

  /// URL Base da API FastAPI (Google Cloud Run ou Local)
  String get baseUrl {
    if (_configuredOrigin.isNotEmpty) {
      return '${_configuredOrigin.replaceFirst(RegExp(r'/+$'), '')}/api/v1';
    }
    // Sem definição: servidor local visto pelo emulador Android ou pelo próprio computador
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api/v1';
      }
    } catch (_) {
      // Fallback em ambientes onde Platform não está disponível
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  /// A API identifica o usuário apenas pelo JWT do Supabase no header Authorization
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = SupabaseAuthService().currentAccessToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Duration timeoutDuration = const Duration(seconds: 4);

  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
    return await http.get(uri, headers: _headers).timeout(timeoutDuration);
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http
        .post(
          uri,
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeoutDuration);
  }

  Future<http.Response> put(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http.put(uri, headers: _headers).timeout(timeoutDuration);
  }

  Future<http.Response> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http
        .patch(
          uri,
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeoutDuration);
  }

  /// Envia um arquivo como multipart/form-data no campo `file`.
  Future<http.Response> postFile(
    String endpoint, {
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    Duration? timeout,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'))
      ..headers.addAll(_headers..remove('Content-Type'))
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ));
    final streamed = await request.send().timeout(timeout ?? timeoutDuration);
    return http.Response.fromStream(streamed);
  }

  Future<http.Response> delete(String endpoint, {Duration? timeout}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http.delete(uri, headers: _headers).timeout(timeout ?? timeoutDuration);
  }
}
