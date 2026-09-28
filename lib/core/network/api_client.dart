import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cliente HTTP Centralizado para consumo da API FastAPI do HarmonIA (SOA)
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  /// URL Base da API FastAPI
  String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/v1';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/v1';
      }
    } catch (_) {
      // Fallback em ambientes onde Platform não está disponível
    }
    return 'http://127.0.0.1:8000/v1';
  }

  /// ID do usuário padrão para sessão de desenvolvimento
  String currentUserId = 'e2b34a62-7f39-44d5-86f3-181559868e4c';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-User-ID': currentUserId,
      };

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

  Future<http.Response> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http.delete(uri, headers: _headers).timeout(timeoutDuration);
  }
}
