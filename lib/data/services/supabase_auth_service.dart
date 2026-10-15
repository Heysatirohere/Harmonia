import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/network/api_client.dart';
import '../../core/supabase/supabase_config.dart';
import '../../domain/models/account.dart';
import '../../domain/repositories/auth_repository.dart';

/// Serviço de Autenticação do Supabase (GoTrue) no HarmonIA (RF01, RF18, RN04)
class SupabaseAuthService implements AuthRepository {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  /// Chave do nome completo em `auth.users.user_metadata`
  static const String _fullNameKey = 'full_name';


  SupabaseClient? get _client => SupabaseConfig.client;

  /// Retorna o usuário logado atualmente
  User? get currentUser => _client?.auth.currentUser;

  /// ID do usuário logado, ou null sem sessão ativa
  String? get currentUserId => currentUser?.id;

  /// Verifica se há sessão ativa
  bool get isAuthenticated => currentUser != null;

  /// Token JWT da sessão atual
  String? get currentAccessToken => _client?.auth.currentSession?.accessToken;

  @override
  bool get isAvailable => _client != null;

  @override
  Account? get currentAccount => _toAccount(currentUser);

  @override
  Stream<Account?> get accountChanges {
    final client = _client;
    if (client == null) return Stream<Account?>.value(null);
    return client.auth.onAuthStateChange.map((state) => _toAccount(state.session?.user));
  }

  @override
  Future<SignUpOutcome> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _guard(
      (client) => client.auth.signUp(
        email: email,
        password: password,
        data: {_fullNameKey: fullName},
      ),
    );
    debugPrint('[SupabaseAuth] Cadastro efetuado para: $email');
    return response.session != null ? SignUpOutcome.signedIn : SignUpOutcome.confirmationPending;
  }

  @override
  Future<Account> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _guard(
      (client) => client.auth.signInWithPassword(email: email, password: password),
    );
    final account = _toAccount(response.user);
    if (account == null) {
      throw const AuthFailure('Não foi possível iniciar a sessão. Tente novamente.');
    }
    return account;
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _guard((client) => client.auth.resetPasswordForEmail(email));
  }

  @override
  Future<bool> updateProfile({String? fullName, String? email}) async {
    final current = currentUser;
    final emailChanged = email != null && email != current?.email;

    await _guard(
      (client) => client.auth.updateUser(
        UserAttributes(
          email: emailChanged ? email : null,
          data: fullName != null ? {_fullNameKey: fullName} : null,
        ),
      ),
    );

    // Com "Secure email change" ativo, o e-mail só muda após confirmação
    return emailChanged && currentUser?.email != email;
  }

  @override
  Future<void> updatePassword(String newPassword) {
    return _guard((client) => client.auth.updateUser(UserAttributes(password: newPassword)));
  }

  @override
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

  /// Exclusão definitiva pela API (RN04): fotos do Storage, registros e login.
  /// A API usa a chave administrativa, que o app não tem; se algo falhar, nada fica pela metade.
  @override
  Future<void> deleteAccount() async {
    if (_client == null) {
      throw const AuthFailure('Serviço de conta indisponível. Verifique sua conexão.');
    }
    final http.Response response;
    try {
      // Apagar as fotos pode levar alguns segundos
      response = await ApiClient().delete('/users/me', timeout: const Duration(seconds: 30));
    } catch (e) {
      debugPrint('[SupabaseAuth] Exclusão sem conexão: $e');
      throw const AuthFailure('Falha de conexão. Nada foi excluído; tente novamente.');
    }
    if (response.statusCode != 204) {
      debugPrint('[SupabaseAuth] Exclusão recusada: ${response.statusCode}');
      throw AuthFailure(_detailOf(response.body) ?? 'Não foi possível excluir a conta agora. Tente novamente.');
    }
    // A sessão local ainda guarda o token revogado: descarta sem chamar o servidor
    await _client?.auth.signOut(scope: SignOutScope.local);
  }

  /// Mensagem do backend (`detail`), já escrita para o usuário
  static String? _detailOf(String body) {
    try {
      final detail = (jsonDecode(body) as Map<String, dynamic>)['detail'];
      return detail is String ? detail : null;
    } catch (_) {
      return null;
    }
  }

  Account? _toAccount(User? user) {
    if (user == null) return null;
    return Account(
      id: user.id,
      email: user.email ?? '',
      fullName: user.userMetadata?[_fullNameKey] as String?,
      createdAt: DateTime.tryParse(user.createdAt),
    );
  }

  /// Executa a chamada garantindo cliente inicializado e traduzindo erros
  Future<T> _guard<T>(Future<T> Function(SupabaseClient client) action) async {
    final client = _client;
    if (client == null) {
      throw const AuthFailure('Serviço de conta indisponível. Verifique sua conexão.');
    }
    try {
      return await action(client);
    } on AuthException catch (e) {
      debugPrint('[SupabaseAuth] $e');
      throw AuthFailure(_messageFor(e));
    } on PostgrestException catch (e) {
      debugPrint('[SupabaseAuth] $e');
      throw const AuthFailure('Não foi possível concluir a operação na sua conta.');
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('[SupabaseAuth] $e');
      throw const AuthFailure('Falha de conexão. Tente novamente em instantes.');
    }
  }

  String _messageFor(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'E-mail ou senha incorretos.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Já existe uma conta com este e-mail.';
      case 'email_not_confirmed':
        return 'Confirme seu e-mail pelo link que enviamos antes de entrar.';
      case 'weak_password':
        return 'Senha fraca. Use ao menos 8 caracteres, com letras e números.';
      case 'same_password':
        return 'A nova senha deve ser diferente da atual.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Muitas tentativas. Aguarde alguns minutos.';
      case 'validation_failed':
      case 'email_address_invalid':
        return 'Verifique o formato do e-mail informado.';
      case 'reauthentication_needed':
        return 'Por segurança, entre novamente antes de alterar a senha.';
      default:
        return e.message;
    }
  }
}
