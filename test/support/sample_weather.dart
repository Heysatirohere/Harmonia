import 'package:harmonia_mvp/models/weather_context.dart';

/// Clima de exemplo para testes de widget
const sampleWeather = WeatherContext(
  city: 'São Paulo, SP',
  temperature: 23.0,
  tempMin: 17.0,
  tempMax: 25.0,
  conditionType: WeatherConditionType.partlyCloudy,
  conditionLabel: 'Parcialmente nublado',
  windKmH: 14.0,
  humidityPercentage: 65,
  rainProbability: 20,
  thermalAmplitudeLabel: 'Moderada (8°C)',
  recommendationBadge: 'Clima ameno: peças de meia-estação',
  sOcasionRationale: 'Hoje entre 17°C e 25°C, com vento de 14 km/h, 65% de umidade e 20% de chance de chuva.',
);
