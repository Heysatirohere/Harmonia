import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../domain/repositories/weather_repository.dart';
import '../../models/weather_context.dart';

typedef Coordinates = ({double latitude, double longitude});

/// Clima local via Open-Meteo (gratuito, sem chave) e localização do aparelho (RF16)
///
/// Usa localização aproximada: basta para a previsão e expõe menos dados (LGPD).
class OpenMeteoWeatherService implements WeatherRepository {
  static const _forecastUrl = 'https://api.open-meteo.com/v1/forecast';

  final http.Client _http;
  final Future<Coordinates> Function() _locate;
  final Future<String?> Function(Coordinates) _cityName;

  OpenMeteoWeatherService({
    http.Client? httpClient,
    Future<Coordinates> Function()? locate,
    Future<String?> Function(Coordinates)? cityName,
  })  : _http = httpClient ?? http.Client(),
        _locate = locate ?? _locateDevice,
        _cityName = cityName ?? _reverseGeocode;

  @override
  Future<WeatherContext> current() async {
    final Coordinates coordinates;
    try {
      coordinates = await _locate();
    } on WeatherFailure {
      rethrow;
    } catch (e) {
      debugPrint('[OpenMeteoWeatherService] Localização indisponível: $e');
      throw const WeatherFailure(WeatherFailureKind.unavailable, 'Não foi possível obter a sua localização.');
    }

    final http.Response response;
    try {
      response = await _http
          .get(Uri.parse(_forecastUrl).replace(queryParameters: {
            'latitude': coordinates.latitude.toStringAsFixed(2),
            'longitude': coordinates.longitude.toStringAsFixed(2),
            'current': 'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
            'daily': 'temperature_2m_max,temperature_2m_min,precipitation_probability_max',
            'timezone': 'auto',
            'forecast_days': '1',
          }))
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[OpenMeteoWeatherService] Previsão indisponível: $e');
      throw const WeatherFailure(WeatherFailureKind.unavailable, 'Não foi possível ler o clima agora.');
    }
    if (response.statusCode != 200) {
      throw const WeatherFailure(WeatherFailureKind.unavailable, 'Não foi possível ler o clima agora.');
    }

    String? city;
    try {
      city = await _cityName(coordinates);
    } catch (_) {
      // O nome da cidade é só rótulo; a previsão vale sem ele
    }

    return WeatherContext.fromOpenMeteo(
      jsonDecode(response.body) as Map<String, dynamic>,
      city: (city == null || city.isEmpty) ? 'Sua localização' : city,
    );
  }

  @override
  Future<void> resolve(WeatherFailureKind kind) async {
    switch (kind) {
      case WeatherFailureKind.permissionDenied:
        await Geolocator.requestPermission();
      case WeatherFailureKind.permissionDeniedForever:
        await Geolocator.openAppSettings();
      case WeatherFailureKind.serviceDisabled:
        await Geolocator.openLocationSettings();
      case WeatherFailureKind.unavailable:
        break;
    }
  }

  static Future<Coordinates> _locateDevice() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const WeatherFailure(
        WeatherFailureKind.serviceDisabled,
        'A localização do aparelho está desligada.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const WeatherFailure(
        WeatherFailureKind.permissionDenied,
        'Sem permissão de localização, os looks não consideram o clima.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const WeatherFailure(
        WeatherFailureKind.permissionDeniedForever,
        'A localização foi bloqueada para o HarmonIA. Ative nas configurações.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return (latitude: last.latitude, longitude: last.longitude);
      throw const WeatherFailure(WeatherFailureKind.unavailable, 'Não foi possível obter a sua localização.');
    }
  }

  static Future<String?> _reverseGeocode(Coordinates coordinates) async {
    final places = await Geocoding().placemarkFromCoordinates(coordinates.latitude, coordinates.longitude);
    if (places.isEmpty) return null;
    final place = places.first;
    final city = place.locality?.isNotEmpty == true ? place.locality : place.subAdministrativeArea;
    final state = place.administrativeArea;
    if (city == null || city.isEmpty) return state;
    return state == null || state.isEmpty ? city : '$city, $state';
  }
}
