import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_scope.dart';
import '../widgets/editorial_form.dart';

enum _AuthMode { signIn, signUp }

/// Entrada editorial do HarmonIA: login e cadastro de conta (RF01, RNF01)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  bool _consentGiven = false;
  bool _isLoading = false;
  String? _error;
  String? _success;

  bool get _isSignUp => _mode == _AuthMode.signUp;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    if (_mode == mode || _isLoading) return;
    HapticFeedback.selectionClick();
    _formKey.currentState?.reset();
    setState(() {
      _mode = mode;
      _error = null;
      _success = null;
      _passwordController.clear();
      _confirmController.clear();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _success = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSignUp && !_consentGiven) {
      setState(() => _error = 'Para criar a conta, aceite o tratamento dos seus dados (LGPD).');
      return;
    }

    final auth = AuthScope.of(context);
    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        final outcome = await auth.signUp(
          fullName: _nameController.text.trim(),
          email: email,
          password: _passwordController.text,
        );
        if (outcome == SignUpOutcome.confirmationPending && mounted) {
          HapticFeedback.mediumImpact();
          setState(() {
            _mode = _AuthMode.signIn;
            _passwordController.clear();
            _confirmController.clear();
            _success = 'Conta criada. Enviamos um link de confirmação para $email.';
          });
        }
      } else {
        await auth.signIn(email: email, password: _passwordController.text);
      }
      // Com sessão ativa, o AuthGate troca a tela automaticamente
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (AccountValidators.email(email) != null) {
      setState(() {
        _success = null;
        _error = 'Informe seu e-mail acima para receber o link de redefinição.';
      });
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _error = null;
      _isLoading = true;
    });
    try {
      await AuthScope.of(context).sendPasswordReset(email);
      if (mounted) setState(() => _success = 'Se houver conta para $email, o link de redefinição chegará em instantes.');
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMasthead(),
                      const SizedBox(height: 40),
                      _ModeSwitch(mode: _mode, onChanged: _switchMode),
                      const SizedBox(height: 28),
                      if (_error != null) ...[
                        FormNotice(message: _error!),
                        const SizedBox(height: AppSpacing.elementGap),
                      ],
                      if (_success != null) ...[
                        FormNotice(message: _success!, tone: FormNoticeTone.success),
                        const SizedBox(height: AppSpacing.elementGap),
                      ],
                      _buildFields(),
                      const SizedBox(height: 28),
                      EditorialButton(
                        label: _isSignUp ? 'Criar conta' : 'Entrar',
                        isLoading: _isLoading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMasthead() {
    return Column(
      children: [
        Text(
          'ATELIÊ DIGITAL',
          textAlign: TextAlign.center,
          style: AppTypography.metadataBadge(color: AppColors.iheGold).copyWith(letterSpacing: 2.4),
        ),
        const SizedBox(height: 12),
        Text(
          'HarmonIA',
          textAlign: TextAlign.center,
          style: AppTypography.displayEditorial().copyWith(fontSize: 40),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: AppMotion.medium,
          switchInCurve: AppMotion.editorialDecel,
          child: Text(
            _isSignUp ? 'Seu acervo, curado desde o primeiro dia.' : 'Que bom ter você de volta ao seu acervo.',
            key: ValueKey(_mode),
            textAlign: TextAlign.center,
            style: AppTypography.subtitleCuratorial(),
          ),
        ),
      ],
    );
  }

  Widget _buildFields() {
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.editorialDecel,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isSignUp) ...[
            EditorialTextField(
              key: const ValueKey('field-name'),
              label: 'Nome',
              controller: _nameController,
              hint: 'Como devemos chamar você',
              autofillHints: const [AutofillHints.name],
              validator: AccountValidators.name,
              enabled: !_isLoading,
            ),
            const SizedBox(height: AppSpacing.elementGap),
          ],
          EditorialTextField(
            key: const ValueKey('field-email'),
            label: 'E-mail',
            controller: _emailController,
            hint: 'voce@exemplo.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: AccountValidators.email,
            enabled: !_isLoading,
          ),
          const SizedBox(height: AppSpacing.elementGap),
          EditorialTextField(
            key: const ValueKey('field-password'),
            label: 'Senha',
            controller: _passwordController,
            obscure: true,
            autofillHints: [_isSignUp ? AutofillHints.newPassword : AutofillHints.password],
            textInputAction: _isSignUp ? TextInputAction.next : TextInputAction.done,
            validator: _isSignUp ? AccountValidators.newPassword : AccountValidators.required,
            onSubmitted: _isSignUp ? null : (_) => _submit(),
            enabled: !_isLoading,
          ),
          if (_isSignUp) ...[
            const SizedBox(height: AppSpacing.elementGap),
            EditorialTextField(
              key: const ValueKey('field-confirm'),
              label: 'Confirmar senha',
              controller: _confirmController,
              obscure: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              validator: (value) => value != _passwordController.text ? 'As senhas não coincidem.' : null,
              onSubmitted: (_) => _submit(),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 20),
            _ConsentToggle(
              value: _consentGiven,
              onChanged: (value) => setState(() => _consentGiven = value),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _isLoading ? null : _resetPassword,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Esqueci minha senha',
                    style: AppTypography.bodySmall(color: AppColors.textPrimary).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Alternância Entrar / Criar conta com sublinhado capilar deslizante
class _ModeSwitch extends StatelessWidget {
  final _AuthMode mode;
  final ValueChanged<_AuthMode> onChanged;

  const _ModeSwitch({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 0.8)),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              _tab('Entrar', _AuthMode.signIn),
              _tab('Criar conta', _AuthMode.signUp),
            ],
          ),
          Positioned.fill(
            child: AnimatedAlign(
              duration: AppMotion.medium,
              curve: AppMotion.editorialDecel,
              alignment: mode == _AuthMode.signIn ? Alignment.bottomLeft : Alignment.bottomRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(height: 1.2, color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, _AuthMode value) {
    final selected = mode == value;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: GestureDetector(
          onTap: () => onChanged(value),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: AnimatedDefaultTextStyle(
              duration: AppMotion.fast,
              curve: AppMotion.editorialDecel,
              style: AppTypography.uiHeadline(
                color: selected ? AppColors.textPrimary : AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

/// Consentimento explícito LGPD no primeiro acesso (RNF01)
class _ConsentToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ConsentToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: 'Aceito o tratamento dos meus dados conforme a LGPD',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        behavior: HitTestBehavior.opaque,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.editorialDecel,
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: value ? AppColors.textPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: value ? AppColors.textPrimary : AppColors.textMuted,
                  width: 1,
                ),
              ),
              child: value ? const Icon(Icons.check, size: 12, color: AppColors.surfaceCanvas) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aceito o tratamento dos meus dados (fotos, biótipo e colorimetria) conforme a LGPD, '
                'com opção de exclusão definitiva a qualquer momento.',
                style: AppTypography.bodySmall(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
