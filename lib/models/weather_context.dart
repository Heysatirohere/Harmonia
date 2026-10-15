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
/// Encapsula as variáveis de clima locais que alimentam o pilar S_ocasion do
/// Índice de Harmonia Estética (IHE). Os textos de recomendação são derivados
/// só dos números medidos, por regras fixas.
class WeatherContext {
  final String city;
  final double temperature;
  final double tempMin;
  final double tempMax;
  final WeatherConditionType conditionType;
  final String conditionLabel;
  final double windKmH;
  final int humidityPercentage;

  /// Probabilidade máxima de chuva prevista para o dia (0 a 100); nula se a fonte não informar
  final int? rainProbability;
  final String thermalAmplitudeLabel;
  final String recommendationBadge;
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
    this.rainProbability,
    required this.thermalAmplitudeLabel,
    required this.recommendationBadge,
    required this.sOcasionRationale,
  });

  /// Chuva prevista a partir desta probabilidade diária (3.3.1: "previsão de chuva")
  static const int rainProbabilityThreshold = 60;

  /// Lê a resposta do Open-Meteo (`current` + `daily` com um dia de previsão)
  factory WeatherContext.fromOpenMeteo(Map<String, dynamic> json, {required String city}) {
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;
    double first(String key) => ((daily[key] as List).first as num).toDouble();

    final temperature = (current['temperature_2m'] as num).toDouble();
    final wind = (current['wind_speed_10m'] as num).toDouble();
    final humidity = (current['relative_humidity_2m'] as num).round();
    final code = (current['weather_code'] as num).toInt();
    final tempMax = first('temperature_2m_max');
    final tempMin = first('temperature_2m_min');
    final rainList = daily['precipitation_probability_max'] as List?;
    final rainProbability = (rainList == null || rainList.isEmpty || rainList.first == null)
        ? null
        : (rainList.first as num).round();

    var type = _typeForCode(code);
    if (wind >= 30 && type != WeatherConditionType.lightRain && type != WeatherConditionType.rainy) {
      type = WeatherConditionType.breezy;
    }

    final amplitude = tempMax - tempMin;
    final rainExpected = type == WeatherConditionType.lightRain ||
        type == WeatherConditionType.rainy ||
        (rainProbability ?? 0) >= rainProbabilityThreshold;

    return WeatherContext(
      city: city,
      temperature: temperature,
      tempMin: tempMin,
      tempMax: tempMax,
      conditionType: type,
      conditionLabel: _labelForCode(code),
      windKmH: wind,
      humidityPercentage: humidity,
      rainProbability: rainProbability,
      thermalAmplitudeLabel: '${_amplitudeLevel(amplitude)} (${amplitude.round()}°C)',
      recommendationBadge: _recommendation(temperature, amplitude, rainExpected),
      sOcasionRationale: _rationale(tempMin, tempMax, wind, humidity, rainProbability, temperature, rainExpected),
    );
  }

  /// Chuva agora ou prevista para o dia: é o que o motor do IHE recebe como `is_raining`
  bool get isRainExpected =>
      conditionType == WeatherConditionType.lightRain ||
      conditionType == WeatherConditionType.rainy ||
      (rainProbability ?? 0) >= rainProbabilityThreshold;

  /// Temperatura formatada em graus Celsius (ex: "23°C")
  String get formattedTemperature => '${temperature.round()}°C';

  /// Intervalo térmico formatado (ex: "17° — 25°C")
  String get formattedMinMax => '${tempMin.round()}° — ${tempMax.round()}°C';

  /// Velocidade do vento formatada (ex: "14 km/h")
  String get formattedWind => '${windKmH.round()} km/h';

  /// Umidade relativa do ar formatada (ex: "65%")
  String get formattedHumidity => '$humidityPercentage%';

  String get windLabel => windKmH < 12 ? 'Brando' : (windKmH < 30 ? 'Moderado' : 'Forte');

  String get humidityLabel =>
      humidityPercentage < 40 ? 'Seco' : (humidityPercentage <= 70 ? 'Confortável' : 'Úmido');

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

  /// Códigos WMO usados pelo Open-Meteo
  static WeatherConditionType _typeForCode(int code) {
    if (code <= 1) return WeatherConditionType.sunny;
    if (code == 2) return WeatherConditionType.partlyCloudy;
    if ((code >= 51 && code <= 57) || code == 61 || code == 80) return WeatherConditionType.lightRain;
    if ((code >= 63 && code <= 67) || code == 81 || code == 82 || code >= 95) return WeatherConditionType.rainy;
    return WeatherConditionType.cloudy; // nublado, nevoeiro e neve
  }

  static String _labelForCode(int code) {
    return switch (code) {
      0 => 'Céu limpo',
      1 => 'Predominantemente limpo',
      2 => 'Parcialmente nublado',
      3 => 'Nublado',
      45 || 48 => 'Nevoeiro',
      51 || 53 || 55 => 'Garoa',
      56 || 57 => 'Garoa congelante',
      61 => 'Chuva fraca',
      63 => 'Chuva',
      65 => 'Chuva forte',
      66 || 67 => 'Chuva congelante',
      71 || 73 || 75 || 77 || 85 || 86 => 'Neve',
      80 => 'Pancadas fracas',
      81 => 'Pancadas de chuva',
      82 => 'Pancadas fortes',
      95 => 'Trovoada',
      96 || 99 => 'Trovoada com granizo',
      _ => 'Condição variável',
    };
  }

  static String _amplitudeLevel(double amplitude) =>
      amplitude < 6 ? 'Baixa' : (amplitude <= 10 ? 'Moderada' : 'Alta');

  static String _recommendation(double temperature, double amplitude, bool rainExpected) {
    if (rainExpected) return 'Chuva prevista: camadas e calçado fechado';
    if (temperature < 15) return 'Frio: camadas e tecidos encorpados';
    if (temperature > 25) return 'Calor: tecidos leves e respiráveis';
    if (amplitude > 10) return 'Amplitude alta: vista-se em camadas';
    return 'Clima ameno: peças de meia-estação';
  }

  static String _rationale(
    double tempMin,
    double tempMax,
    double wind,
    int humidity,
    int? rainProbability,
    double temperature,
    bool rainExpected,
  ) {
    final rain = rainProbability == null ? '' : ' e $rainProbability% de chance de chuva';
    final measured = 'Hoje entre ${tempMin.round()}°C e ${tempMax.round()}°C, '
        'com vento de ${wind.round()} km/h, $humidity% de umidade$rain.';
    final advice = rainExpected
        ? 'Prefira peças que tolerem chuva e evite tecidos muito leves.'
        : temperature < 15
            ? 'Prefira tecidos encorpados e sobreposições.'
            : temperature > 25
                ? 'Prefira tecidos leves e evite peças pesadas.'
                : 'Peças de meia-estação resolvem o dia.';
    return '$measured $advice';
  }
}
