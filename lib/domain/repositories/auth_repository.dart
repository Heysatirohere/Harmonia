import '../models/account.dart';

/// Resultado do cadastro: sessão iniciada ou aguardando confirmação por e-mail
enum SignUpOutcome { signedIn, confirmationPending }

/// Falha de autenticação com mensagem já pronta para exibição ao usuário
class AuthFailure implements Exception {
  final String message;

  const AuthFailure(this.message);

  @override
  String toString() => message;
}

/// Contrato de autenticação e gestão de conta (RF01, RF18, RN04)
///
/// CRUD da conta:
/// - Create: [signUp]
/// - Read:   [currentAccount] / [accountChanges]
/// - Update: [updateProfile] / [updatePassword]
/// - Delete: [deleteAccount]
abstract class AuthRepository {
  /// `false` quando o provedor não foi inicializado (offline / testes)
  bool get isAvailable;

  Account? get currentAccount;

  /// Emite a conta atual a cada mudança de sessão (login, logout, edição)
  Stream<Account?> get accountChanges;

  Future<SignUpOutcome> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<Account> signIn({
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  /// Atualiza nome e/ou e-mail. Retorna `true` se a troca de e-mail
  /// exigir confirmação no novo endereço.
  Future<bool> updateProfile({String? fullName, String? email});

  Future<void> updatePassword(String newPassword);

  Future<void> signOut();

  /// Exclusão definitiva da conta e dos registros vinculados (RN04)
  Future<void> deleteAccount();
}
