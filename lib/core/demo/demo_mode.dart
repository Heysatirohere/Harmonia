import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

bool _isFlutterTestEnvironment() {
  if (kIsWeb) return false;
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}

/// Modo Offline / Demonstração Completa (apresentações e testes manuais sem servidor).
///
/// Ativo por padrão ao rodar o app (`flutter run` / APK), desconectando 100% do
/// servidor FastAPI, Supabase e Open-Meteo e operando com o estado interativo em
/// memória (`MockAtelierStore`). Na suíte automatizada (`FLUTTER_TEST`), permanece
/// desativado por padrão para preservar os testes de contrato HTTP, podendo ser
/// ligado via [setDemoModeForTesting].
bool _demoModeEnabled = const bool.fromEnvironment('HARMONIA_DEMO', defaultValue: true) &&
    !_isFlutterTestEnvironment();

bool get kDemoMode => _demoModeEnabled;

void setDemoModeForTesting(bool enabled) {
  _demoModeEnabled = enabled;
}
