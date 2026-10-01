import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/data/services/outfit_api_service.dart';
import 'package:harmonia_mvp/domain/repositories/weather_repository.dart';
import 'package:harmonia_mvp/mocks/mock_clothes.dart';
import 'package:harmonia_mvp/models/weather_context.dart';
import 'package:harmonia_mvp/presentation/screens/daily_outfit_screen.dart';
import 'package:harmonia_mvp/presentation/widgets/weather_context_badge.dart';

import 'support/fake_outfit_service.dart';
import 'support/fake_weather_repository.dart';
import 'support/sample_weather.dart';

void main() {
  group('WeatherContext Model Tests', () {
    test('WeatherContext formats telemetry correctly', () {
      const weather = WeatherContext(
        city: 'Rio de Janeiro, RJ',
        temperature: 28.4,
        tempMin: 22.0,
        tempMax: 30.0,
        conditionType: WeatherConditionType.sunny,
        conditionLabel: 'Ensolarado',
        windKmH: 18.2,
        humidityPercentage: 70,
        thermalAmplitudeLabel: 'Baixa (8°C)',
        recommendationBadge: 'Tecidos leves em algodão e linho',
        sOcasionRationale: 'Clima quente exige fibras naturais de alta respirabilidade.',
      );

      expect(weather.formattedTemperature, '28°C');
      expect(weather.formattedMinMax, '22° — 30°C');
      expect(weather.formattedWind, '18 km/h');
      expect(weather.formattedHumidity, '70%');
      expect(weather.iconData, Icons.wb_sunny_outlined);
    });

    test('lê a resposta do Open-Meteo e deriva os rótulos só dos números', () {
      final weather = WeatherContext.fromOpenMeteo({
        'current': {'temperature_2m': 23.4, 'relative_humidity_2m': 64, 'weather_code': 2, 'wind_speed_10m': 13.8},
        'daily': {
          'temperature_2m_max': [26.1],
          'temperature_2m_min': [15.2],
          'precipitation_probability_max': [20],
        },
      }, city: 'São Paulo, SP');

      expect(weather.formattedTemperature, '23°C');
      expect(weather.formattedMinMax, '15° — 26°C');
      expect(weather.conditionType, WeatherConditionType.partlyCloudy);
      expect(weather.conditionLabel, 'Parcialmente nublado');
      expect(weather.isRainExpected, isFalse);
      expect(weather.thermalAmplitudeLabel, 'Alta (11°C)');
      expect(weather.recommendationBadge, 'Amplitude alta: vista-se em camadas');
      expect(weather.windLabel, 'Moderado');
      expect(weather.humidityLabel, 'Confortável');
      expect(weather.sOcasionRationale, contains('20% de chance de chuva'));
    });

    test('previsão de chuva do dia conta como chuva para o motor', () {
      final weather = WeatherContext.fromOpenMeteo({
        'current': {'temperature_2m': 19.0, 'relative_humidity_2m': 80, 'weather_code': 3, 'wind_speed_10m': 8.0},
        'daily': {
          'temperature_2m_max': [21.0],
          'temperature_2m_min': [17.0],
          'precipitation_probability_max': [70],
        },
      }, city: 'Curitiba, PR');

      expect(weather.conditionType, WeatherConditionType.cloudy);
      expect(weather.isRainExpected, isTrue);
      expect(weather.recommendationBadge, startsWith('Chuva prevista'));
    });

    test('vento forte sem chuva vira condição de vento; chuva forte continua chuva', () {
      Map<String, dynamic> response(int code, double wind) => {
            'current': {'temperature_2m': 20.0, 'relative_humidity_2m': 50, 'weather_code': code, 'wind_speed_10m': wind},
            'daily': {
              'temperature_2m_max': [22.0],
              'temperature_2m_min': [18.0],
              'precipitation_probability_max': [null],
            },
          };

      final windy = WeatherContext.fromOpenMeteo(response(0, 35), city: 'X');
      final storm = WeatherContext.fromOpenMeteo(response(65, 35), city: 'X');

      expect(windy.conditionType, WeatherConditionType.breezy);
      expect(windy.rainProbability, isNull);
      expect(storm.conditionType, WeatherConditionType.rainy);
      expect(storm.isRainExpected, isTrue);
    });
  });

  group('WeatherContextBadge Widget Tests', () {
    testWidgets('renders telemetry data and recommendation badge accurately', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: const WeatherContextBadge(weatherContext: sampleWeather),
            ),
          ),
        ),
      );

      // Verifica exibição de Cidade, Condição e Temperatura
      expect(find.text('SÃO PAULO, SP'), findsOneWidget);
      expect(find.text('PARCIALMENTE NUBLADO'), findsOneWidget);
      expect(find.text('23°C'), findsOneWidget);

      // Verifica o badge de recomendação contextual
      expect(find.text('Clima ameno: peças de meia-estação'), findsOneWidget);
    });

    testWidgets('tap triggers selection haptic and opens S_ocasion details sheet', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: WeatherContextBadge(
                weatherContext: sampleWeather,
                sOcasionScore: 0.88,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      // Toque no badge de clima
      await tester.tap(find.byType(WeatherContextBadge));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);

      // Verifica se a Bottom Sheet abriu com as variáveis de clima e S_ocasion
      expect(find.text('CONTEXTO METEOROLÓGICO'), findsOneWidget);
      expect(find.text('Variáveis do S_ocasion'), findsOneWidget);
      expect(find.text('88%'), findsOneWidget);
      expect(find.text('RECOMENDAÇÃO EDITORIAL DE CAMADAS'), findsOneWidget);

      // Fecha o modal clicando em Entendido
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      expect(find.text('CONTEXTO METEOROLÓGICO'), findsNothing);
    });
  });

  group('DailyOutfitScreen Integration Tests', () {
    Future<FakeOutfitService> pumpDaily(WidgetTester tester, FakeOutfitService service, {FakeWeatherRepository? weather}) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(MaterialApp(
        home: DailyOutfitScreen(service: service, weatherRepository: weather ?? FakeWeatherRepository()),
      ));
      await tester.pumpAndSettle();
      return service;
    }

    testWidgets('mostra o look gerado com o IHE e o clima', (WidgetTester tester) async {
      await pumpDaily(tester, FakeOutfitService.sample());

      expect(find.text('Look do Dia'), findsOneWidget);
      expect(find.textContaining('CURADORIA •'), findsOneWidget, reason: 'data do dia, não mais fixa');
      expect(find.byType(WeatherContextBadge), findsOneWidget);

      expect(find.text(mockClothes[0].name, skipOffstage: false), findsOneWidget);
      expect(find.text('88%', findRichText: true, skipOffstage: false), findsOneWidget);
      expect(find.text('LOOK FORTEMENTE RECOMENDADO', skipOffstage: false), findsOneWidget);
      expect(find.text('Tons terrosos em diálogo com a sua cartela.', skipOffstage: false), findsOneWidget);
      expect(find.text('Aprovar look do dia', skipOffstage: false), findsOneWidget);
      expect(find.text('Simular no provador', skipOffstage: false), findsOneWidget);
    });

    testWidgets('outra sugestão percorre os looks sem nova consulta', (WidgetTester tester) async {
      final service = await pumpDaily(tester, FakeOutfitService.sample());

      await tester.ensureVisible(find.text('Outra sugestão (1/2)'));
      await tester.tap(find.text('Outra sugestão (1/2)'));
      await tester.pumpAndSettle();

      expect(find.text('64%', findRichText: true, skipOffstage: false), findsOneWidget);
      expect(find.text('LOOK FORTEMENTE RECOMENDADO', skipOffstage: false), findsNothing);
      expect(service.occasions, ['CASUAL']);
    });

    testWidgets('trocar a ocasião pede novos looks ao motor', (WidgetTester tester) async {
      final service = await pumpDaily(tester, FakeOutfitService.sample());

      await tester.tap(find.text('Trabalho'));
      await tester.pumpAndSettle();

      expect(service.occasions, ['CASUAL', 'TRABALHO']);
    });

    testWidgets('acervo que não forma look orienta a digitalizar peças', (WidgetTester tester) async {
      await pumpDaily(tester, FakeOutfitService(const []));

      expect(find.text('Seu acervo ainda não forma um look'), findsOneWidget);
      expect(find.text('Aprovar look do dia', skipOffstage: false), findsNothing);
    });

    testWidgets('cota esgotada informa e não oferece nova tentativa', (WidgetTester tester) async {
      await pumpDaily(
        tester,
        FakeOutfitService(const [], failure: const OutfitException('Cota esgotada hoje.', isQuotaExceeded: true)),
      );

      expect(find.text('Cota de hoje esgotada'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('falha de conexão permite tentar de novo', (WidgetTester tester) async {
      await pumpDaily(
        tester,
        FakeOutfitService.sample()..failure = const OutfitException('Não foi possível conectar ao ateliê.'),
      );

      expect(find.text('O ateliê não respondeu'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(find.text('LOOK FORTEMENTE RECOMENDADO', skipOffstage: false), findsOneWidget);
    });

    testWidgets('aprovar o look muda o estado e confirma', (WidgetTester tester) async {
      await pumpDaily(tester, FakeOutfitService.sample());

      await tester.ensureVisible(find.text('Aprovar look do dia'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aprovar look do dia'));
      await tester.pumpAndSettle();

      expect(find.text('Look aprovado'), findsOneWidget);
      expect(find.text('Look do dia aprovado.'), findsOneWidget);
    });

    testWidgets('o clima local vai para o motor de looks', (WidgetTester tester) async {
      final rainy = WeatherContext.fromOpenMeteo({
        'current': {'temperature_2m': 13.6, 'relative_humidity_2m': 88, 'weather_code': 61, 'wind_speed_10m': 9.0},
        'daily': {
          'temperature_2m_max': [16.0],
          'temperature_2m_min': [11.0],
          'precipitation_probability_max': [90],
        },
      }, city: 'Porto Alegre, RS');
      final service = await pumpDaily(
        tester,
        FakeOutfitService.sample(),
        weather: FakeWeatherRepository(weather: rainy),
      );

      expect(service.climates.single, (temperature: 13.6, isRaining: true));
      expect(find.text('PORTO ALEGRE, RS'), findsOneWidget);
    });

    testWidgets('sem localização os looks usam clima neutro e a tela explica', (WidgetTester tester) async {
      final weather = FakeWeatherRepository(
        failure: const WeatherFailure(
          WeatherFailureKind.permissionDenied,
          'Sem permissão de localização, os looks não consideram o clima.',
        ),
      );
      final service = await pumpDaily(tester, FakeOutfitService.sample(), weather: weather);

      expect(service.climates.single, (temperature: 22.0, isRaining: false));
      expect(find.text('Sem permissão de localização, os looks não consideram o clima.'), findsOneWidget);
      expect(find.byType(WeatherContextBadge), findsNothing);

      await tester.tap(find.text('Permitir localização'));
      await tester.pumpAndSettle();

      expect(weather.resolved, [WeatherFailureKind.permissionDenied]);
      expect(find.byType(WeatherContextBadge), findsOneWidget);
      expect(service.climates.last, (temperature: 23.0, isRaining: false));
    });
  });
}
