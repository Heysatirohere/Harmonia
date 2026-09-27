import 'package:flutter/material.dart';

/// Tipos de condição meteorológica suportados pela telemetria do HarmonIA
enum WeatherConditionType {
  sunny,
  partlyCloudy,
  cloudy,
  lightRain,
  rainy,
  breezy,
}

/// Modelo de Dados de Telemetria Meteorológica e Contexto do Look (RF16)
///
/// Encapsula as variáveis de clima locais e o raciocínio estético que
/// alimenta a métrica S_ocasion do Índice de Harmonia Estética (IHE).
class WeatherContext {
  final String city;
  final double temperature;
  final double tempMin;
  final double tempMax;
  final WeatherConditionType conditionType;
  final String conditionLabel;
  final double windKmH;
  final int humidityPercentage;
  final String thermalAmplitudeLabel;
  final String recommendationBadge;
  final double sOcasionScore; // Valor entre 0.0 e 1.0 (ex: 0.88)
  final String sOcasionRationale;

  const WeatherContext({
    required this.city,
    required this.temperature,
    required this.tempMin,
    required this.tempMax,
    required this.conditionType,
    required this.conditionLabel,
    required this.windKmH,
    required this.humidityPercentage,
    required this.thermalAmplitudeLabel,
    required this.recommendationBadge,
    required this.sOcasionScore,
    required this.sOcasionRationale,
  });

  /// Temperatura formatada em graus Celsius (ex: "23°C")
  String get formattedTemperature => '${temperature.round()}°C';

  /// Intervalo térmico formatado (ex: "17° — 25°C")
  String get formattedMinMax => '${tempMin.round()}° — ${tempMax.round()}°C';

  /// Velocidade do vento formatada (ex: "14 km/h")
  String get formattedWind => '${windKmH.round()} km/h';

  /// Umidade relativa do ar formatada (ex: "65%")
  String get formattedHumidity => '$humidityPercentage%';

  /// Métrica de Ocasião/Clima em percentual (ex: "88%")
  String get formattedScore => '${(sOcasionScore * 100).round()}%';

  /// Ícone linear minimalista refinado conforme AGENTS.md
  IconData get iconData {
    switch (conditionType) {
      case WeatherConditionType.sunny:
        return Icons.wb_sunny_outlined;
      case WeatherConditionType.partlyCloudy:
        return Icons.wb_cloudy_outlined;
      case WeatherConditionType.cloudy:
        return Icons.cloud_outlined;
      case WeatherConditionType.lightRain:
        return Icons.grain_outlined;
      case WeatherConditionType.rainy:
        return Icons.water_drop_outlined;
      case WeatherConditionType.breezy:
        return Icons.air_outlined;
    }
  }
}
