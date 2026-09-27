import '../models/weather_context.dart';

/// Dados Mockados de Telemetria Meteorológica do HarmonIA (RF16)
class MockWeather {
  MockWeather._();

  /// Telemetria atual de referência para a tela de sugestão diária
  static const WeatherContext current = WeatherContext(
    city: 'SÃO PAULO, SP',
    temperature: 23.0,
    tempMin: 17.0,
    tempMax: 25.0,
    conditionType: WeatherConditionType.partlyCloudy,
    conditionLabel: 'PARCIALMENTE ENSOLARADO',
    windKmH: 14.0,
    humidityPercentage: 65,
    thermalAmplitudeLabel: 'Moderada (8°C)',
    recommendationBadge: 'Adequado para amplitude térmica moderada',
    sOcasionScore: 0.88,
    sOcasionRationale:
        'A variação de 17°C a 25°C com vento brando de 14 km/h e 65% de umidade requer sobreposição inteligente em tecidos de fibra natural com caimento estruturado (ex.: blazer leve em linho sobre peça de seda), garantindo conforto higrotérmico ao longo do dia.',
  );
}
