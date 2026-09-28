import 'package:flutter/widgets.dart';

import '../../domain/repositories/auth_repository.dart';

/// Disponibiliza o [AuthRepository] para a árvore de widgets,
/// mantendo telas desacopladas do provedor concreto (Supabase).
class AuthScope extends InheritedWidget {
  final AuthRepository repository;

  const AuthScope({
    super.key,
    required this.repository,
    required super.child,
  });

  static AuthRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope ausente na árvore de widgets.');
    return scope!.repository;
  }

  /// Versão tolerante para telas renderizadas isoladamente (ex.: testes)
  static AuthRepository? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthScope>()?.repository;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) => repository != oldWidget.repository;
}
