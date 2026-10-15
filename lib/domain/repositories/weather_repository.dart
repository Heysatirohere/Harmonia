import '../../models/weather_context.dart';

/// Por que o clima local não pôde ser lido
enum WeatherFailureKind {
  /// O usuário recusou a localização; pode ser pedida de novo
  permissionDenied,

  /// Recusada de forma permanente: só nas configurações do app
  permissionDeniedForever,

  /// Localização do aparelho desligada
  serviceDisabled,

  /// Sem conexão ou a previsão não respondeu
  unavailable,
}

class WeatherFailure implements Exception {
  final WeatherFailureKind kind;
  final String message;

  const WeatherFailure(this.kind, this.message);

  @override
  String toString() => message;
}

/// Clima local do aparelho (RF16), lido com permissão explícita de localização
abstract class WeatherRepository {
  /// Lança [WeatherFailure] quando não há localização ou previsão
  Future<WeatherContext> current();

  /// Leva o usuário ao ponto que resolve a falha (diálogo de permissão ou configurações)
  Future<void> resolve(WeatherFailureKind kind);
}
