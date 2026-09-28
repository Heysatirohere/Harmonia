import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/supabase_auth_service.dart';
import '../../theme/app_theme.dart';

/// Modal Editorial de Autenticação Supabase (RF01 - Login e Cadastro)
class AuthModalSheet extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const AuthModalSheet({
    super.key,
    this.onAuthSuccess,
  });

  static Future<void> show(BuildContext context, {VoidCallback? onAuthSuccess}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AuthModalSheet(onAuthSuccess: onAuthSuccess),
    );
  }

  @override
  State<AuthModalSheet> createState() => _AuthModalSheetState();
}

class _AuthModalSheetState extends State<AuthModalSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, preencha todos os campos.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'A senha deve conter ao menos 6 caracteres.';
      });
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = SupabaseAuthService();
      if (_isSignUp) {
        await auth.signUp(email: email, password: password);
      } else {
        await auth.signIn(email: email, password: password);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onAuthSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.textPrimary,
            content: Text(
              _isSignUp
                  ? 'Conta criada com sucesso!'
                  : 'Sessão iniciada no HarmonIA!',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isSignUp ? 'Criar Sua Conta' : 'Acessar Seu Ateliê',
              style: AppTypography.displayEditorial().copyWith(
                fontSize: 22,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'CONSULTORIA DE ESTILO & ACERVO PESSOAL',
              style: AppTypography.metadataBadge(color: AppColors.iheGold).copyWith(
                fontSize: 9.5,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Toggle Entrar / Cadastrar
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isSignUp = false;
                        _errorMessage = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: !_isSignUp ? AppColors.accentTerracotta : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'ENTRAR',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: !_isSignUp ? FontWeight.w700 : FontWeight.w500,
                          color: !_isSignUp ? AppColors.accentTerracotta : AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isSignUp = true;
                        _errorMessage = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _isSignUp ? AppColors.accentTerracotta : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'CADASTRAR',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: _isSignUp ? FontWeight.w700 : FontWeight.w500,
                          color: _isSignUp ? AppColors.accentTerracotta : AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Mensagem de Erro
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200, width: 0.8),
                ),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: Colors.red.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Input E-mail
            Text(
              'E-MAIL',
              style: AppTypography.metadataBadge(color: AppColors.textSecondary).copyWith(
                fontSize: 9.5,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'seu.email@exemplo.com',
                hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceRaised,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.accentTerracotta, width: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Input Senha
            Text(
              'SENHA',
              style: AppTypography.metadataBadge(color: AppColors.textSecondary).copyWith(
                fontSize: 9.5,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceRaised,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.accentTerracotta, width: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botão de Submissão
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTerracotta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isSignUp ? 'CRIAR CONTA' : 'INICIAR SESSÃO',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
