import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_config.dart';

/// Serviço de Autenticação do Supabase (GoTrue) no HarmonIA (RF01, RNF01, RNF02)
class SupabaseAuthService {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  SupabaseClient? get _client => SupabaseConfig.client;

  /// Retorna o usuário logado atualmente
  User? get currentUser => _client?.auth.currentUser;

  /// Retorna o ID do usuário (ou ID de desenvolvimento mock se offline)
  String get currentUserId {
    return currentUser?.id ?? 'e2b34a62-7f39-44d5-86f3-181559868e4c';
  }

  /// Verifica se há sessão ativa
  bool get isAuthenticated => currentUser != null;

  /// Token JWT da sessão atual
  String? get currentAccessToken => _client?.auth.currentSession?.accessToken;

  /// Cadastro com e-mail e senha
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    final client = _client;
    if (client == null) {
      debugPrint('[SupabaseAuth] Cliente Supabase não inicializado.');
      return null;
    }
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      debugPrint('[SupabaseAuth] Cadastro efetuado para: $email');
      return response;
    } catch (e) {
      debugPrint('[SupabaseAuth] Erro no cadastro: $e');
      rethrow;
    }
  }

  /// Login com e-mail e senha
  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      debugPrint('[SupabaseAuth] Cliente Supabase não inicializado.');
      return null;
    }
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('[SupabaseAuth] Login efetuado com sucesso para: $email');
      return response;
    } catch (e) {
      debugPrint('[SupabaseAuth] Erro no login: $e');
      rethrow;
    }
  }

  /// Encerramento de sessão (Logout)
  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.auth.signOut();
      debugPrint('[SupabaseAuth] Logout realizado.');
    } catch (e) {
      debugPrint('[SupabaseAuth] Erro no logout: $e');
    }
  }

  /// Stream para escutar mudanças no estado da autenticação
  Stream<AuthState>? get authStateChanges => _client?.auth.onAuthStateChange;
}
