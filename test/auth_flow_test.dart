import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/domain/models/account.dart';
import 'package:harmonia_mvp/domain/repositories/auth_repository.dart';
import 'package:harmonia_mvp/main.dart';
import 'package:harmonia_mvp/presentation/auth/auth_scope.dart';
import 'package:harmonia_mvp/presentation/screens/account_settings_screen.dart';
import 'package:harmonia_mvp/presentation/screens/auth_screen.dart';
import 'package:harmonia_mvp/presentation/screens/main_navigation_screen.dart';

import 'support/fake_auth_repository.dart';

Finder _field(String label) => find.ancestor(
      of: find.text(label.toUpperCase()),
      matching: find.byType(Column),
    ).first;

Future<void> _type(WidgetTester tester, String label, String value) async {
  await tester.enterText(find.descendant(of: _field(label), matching: find.byType(TextFormField)), value);
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  // O rótulo também pode nomear a aba do seletor; o botão vem por último
  final button = find.bySemanticsLabel(label).last;
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  Future<void> pumpApp(WidgetTester tester, FakeAuthRepository repo) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(HarmoniaApp(authRepository: repo));
    await tester.pumpAndSettle();
  }

  group('AuthScreen', () {
    testWidgets('sem sessão exibe a entrada de conta', (tester) async {
      await pumpApp(tester, FakeAuthRepository());
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(MainNavigationScreen), findsNothing);
    });

    testWidgets('valida campos antes de chamar o provedor', (tester) async {
      final repo = FakeAuthRepository();
      await pumpApp(tester, repo);

      await _tapButton(tester, 'Entrar');

      expect(find.text('Informe um e-mail válido.'), findsOneWidget);
      expect(find.text('Campo obrigatório.'), findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    testWidgets('cadastro exige consentimento LGPD e inicia sessão', (tester) async {
      final repo = FakeAuthRepository();
      await pumpApp(tester, repo);

      await tester.tap(find.text('Criar conta').first);
      await tester.pumpAndSettle();

      await _type(tester, 'Nome', 'Ana Lima');
      await _type(tester, 'E-mail', 'ana@harmonia.app');
      await _type(tester, 'Senha', 'atelie2026');
      await _type(tester, 'Confirmar senha', 'atelie2026');

      await _tapButton(tester, 'Criar conta');
      expect(find.textContaining('LGPD'), findsWidgets);
      expect(repo.calls, isEmpty);

      await tester.tap(find.bySemanticsLabel('Aceito o tratamento dos meus dados conforme a LGPD'));
      await tester.pump();
      await _tapButton(tester, 'Criar conta');

      expect(repo.calls, ['signUp']);
      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });

    testWidgets('cadastro com confirmação pendente volta ao login com aviso', (tester) async {
      final repo = FakeAuthRepository(requireEmailConfirmation: true);
      await pumpApp(tester, repo);

      await tester.tap(find.text('Criar conta').first);
      await tester.pumpAndSettle();
      await _type(tester, 'Nome', 'Ana Lima');
      await _type(tester, 'E-mail', 'ana@harmonia.app');
      await _type(tester, 'Senha', 'atelie2026');
      await _type(tester, 'Confirmar senha', 'atelie2026');
      await tester.tap(find.bySemanticsLabel('Aceito o tratamento dos meus dados conforme a LGPD'));
      await tester.pump();
      await _tapButton(tester, 'Criar conta');

      expect(find.textContaining('link de confirmação'), findsOneWidget);
      expect(find.byType(AuthScreen), findsOneWidget);
    });

    testWidgets('login com credenciais erradas exibe a falha', (tester) async {
      final repo = FakeAuthRepository();
      await pumpApp(tester, repo);

      await _type(tester, 'E-mail', 'ana@harmonia.app');
      await _type(tester, 'Senha', 'errada123');
      await _tapButton(tester, 'Entrar');

      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
      expect(find.byType(AuthScreen), findsOneWidget);
    });

    testWidgets('login válido abre o app', (tester) async {
      final account = Account(id: '1', email: 'ana@harmonia.app', fullName: 'Ana Lima');
      final repo = FakeAuthRepository(signedIn: account, password: 'atelie2026');
      await repo.signOut();
      repo.calls.clear();
      await pumpApp(tester, repo);

      await _type(tester, 'E-mail', 'ana@harmonia.app');
      await _type(tester, 'Senha', 'atelie2026');
      await _tapButton(tester, 'Entrar');

      expect(repo.calls, ['signIn']);
      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });
  });

  group('AccountSettingsScreen', () {
    final account = Account(id: '1', email: 'ana@harmonia.app', fullName: 'Ana Lima', createdAt: DateTime(2026, 3, 2));

    Future<FakeAuthRepository> pumpSettings(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final repo = FakeAuthRepository(signedIn: account);
      await tester.pumpWidget(
        AuthScope(
          repository: repo,
          child: const MaterialApp(home: AccountSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('exibe os dados da conta', (tester) async {
      await pumpSettings(tester);
      expect(find.text('Ana Lima'), findsWidgets);
      expect(find.text('ana@harmonia.app'), findsWidgets);
      expect(find.text('MEMBRO DESDE MAR 2026'), findsOneWidget);
    });

    testWidgets('atualiza o nome', (tester) async {
      final repo = await pumpSettings(tester);
      await _type(tester, 'Nome', 'Ana Lima Duarte');
      await tester.pump();
      await _tapButton(tester, 'Salvar alterações');

      expect(repo.calls, ['updateProfile']);
      expect(repo.currentAccount?.fullName, 'Ana Lima Duarte');
      expect(find.text('Dados atualizados.'), findsOneWidget);
    });

    testWidgets('senha nova precisa ser forte e confirmada', (tester) async {
      final repo = await pumpSettings(tester);
      await _type(tester, 'Nova senha', 'curta');
      await _tapButton(tester, 'Atualizar senha');
      expect(find.text('Use ao menos 8 caracteres.'), findsOneWidget);

      await _type(tester, 'Nova senha', 'novasenha9');
      await _type(tester, 'Confirmar nova senha', 'novasenha9');
      await _tapButton(tester, 'Atualizar senha');
      expect(repo.calls, ['updatePassword']);
      expect(find.text('Senha atualizada.'), findsOneWidget);
    });

    testWidgets('exclusão exige digitar a confirmação', (tester) async {
      final repo = await pumpSettings(tester);
      await _tapButton(tester, 'Excluir conta');
      expect(find.text('Excluir sua conta?'), findsOneWidget);

      await _tapButton(tester, 'Excluir definitivamente');
      expect(repo.calls, isEmpty);

      await tester.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(TextFormField)), 'excluir');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Excluir definitivamente'));
      // Isolada, a tela segue em espera: no app o AuthGate a substitui
      await tester.pump(const Duration(milliseconds: 500));

      expect(repo.calls, ['deleteAccount']);
      expect(repo.currentAccount, isNull);
    });

    testWidgets('falha na exclusão mantém a conta e informa', (tester) async {
      final repo = await pumpSettings(tester);
      repo.nextFailure = const AuthFailure('Não foi possível concluir a operação na sua conta.');
      await _tapButton(tester, 'Excluir conta');
      await tester.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(TextFormField)), 'EXCLUIR');
      await tester.pump();
      await _tapButton(tester, 'Excluir definitivamente');

      expect(find.text('Não foi possível concluir a operação na sua conta.'), findsOneWidget);
      expect(repo.currentAccount, isNotNull);
    });
  });

  testWidgets('encerrar sessão pelo Ateliê retorna à entrada', (tester) async {
    final repo = FakeAuthRepository(signedIn: const Account(id: '1', email: 'ana@harmonia.app', fullName: 'Ana Lima'));
    await pumpApp(tester, repo);

    await tester.tap(find.byTooltip('Ateliê'));
    await tester.pumpAndSettle();
    expect(find.text('Ana Lima'), findsOneWidget);

    await tester.tap(find.text('Conta & Segurança'));
    await tester.pumpAndSettle();
    await _tapButton(tester, 'Encerrar sessão');

    expect(repo.calls, contains('signOut'));
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(AccountSettingsScreen), findsNothing);
  });
}
