import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/mocks/mock_weather.dart';
import 'package:harmonia_mvp/models/weather_context.dart';
import 'package:harmonia_mvp/presentation/screens/daily_outfit_screen.dart';
import 'package:harmonia_mvp/presentation/widgets/weather_context_badge.dart';

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
        sOcasionScore: 0.95,
        sOcasionRationale: 'Clima quente exige fibras naturais de alta respirabilidade.',
      );

      expect(weather.formattedTemperature, '28°C');
      expect(weather.formattedMinMax, '22° — 30°C');
      expect(weather.formattedWind, '18 km/h');
      expect(weather.formattedHumidity, '70%');
      expect(weather.formattedScore, '95%');
      expect(weather.iconData, Icons.wb_sunny_outlined);
    });

    test('MockWeather provides valid current telemetry', () {
      final mock = MockWeather.current;
      expect(mock.city, 'SÃO PAULO, SP');
      expect(mock.formattedTemperature, '23°C');
      expect(mock.conditionLabel, 'PARCIALMENTE ENSOLARADO');
      expect(mock.sOcasionScore, 0.88);
    });
  });

  group('WeatherContextBadge Widget Tests', () {
    testWidgets('renders telemetry data and recommendation badge accurately', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: WeatherContextBadge(weatherContext: MockWeather.current),
            ),
          ),
        ),
      );

      // Verifica exibição de Cidade, Condição e Temperatura
      expect(find.text('SÃO PAULO, SP'), findsOneWidget);
      expect(find.text('PARCIALMENTE ENSOLARADO'), findsOneWidget);
      expect(find.text('23°C'), findsOneWidget);

      // Verifica o badge de recomendação contextual
      expect(find.text('Adequado para amplitude térmica moderada'), findsOneWidget);
    });

    testWidgets('tap triggers selection haptic and opens S_ocasion details sheet', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: WeatherContextBadge(
                weatherContext: MockWeather.current,
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
    testWidgets('renders DailyOutfitScreen with top weather badge and outfit components', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DailyOutfitScreen(),
        ),
      );

      // Header e Título
      expect(find.text('Sugestão Diária'), findsOneWidget);
      expect(find.text('CURADORIA HARMONIA • 27 SETEMBRO'), findsOneWidget);

      // WeatherContextBadge no topo
      expect(find.byType(WeatherContextBadge), findsOneWidget);

      // Elementos do Look
      expect(find.text('LOOK FORTEMENTE RECOMENDADO'), findsOneWidget);
      expect(find.text('Sobreposição Terracota em Linho Cru'), findsOneWidget);
      expect(find.text('Blazer Desestruturado em Linho'), findsOneWidget);

      // Botões de Ação 3 Toques
      expect(find.text('Aprovar Look do Dia'), findsOneWidget);
      expect(find.text('Simular no Provador (Mirror Mode)'), findsOneWidget);
    });

    testWidgets('approving look changes state and displays feedback snackbar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DailyOutfitScreen(),
        ),
      );

      // Clica em 'Aprovar Look do Dia'
      await tester.tap(find.text('Aprovar Look do Dia'));
      await tester.pumpAndSettle();

      expect(find.text('Look Aprovado'), findsOneWidget);
      expect(find.text('Look do dia registrado no seu acervo!'), findsOneWidget);
    });
  });
}
