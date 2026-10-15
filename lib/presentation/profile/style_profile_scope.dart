import 'package:flutter/widgets.dart';

import '../../domain/repositories/style_profile_repository.dart';

/// Disponibiliza o [StyleProfileRepository] para a árvore de widgets,
/// mantendo telas desacopladas da API concreta.
class StyleProfileScope extends InheritedWidget {
  final StyleProfileRepository repository;

  const StyleProfileScope({
    super.key,
    required this.repository,
    required super.child,
  });

  /// Versão tolerante para telas renderizadas isoladamente (ex.: testes)
  static StyleProfileRepository? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StyleProfileScope>()?.repository;
  }

  @override
  bool updateShouldNotify(StyleProfileScope oldWidget) => repository != oldWidget.repository;
}
