import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

/// Componentes de formulário editoriais compartilhados (autenticação e conta)

/// Campo de texto com rótulo em caixa alta e linha capilar
class EditorialTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  const EditorialTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.validator,
    this.onSubmitted,
    this.enabled = true,
  });

  @override
  State<EditorialTextField> createState() => _EditorialTextFieldState();
}

class _EditorialTextFieldState extends State<EditorialTextField> {
  late bool _obscured = widget.obscure;

  static OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall + 2),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: AppTypography.metadataBadge().copyWith(fontSize: 10),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          autocorrect: !widget.obscure,
          enableSuggestions: !widget.obscure,
          cursorColor: AppColors.accentCinnabar,
          cursorWidth: 1.2,
          style: AppTypography.bodyReading(),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.bodyReading(color: AppColors.inkSecondary),
            filled: true,
            fillColor: AppColors.paperBoneRaised,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            errorStyle: AppTypography.bodySmall(color: AppColors.accentCinnabar).copyWith(fontSize: 11),
            border: _border(AppColors.hairlineInk, 0.8),
            enabledBorder: _border(AppColors.hairlineInk, 0.8),
            disabledBorder: _border(AppColors.hairlineInk, 0.8),
            focusedBorder: _border(AppColors.inkText, 1.0),
            errorBorder: _border(AppColors.accentCinnabar, 0.8),
            focusedErrorBorder: _border(AppColors.accentCinnabar, 1.0),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _obscured ? 'Mostrar senha' : 'Ocultar senha',
                    splashRadius: 18,
                    icon: Icon(
                      _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppColors.inkSecondary,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _obscured = !_obscured);
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

enum EditorialButtonTone { primary, outline, destructive }

/// Botão autoral para folhas de papel: cinábrio (ação primária), contorno de tinta ou destrutivo.
/// O destrutivo é só contorno cinábrio, para não competir com a ação primária.
/// O estado de espera pulsa a opacidade do rótulo (sem spinner padrão).
class EditorialButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final EditorialButtonTone tone;

  const EditorialButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.tone = EditorialButtonTone.primary,
  });

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground, Color border) = switch (tone) {
      EditorialButtonTone.primary => (AppColors.accentCinnabar, AppColors.ivoryText, AppColors.accentCinnabar),
      EditorialButtonTone.outline => (Colors.transparent, AppColors.inkText, AppColors.inkSecondary),
      EditorialButtonTone.destructive => (Colors.transparent, AppColors.accentCinnabar, AppColors.accentCinnabar),
    };
    final enabled = onPressed != null && !isLoading;

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: AppMotion.fast,
          curve: AppMotion.editorialDecel,
          opacity: onPressed == null ? 0.4 : 1.0,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(color: border, width: 0.8),
            ),
            child: _BreathingLabel(
              text: isLoading ? 'AGUARDE' : label.toUpperCase(),
              breathing: isLoading,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathingLabel extends StatefulWidget {
  final String text;
  final bool breathing;
  final Color color;

  const _BreathingLabel({required this.text, required this.breathing, required this.color});

  @override
  State<_BreathingLabel> createState() => _BreathingLabelState();
}

class _BreathingLabelState extends State<_BreathingLabel> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _opacity = Tween<double>(begin: 1.0, end: 0.35).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _BreathingLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.breathing != widget.breathing) _sync();
  }

  void _sync() {
    if (widget.breathing) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Text(
        widget.text,
        style: AppTypography.metadataBadge(color: widget.color).copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

enum FormNoticeTone { error, success }

/// Aviso inline com filete lateral (erro em terracota, sucesso em oliva)
class FormNotice extends StatelessWidget {
  final String message;
  final FormNoticeTone tone;

  const FormNotice({super.key, required this.message, this.tone = FormNoticeTone.error});

  @override
  Widget build(BuildContext context) {
    final accent = tone == FormNoticeTone.error ? AppColors.accentCinnabar : AppColors.verdigrisInk;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          border: Border(left: BorderSide(color: accent, width: 2)),
        ),
        child: Text(message, style: AppTypography.bodyReading(color: accent)),
      ),
    );
  }
}

/// Validações compartilhadas entre cadastro e edição de conta
class AccountValidators {
  AccountValidators._();

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static const int minPasswordLength = 8;

  static String? name(String? value) {
    if (value == null || value.trim().length < 2) return 'Informe seu nome.';
    return null;
  }

  static String? email(String? value) {
    if (value == null || !_emailPattern.hasMatch(value.trim())) return 'Informe um e-mail válido.';
    return null;
  }

  static String? required(String? value) {
    if (value == null || value.isEmpty) return 'Campo obrigatório.';
    return null;
  }

  static String? newPassword(String? value) {
    if (value == null || value.length < minPasswordLength) {
      return 'Use ao menos $minPasswordLength caracteres.';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value) || !RegExp(r'\d').hasMatch(value)) {
      return 'Combine letras e números.';
    }
    return null;
  }
}
