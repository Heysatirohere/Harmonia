/// Modo de demonstração (apresentações e banca), ligado só na compilação:
///   flutter run --dart-define=HARMONIA_DEMO=true
///
/// Ligado, as telas preenchem com o acervo de exemplo quando a API falha ou volta vazia.
/// Desligado (padrão, inclusive nos testes), o erro real aparece e nada é inventado.
const bool kDemoMode = bool.fromEnvironment('HARMONIA_DEMO');
