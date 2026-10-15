import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/domain/models/colorimetry_result.dart';
import 'package:harmonia_mvp/models/user_style_profile.dart';
import 'package:harmonia_mvp/presentation/profile/style_profile_scope.dart';
import 'package:harmonia_mvp/presentation/screens/onboarding_profile_screen.dart';

import 'support/fake_style_profile_repository.dart';

final _selfie = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

const _warmLight = ColorimetryResult(
  palette: SeasonalPaletteType.primaveraQuente,
  skinColor: Color(0xFFF2CCAA),
  undertone: 'QUENTE',
  depth: 'CLARA',
  intensity: 'BRILHANTE',
);

Future<void> tapButton(WidgetTester tester, String label) async {
  final button = find.text(label);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<FakeStyleProfileRepository> pumpColorimetryStep(WidgetTester tester, {ColorimetryResult? result}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  final profiles = FakeStyleProfileRepository()..colorimetry = result;
  await tester.pumpWidget(MaterialApp(
    home: StyleProfileScope(
      repository: profiles,
      child: OnboardingProfileScreen(captureSelfie: (source) async => (bytes: _selfie, name: 'selfie.jpg')),
    ),
  ));
  await tapButton(tester, 'Iniciar Consultoria');
  await tapButton(tester, 'Avançar');
  return profiles;
}

void main() {
  test('ColorimetryResult lê a resposta da API e resume em palavras', () {
    final result = ColorimetryResult.fromJson({
      'palette': 'OUTONO_SUAVE',
      'skin_hex': '#C99A7A',
      'L': 66.0, 'a': 12.0, 'b': 20.0, 'hue': 59.0, 'chroma': 23.3, 'contrast': 20.0,
      'undertone': 'QUENTE',
      'depth': 'MEDIA',
      'intensity': 'SUAVE',
    });

    expect(result.palette, SeasonalPaletteType.outonoSuave);
    expect(result.skinColor, const Color(0xFFC99A7A));
    expect(result.summary, 'Subtom quente · coloração média · suave');
  });

  testWidgets('a selfie sugere a cartela e explica o porquê (RF02)', (tester) async {
    final profiles = await pumpColorimetryStep(tester, result: _warmLight);

    await tapButton(tester, 'Analisar com selfie');

    expect(profiles.calls, contains('analyzeSelfie'));
    expect(find.textContaining('Subtom quente · coloração clara · brilhante'), findsOneWidget);
    expect(find.text(SeasonalPaletteType.primaveraQuente.displayName), findsWidgets);
    expect(find.text('Refazer a selfie'), findsOneWidget);
  });

  testWidgets('rosto fora do oval explica o que refazer e mantém a escolha manual', (tester) async {
    await pumpColorimetryStep(tester);

    await tapButton(tester, 'Analisar com selfie');

    expect(find.text('Não encontramos o rosto no centro da foto.'), findsOneWidget);
    expect(find.text(SeasonalPaletteType.outonoQuente.displayName), findsWidgets);
  });
}
