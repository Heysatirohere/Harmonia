import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_scope.dart';
import '../widgets/editorial_form.dart';

/// Dados da conta & segurança (RF18): leitura, edição, troca de senha,
/// encerramento de sessão e exclusão definitiva (RN04).
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

enum _Busy { none, profile, password, signOut, delete }

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  late AuthRepository _auth;
  Account? _account;
  _Busy _busy = _Busy.none;

  String? _profileError;
  String? _profileSuccess;
  String? _passwordError;
  String? _passwordSuccess;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _auth = AuthScope.of(context);
    if (_account == null) _loadAccount();
  }

  void _loadAccount() {
    _account = _auth.currentAccount;
    _nameController.text = _account?.fullName ?? '';
    _emailController.text = _account?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isBusy => _busy != _Busy.none;

  bool get _profileDirty {
    final account = _account;
    if (account == null) return false;
    return _nameController.text.trim() != (account.fullName ?? '') ||
        _emailController.text.trim() != account.email;
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _profileError = null;
      _profileSuccess = null;
    });
    if (!(_profileFormKey.currentState?.validate() ?? false)) return;

    final account = _account!;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    setState(() => _busy = _Busy.profile);
    try {
      final pendingEmail = await _auth.updateProfile(
        fullName: name != (account.fullName ?? '') ? name : null,
        email: email != account.email ? email : null,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _account = _auth.currentAccount ?? account.copyWith(fullName: name);
        _emailController.text = _account!.email;
        _profileSuccess = pendingEmail
            ? 'Nome salvo. Confirme a troca pelo link enviado para $email.'
            : 'Dados atualizados.';
      });
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _profileError = e.message);
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  Future<void> _savePassword() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _passwordError = null;
      _passwordSuccess = null;
    });
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = _Busy.password);
    try {
      await _auth.updatePassword(_passwordController.text);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _passwordFormKey.currentState?.reset();
      _passwordController.clear();
      _confirmController.clear();
      setState(() => _passwordSuccess = 'Senha atualizada.');
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _passwordError = e.message);
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = _Busy.signOut);
    await _auth.signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.32),
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = _Busy.delete);
    try {
      await _auth.deleteAccount();
      HapticFeedback.heavyImpact();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _busy = _Busy.none);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          content: Text(e.message, style: AppTypography.bodyReading(color: AppColors.surfaceCanvas)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCanvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('Conta & Segurança', style: AppTypography.editorialTitleMedium()),
      ),
      body: account == null
          ? _buildUnavailable()
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin, 8, AppSpacing.pageMargin, 48),
              children: [
                _buildIdentity(account),
                const SizedBox(height: 36),
                _buildProfileSection(),
                const SizedBox(height: 40),
                _buildPasswordSection(),
                const SizedBox(height: 40),
                const _SectionLabel('Sessão'),
                const SizedBox(height: AppSpacing.elementGap),
                EditorialButton(
                  label: 'Encerrar sessão',
                  tone: EditorialButtonTone.outline,
                  isLoading: _busy == _Busy.signOut,
                  onPressed: _isBusy ? null : _signOut,
                ),
                const SizedBox(height: 40),
                _buildDangerZone(),
              ],
            ),
    );
  }

  Widget _buildUnavailable() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pageMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nenhuma sessão ativa', style: AppTypography.subtitleCuratorial(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.tightGap),
          Text(
            'O serviço de conta está indisponível neste ambiente. '
            'Conecte-se à internet e entre novamente para editar seus dados.',
            style: AppTypography.bodyReading(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentity(Account account) {
    final since = account.createdAt;
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderGold, width: 0.8),
          ),
          child: Text(account.monogram, style: AppTypography.iheMetric()),
        ),
        const SizedBox(width: AppSpacing.elementGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(account.displayName, style: AppTypography.editorialTitleSmall()),
              const SizedBox(height: 2),
              Text(account.email, style: AppTypography.bodySmall()),
              if (since != null) ...[
                const SizedBox(height: 6),
                Text(
                  'MEMBRO DESDE ${_monthYear(since)}',
                  style: AppTypography.metadataBadge(color: AppColors.textMuted).copyWith(fontSize: 9.5),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Form(
      key: _profileFormKey,
      onChanged: () => setState(() {}),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Dados pessoais'),
          const SizedBox(height: AppSpacing.elementGap),
          if (_profileError != null) ...[
            FormNotice(message: _profileError!),
            const SizedBox(height: AppSpacing.elementGap),
          ],
          if (_profileSuccess != null) ...[
            FormNotice(message: _profileSuccess!, tone: FormNoticeTone.success),
            const SizedBox(height: AppSpacing.elementGap),
          ],
          EditorialTextField(
            label: 'Nome',
            controller: _nameController,
            autofillHints: const [AutofillHints.name],
            validator: AccountValidators.name,
            enabled: !_isBusy,
          ),
          const SizedBox(height: AppSpacing.elementGap),
          EditorialTextField(
            label: 'E-mail',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: AccountValidators.email,
            enabled: !_isBusy,
          ),
          const SizedBox(height: 20),
          EditorialButton(
            label: 'Salvar alterações',
            isLoading: _busy == _Busy.profile,
            onPressed: _profileDirty && !_isBusy ? _saveProfile : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Senha'),
          const SizedBox(height: AppSpacing.elementGap),
          if (_passwordError != null) ...[
            FormNotice(message: _passwordError!),
            const SizedBox(height: AppSpacing.elementGap),
          ],
          if (_passwordSuccess != null) ...[
            FormNotice(message: _passwordSuccess!, tone: FormNoticeTone.success),
            const SizedBox(height: AppSpacing.elementGap),
          ],
          EditorialTextField(
            label: 'Nova senha',
            controller: _passwordController,
            obscure: true,
            autofillHints: const [AutofillHints.newPassword],
            validator: AccountValidators.newPassword,
            enabled: !_isBusy,
          ),
          const SizedBox(height: AppSpacing.elementGap),
          EditorialTextField(
            label: 'Confirmar nova senha',
            controller: _confirmController,
            obscure: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            validator: (value) => value != _passwordController.text ? 'As senhas não coincidem.' : null,
            onSubmitted: (_) => _savePassword(),
            enabled: !_isBusy,
          ),
          const SizedBox(height: 20),
          EditorialButton(
            label: 'Atualizar senha',
            tone: EditorialButtonTone.outline,
            isLoading: _busy == _Busy.password,
            onPressed: _isBusy ? null : _savePassword,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.accentTerracotta.withValues(alpha: 0.28), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'EXCLUSÃO DEFINITIVA',
            style: AppTypography.metadataBadge(color: AppColors.accentTerracotta),
          ),
          const SizedBox(height: AppSpacing.tightGap),
          Text(
            'Revoga suas credenciais e apaga perfil, acervo e looks. Esta ação não pode ser desfeita.',
            style: AppTypography.bodyReading(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.elementGap),
          EditorialButton(
            label: 'Excluir conta',
            tone: EditorialButtonTone.destructive,
            isLoading: _busy == _Busy.delete,
            onPressed: _isBusy ? null : _confirmDelete,
          ),
        ],
      ),
    );
  }

  static const _months = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];

  static String _monthYear(DateTime date) => '${_months[date.month - 1]} ${date.year}';
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.subtitleCuratorial(color: AppColors.textPrimary));
  }
}

/// Confirmação digitada para a exclusão irreversível
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  static const _keyword = 'EXCLUIR';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCanvas,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pageMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Excluir sua conta?', style: AppTypography.editorialTitleMedium()),
            const SizedBox(height: AppSpacing.tightGap),
            Text(
              'Para confirmar, digite $_keyword abaixo.',
              style: AppTypography.bodyReading(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.elementGap),
            EditorialTextField(
              label: 'Confirmação',
              controller: _controller,
              hint: _keyword,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),
            ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final ready = _controller.text.trim().toUpperCase() == _keyword;
                return EditorialButton(
                  label: 'Excluir definitivamente',
                  tone: EditorialButtonTone.destructive,
                  onPressed: ready ? () => Navigator.pop(context, true) : null,
                );
              },
            ),
            const SizedBox(height: AppSpacing.tightGap),
            EditorialButton(
              label: 'Cancelar',
              tone: EditorialButtonTone.outline,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }
}
