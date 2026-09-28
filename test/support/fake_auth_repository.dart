import 'dart:async';

import 'package:harmonia_mvp/domain/models/account.dart';
import 'package:harmonia_mvp/domain/repositories/auth_repository.dart';

/// Repositório de autenticação em memória para testes de widget
class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<Account?>.broadcast();
  final Map<String, String> _passwords = {};
  final Map<String, Account> _accounts = {};

  Account? _current;
  bool requireEmailConfirmation;
  AuthFailure? nextFailure;
  final List<String> calls = [];

  FakeAuthRepository({this.requireEmailConfirmation = false, Account? signedIn, String password = 'senha123'}) {
    if (signedIn != null) {
      _accounts[signedIn.email] = signedIn;
      _passwords[signedIn.email] = password;
      _current = signedIn;
    }
  }

  void _emit(Account? account) {
    _current = account;
    _controller.add(account);
  }

  void _throwIfQueued() {
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      throw failure;
    }
  }

  @override
  bool get isAvailable => true;

  @override
  Account? get currentAccount => _current;

  @override
  Stream<Account?> get accountChanges => _controller.stream;

  @override
  Future<SignUpOutcome> signUp({required String fullName, required String email, required String password}) async {
    calls.add('signUp');
    _throwIfQueued();
    if (_accounts.containsKey(email)) throw const AuthFailure('Já existe uma conta com este e-mail.');
    final account = Account(id: 'id-$email', email: email, fullName: fullName, createdAt: DateTime(2026, 9, 1));
    _accounts[email] = account;
    _passwords[email] = password;
    if (requireEmailConfirmation) return SignUpOutcome.confirmationPending;
    _emit(account);
    return SignUpOutcome.signedIn;
  }

  @override
  Future<Account> signIn({required String email, required String password}) async {
    calls.add('signIn');
    _throwIfQueued();
    if (_passwords[email] != password) throw const AuthFailure('E-mail ou senha incorretos.');
    final account = _accounts[email]!;
    _emit(account);
    return account;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    calls.add('reset:$email');
    _throwIfQueued();
  }

  @override
  Future<bool> updateProfile({String? fullName, String? email}) async {
    calls.add('updateProfile');
    _throwIfQueued();
    final updated = _current!.copyWith(fullName: fullName);
    _emit(updated);
    return email != null;
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    calls.add('updatePassword');
    _throwIfQueued();
    _passwords[_current!.email] = newPassword;
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    _emit(null);
  }

  @override
  Future<void> deleteAccount() async {
    calls.add('deleteAccount');
    _throwIfQueued();
    _accounts.remove(_current!.email);
    _passwords.remove(_current!.email);
    _emit(null);
  }
}
