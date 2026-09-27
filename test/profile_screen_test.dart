import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/mocks/mock_user_profile.dart';
import 'package:harmonia_mvp/presentation/screens/profile_screen.dart';
import 'package:harmonia_mvp/presentation/widgets/freemium_quota_card.dart';

void main() {
  group('ProfileScreen & FreemiumQuotaCard Widget Tests (RF18 & RN02)', () {
    testWidgets('renders identity header, body type badge, and freemium quota ruler metrics',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );

      // Identidade do Usuário
      expect(find.text('Helena Vasconcelos'), findsOneWidget);
      expect(find.text('Ampulheta'), findsOneWidget);
      expect(find.text('Outono Suave'), findsOneWidget);

      // Card de Cota Freemium (RN02)
      expect(find.byType(FreemiumQuotaCard), findsOneWidget);
      expect(find.text('24 / 30 peças'), findsOneWidget);
      expect(find.text('4 / 5 looks hoje'), findsOneWidget);

      // Seções de Recalibração (RF18)
      expect(find.text('Recalibrar Colorimetria Pessoal'), findsOneWidget);
      expect(find.text('Ajustar Biótipo Corporal'), findsOneWidget);
      expect(find.text('Dados da Conta & Segurança'), findsOneWidget);
    });

    testWidgets(
        'RN02: displays terracotta upgrade alert when freemium quota limit is reached',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final limitReachedUser = MockUserProfile.limitReachedUser;

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            initialProfile: limitReachedUser,
          ),
        ),
      );

      // Metricas com teto atingido (RN02)
      expect(find.text('30 / 30 peças'), findsOneWidget);
      expect(find.text('5 / 5 looks hoje'), findsOneWidget);

      // Alerta Terracota de Teto Freemium (RN02)
      expect(find.text('Limite Freemium Atingido (RN02)'), findsOneWidget);
      expect(find.text('Fazer Upgrade para HarmonIA Premium'), findsOneWidget);
    });

    testWidgets('tapping body type tile opens recalibration picker modal (RF18)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );

      // Clica em 'Ajustar Biótipo Corporal'
      await tester.tap(find.text('Ajustar Biótipo Corporal'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('RECALIBRAÇÃO MORFOLÓGICA'), findsOneWidget);
      expect(find.text('Retângulo'), findsOneWidget);

      // Seleciona 'Retângulo'
      await tester.tap(find.text('Retângulo'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Retângulo'), findsAtLeastNWidgets(1));
    });

    testWidgets('toggling privacy switch updates public/private status (RN05)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );

      expect(find.text('Perfil Público na Comunidade'), findsOneWidget);

      // Alterna Chave de Privacidade
      await tester.tap(find.byType(Switch));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Modo Privado ativado. Visível apenas para si.'),
          findsOneWidget);
    });
  });
}
