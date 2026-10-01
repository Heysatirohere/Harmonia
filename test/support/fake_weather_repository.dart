import 'package:harmonia_mvp/domain/repositories/weather_repository.dart';
import 'package:harmonia_mvp/models/weather_context.dart';

import 'sample_weather.dart';

/// Clima em memória para testes de widget; [failure] simula localização ou previsão indisponível
class FakeWeatherRepository implements WeatherRepository {
  WeatherContext weather;
  WeatherFailure? failure;
  final List<WeatherFailureKind> resolved = [];

  FakeWeatherRepository({this.weather = sampleWeather, this.failure});

  @override
  Future<WeatherContext> current() async {
    final queued = failure;
    if (queued != null) throw queued;
    return weather;
  }

  @override
  Future<void> resolve(WeatherFailureKind kind) async {
    resolved.add(kind);
    failure = null;
  }
}
