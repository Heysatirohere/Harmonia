import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/data/services/open_meteo_weather_service.dart';
import 'package:harmonia_mvp/domain/repositories/weather_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _forecast = {
  'current': {'temperature_2m': 24.2, 'relative_humidity_2m': 58, 'weather_code': 1, 'wind_speed_10m': 10.4},
  'daily': {
    'temperature_2m_max': [27.0],
    'temperature_2m_min': [18.0],
    'precipitation_probability_max': [10],
  },
};

Future<Coordinates> _saoPaulo() async => (latitude: -23.5505, longitude: -46.6333);

void main() {
  group('OpenMeteoWeatherService (RF16)', () {
    test('consulta a previsão com a localização aproximada e nomeia a cidade', () async {
      late Uri requested;
      final service = OpenMeteoWeatherService(
        httpClient: MockClient((request) async {
          requested = request.url;
          return http.Response(jsonEncode(_forecast), 200);
        }),
        locate: _saoPaulo,
        cityName: (_) async => 'São Paulo, SP',
      );

      final weather = await service.current();

      expect(requested.host, 'api.open-meteo.com');
      // Duas casas decimais (~1 km): o suficiente para a previsão, sem a posição exata
      expect(requested.queryParameters['latitude'], '-23.55');
      expect(requested.queryParameters['longitude'], '-46.63');
      expect(requested.queryParameters['forecast_days'], '1');
      expect(weather.city, 'São Paulo, SP');
      expect(weather.formattedTemperature, '24°C');
      expect(weather.isRainExpected, isFalse);
    });

    test('sem nome de cidade a previsão continua valendo', () async {
      final service = OpenMeteoWeatherService(
        httpClient: MockClient((_) async => http.Response(jsonEncode(_forecast), 200)),
        locate: _saoPaulo,
        cityName: (_) async => throw Exception('geocoder indisponível'),
      );

      expect((await service.current()).city, 'Sua localização');
    });

    test('permissão recusada chega como falha tipada, sem consultar a previsão', () async {
      var called = false;
      final service = OpenMeteoWeatherService(
        httpClient: MockClient((_) async {
          called = true;
          return http.Response('{}', 200);
        }),
        locate: () async => throw const WeatherFailure(WeatherFailureKind.permissionDenied, 'Sem permissão.'),
      );

      await expectLater(
        service.current(),
        throwsA(isA<WeatherFailure>().having((f) => f.kind, 'kind', WeatherFailureKind.permissionDenied)),
      );
      expect(called, isFalse);
    });

    test('erro inesperado do plugin de localização vira clima indisponível', () async {
      final service = OpenMeteoWeatherService(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
        locate: () async => throw StateError('plugin ausente'),
      );

      await expectLater(
        service.current(),
        throwsA(isA<WeatherFailure>().having((f) => f.kind, 'kind', WeatherFailureKind.unavailable)),
      );
    });

    test('previsão fora do ar vira clima indisponível', () async {
      final service = OpenMeteoWeatherService(
        httpClient: MockClient((_) async => http.Response('erro', 503)),
        locate: _saoPaulo,
        cityName: (_) async => 'São Paulo, SP',
      );

      await expectLater(
        service.current(),
        throwsA(isA<WeatherFailure>().having((f) => f.kind, 'kind', WeatherFailureKind.unavailable)),
      );
    });
  });
}
