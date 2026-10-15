import 'package:flutter/material.dart';

import '../../domain/models/account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/style_profile_repository.dart';
import '../../models/user_style_profile.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_room.dart';
import '../atelier/room_scene.dart';
import '../auth/auth_scope.dart';
import '../profile/style_profile_scope.dart';
import 'auth_screen.dart';
import 'main_navigation_screen.dart';
import 'onboarding_profile_screen.dart';

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
        final account = snapshot.data;
        return AnimatedSwitcher(
          duration: AppMotion.slow,
          switchInCurve: AppMotion.editorialDecel,
          switchOutCurve: AppMotion.editorialIn,
          child: account != null
              ? _StyleProfileGate(key: ValueKey('app:${account.id}'))
              : const AuthScreen(key: ValueKey('auth')),
        );
      },
    );
  }
}

enum _ProfileStage { loading, onboarding, ready }

/// Leva ao onboarding (RF02) quando o perfil salvo ainda não tem biótipo e cartela.
///
/// Se a API estiver fora do ar, segue para o app: o Ateliê mostra o erro
/// e o onboarding volta a ser oferecido na próxima abertura.
class _StyleProfileGate extends StatefulWidget {
  const _StyleProfileGate({super.key});

  @override
  State<_StyleProfileGate> createState() => _StyleProfileGateState();
}

class _StyleProfileGateState extends State<_StyleProfileGate> {
  StyleProfileRepository? _repository;
  _ProfileStage _stage = _ProfileStage.loading;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = StyleProfileScope.maybeOf(context);
    if (repository == _repository && _repository != null) return;
    _repository = repository;
    _load();
  }

  Future<void> _load() async {
    final repository = _repository;
    if (repository == null) {
      setState(() => _stage = _ProfileStage.ready);
      return;
    }
    _ProfileStage stage;
    try {
      final profile = await repository.fetch();
      stage = profile.isComplete ? _ProfileStage.ready : _ProfileStage.onboarding;
    } on StyleProfileFailure {
      stage = _ProfileStage.ready;
    }
    if (mounted) setState(() => _stage = stage);
  }

  Future<void> _saveOnboarding(BodySilhouetteType silhouette, SeasonalPaletteType palette) async {
    await _repository!.update(silhouette: silhouette, palette: palette);
    if (mounted) setState(() => _stage = _ProfileStage.ready);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.roomDissolve,
      switchInCurve: AppMotion.editorialDecel,
      switchOutCurve: AppMotion.editorialIn,
      child: switch (_stage) {
        // Só a Sala, sem spinner: a espera costuma durar uma fração de segundo
        _ProfileStage.loading => const RoomScene(
            key: ValueKey('loading'),
            room: AtelierRoom.velvetBordeaux,
            child: SizedBox.expand(),
          ),
        _ProfileStage.onboarding => OnboardingProfileScreen(
            key: const ValueKey('onboarding'),
            onCompleted: _saveOnboarding,
          ),
        _ProfileStage.ready => const MainNavigationScreen(key: ValueKey('app')),
      },
    );
  }
}
