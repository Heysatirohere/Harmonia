import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/domain/repositories/style_profile_repository.dart';
import 'package:harmonia_mvp/models/user_style_profile.dart';
import 'package:harmonia_mvp/presentation/profile/style_profile_scope.dart';
import 'package:harmonia_mvp/presentation/screens/profile_screen.dart';

import 'support/fake_style_profile_repository.dart';

void main() {
  Future<void> pumpProfile(WidgetTester tester, FakeStyleProfileRepository repo) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      StyleProfileScope(
        repository: repo,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('exibe o perfil salvo, a cota e as ações de recalibração', (tester) async {
    await pumpProfile(tester, FakeStyleProfileRepository.completed());

    expect(find.text('ATELIÊ & PERFIL'), findsOneWidget);
    expect(find.text('Ampulheta'), findsOneWidget);
    expect(find.text('Outono Quente'), findsOneWidget);
    expect(find.text('SAÚDE DA ASSINATURA (RN02)'), findsOneWidget);
    expect(find.text('Recalibrar Colorimetria'), findsOneWidget);
    expect(find.text('Ajustar Biótipo Corporal'), findsOneWidget);
  });

  testWidgets('ajustar o biótipo salva no repositório', (tester) async {
    final repo = FakeStyleProfileRepository.completed();
    await pumpProfile(tester, repo);

    await tester.tap(find.text('Ajustar Biótipo Corporal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oval'));
    await tester.pumpAndSettle();

    expect(repo.calls, contains('update'));
    expect(repo.profile.silhouette, BodySilhouetteType.oval);
    expect(find.text('Biótipo atualizado para Oval.'), findsOneWidget);
  });

  testWidgets('falha ao carregar mostra aviso e permite tentar de novo', (tester) async {
    final repo = FakeStyleProfileRepository.completed()
      ..nextFailure = const StyleProfileFailure('Não foi possível conectar ao ateliê.');
    await pumpProfile(tester, repo);

    expect(find.text('Não foi possível conectar ao ateliê.'), findsOneWidget);
    expect(find.text('SAÚDE DA ASSINATURA (RN02)'), findsNothing);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(find.text('Ampulheta'), findsOneWidget);
  });
}
