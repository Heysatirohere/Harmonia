import 'package:flutter/material.dart';

import '../../domain/models/account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_scope.dart';
import 'auth_screen.dart';
import 'main_navigation_screen.dart';

/// Decide entre a entrada de conta e o app com base na sessão ativa.
///
/// Sem provedor disponível (offline ou testes), segue direto para o app
/// em modo de desenvolvimento, mantendo o comportamento dos mocks.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthRepository? _auth;
  Stream<Account?>? _accountChanges;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.of(context);
    if (auth != _auth) {
      _auth = auth;
      _accountChanges = auth.accountChanges;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = _auth!;
    if (!auth.isAvailable) return const MainNavigationScreen();

    return StreamBuilder<Account?>(
      stream: _accountChanges,
      initialData: auth.currentAccount,
      builder: (context, snapshot) {
        final signedIn = snapshot.data != null;
        return AnimatedSwitcher(
          duration: AppMotion.slow,
          switchInCurve: AppMotion.editorialDecel,
          switchOutCurve: AppMotion.editorialIn,
          child: signedIn
              ? const MainNavigationScreen(key: ValueKey('app'))
              : const AuthScreen(key: ValueKey('auth')),
        );
      },
    );
  }
}
