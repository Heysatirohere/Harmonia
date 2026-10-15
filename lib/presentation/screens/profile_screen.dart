import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/demo/demo_mode.dart';
import '../../domain/models/style_profile.dart';
import '../../domain/repositories/style_profile_repository.dart';
import '../../models/user_style_profile.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_room.dart';
import '../atelier/atelier_widgets.dart';
import '../atelier/room_scene.dart';
import '../auth/auth_scope.dart';
import '../profile/style_profile_scope.dart';
import '../widgets/freemium_quota_card.dart';
import '../widgets/style_recalibration_dialogs.dart';
import 'account_settings_screen.dart';
import 'gap_analysis_screen.dart';
import 'onboarding_profile_screen.dart';
import 'wardrobe_analytics_screen.dart';

/// Ateliê & Perfil (RF18): identidade sobre o veludo bordô, opções em folha de papel
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StyleProfileRepository? _repository;
  StyleProfile? _profile;
  String? _loadError;

  static const _demoProfile = StyleProfile(
    silhouette: BodySilhouetteType.ampulheta,
    palette: SeasonalPaletteType.outonoQuente,
    itemsCount: 8,
    maxItems: 30,
    looksToday: 1,
    maxDailyLooks: 5,
    isPremium: false,
    isPublic: true,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = StyleProfileScope.maybeOf(context);
    if (repository == _repository && _profile != null) return;
    _repository = repository;
    _load();
  }

  Future<void> _load() async {
    final repository = _repository;
    if (repository == null) {
      setState(() {
        if (kDemoMode) {
          _profile = _demoProfile;
        } else {
          _loadError = 'Perfil de estilo indisponível neste modo.';
        }
      });
      return;
    }
    setState(() => _loadError = null);
    try {
      final profile = await repository.fetch();
      if (mounted) setState(() => _profile = profile);
    } on StyleProfileFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        if (kDemoMode) {
          _profile = _demoProfile;
        } else {
          _loadError = failure.message;
        }
      });
    }
  }

  /// Salva no backend; lança [StyleProfileFailure] para quem precisar reagir à falha
  Future<void> _persist({BodySilhouetteType? silhouette, SeasonalPaletteType? palette, bool? isPublic}) async {
    final profile = await _repository!.update(silhouette: silhouette, palette: palette, isPublic: isPublic);
    if (mounted) setState(() => _profile = profile);
  }

  Future<void> _saveRecalibration({BodySilhouetteType? silhouette, SeasonalPaletteType? palette}) async {
    try {
      await _persist(silhouette: silhouette, palette: palette);
      _showMessage(silhouette != null
          ? 'Biótipo atualizado para ${silhouette.displayName}.'
          : 'Cartela atualizada para ${palette!.displayName}.');
    } on StyleProfileFailure catch (failure) {
      _showMessage(failure.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.tapestryNoir,
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: AppTypography.bodyReading(color: AppColors.ivoryText)),
      ),
    );
  }

  /// Recalibrar exige o perfil carregado; sem ele, a ação explica o motivo
  VoidCallback _requireProfile(VoidCallback action) {
    return () {
      if (_profile == null) {
        _showMessage(_loadError ?? 'Carregando o seu perfil de estilo…');
        return;
      }
      action();
    };
  }

  void _open(Widget screen) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) {
      // Reflete edições feitas em Conta & Segurança
      if (mounted) setState(() {});
    });
  }

  Future<void> _openPreferencesSheet(BuildContext context, StyleProfile profile) async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PreferencesSheet(
        profile: profile,
        onSave: (isPublic) async {
          try {
            await _persist(isPublic: isPublic);
            _showMessage(isPublic
                ? 'Perfil alterado para Público (visível no Feed Editorial).'
                : 'Perfil alterado para Privado (visível apenas para você).');
          } on StyleProfileFailure catch (e) {
            _showMessage(e.message);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = AuthScope.maybeOf(context)?.currentAccount;
    final displayName = account?.displayName ?? 'Ateliê pessoal';
    final displayEmail = account?.email;
    final profile = _profile;
    const room = AtelierRoom.velvetBordeaux;

    return Scaffold(
      backgroundColor: AppColors.tapestryNoir,
      body: RoomScene(
        room: room,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            const RoomHeader(eyebrow: 'Ateliê & Perfil', title: 'Ateliê', room: room),

            // Identidade direto sobre o veludo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gildedLeaf, width: 1.2),
                    ),
                    child: Text(
                      account?.monogram ?? 'H',
                      style: AppTypography.heroDisplay(color: AppColors.gildedLeaf).copyWith(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: AppTypography.displayEditorial(color: AppColors.ivoryText).copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 2),
                        if (displayEmail != null)
                          Text(displayEmail, style: AppTypography.bodySmall(color: AppColors.ivoryMuted)),
                        const SizedBox(height: 10),
                        if (profile != null)
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _RoomChip(label: profile.silhouette?.displayName ?? 'Biótipo a definir'),
                              _RoomChip(
                                label: profile.palette?.displayName ?? 'Cartela a definir',
                                swatches: profile.palette?.colorSwatches ?? const [],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Cota Freemium (RN02)
            if (profile != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                child: FreemiumQuotaCard(
                  profile: profile,
                  onUpgradeTap: () {
                    setState(() => _profile = profile.copyWith(isPremium: true));
                    _showMessage('Parabéns! Assinatura HarmonIA Ateliê ativada!');
                  },
                ),
              )
            else if (_loadError != null)
              _LoadErrorNotice(message: _loadError!, onRetry: _repository == null ? null : _load),

            // Recalibração & configurações (RF18)
            const RoomSectionTitle(title: 'Recalibração & configurações', meta: 'RF18'),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin, 0, AppSpacing.pageMargin, 48),
              child: AtelierSheet(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  children: [
                    _ActionItem(
                      icon: Icons.camera_front_outlined,
                      title: 'Recalibrar Colorimetria',
                      subtitle: 'Refazer teste de iluminação selfie via câmera',
                      onTap: _requireProfile(() => StyleRecalibrationDialogs.showColorimetryRecalibration(
                            context,
                            current: profile!.palette,
                            onSelected: (palette) => _saveRecalibration(palette: palette),
                          )),
                    ),
                    _ActionItem(
                      icon: Icons.accessibility_new_outlined,
                      title: 'Ajustar Biótipo Corporal',
                      subtitle: 'Atualizar proporções morfológicas',
                      onTap: _requireProfile(() => StyleRecalibrationDialogs.showBodyTypeAdjustment(
                            context,
                            current: profile!.silhouette,
                            onSelected: (silhouette) => _saveRecalibration(silhouette: silhouette),
                          )),
                    ),
                    _ActionItem(
                      icon: Icons.style_outlined,
                      title: 'Refazer Perfil de Estilo',
                      subtitle: 'Onboarding morfocromático completo',
                      onTap: _requireProfile(() => _open(OnboardingProfileScreen(
                            initialSilhouette: profile!.silhouette,
                            initialPalette: profile.palette,
                            onCompleted: (silhouette, palette) async {
                              await _persist(silhouette: silhouette, palette: palette);
                              if (context.mounted) Navigator.pop(context);
                            },
                          ))),
                    ),
                    _ActionItem(
                      icon: Icons.eco_outlined,
                      title: 'Saúde do Acervo & Rotação ESG (3.2.2)',
                      subtitle: 'Ociosidade (30/60/90d) e cores do armário',
                      onTap: () => _open(const WardrobeAnalyticsScreen()),
                    ),
                    _ActionItem(
                      icon: Icons.extension_outlined,
                      title: 'Lacunas do Acervo (3.6.1)',
                      subtitle: 'Peças-chave que destravam novas combinações',
                      onTap: () => _open(const GapAnalysisScreen()),
                    ),
                    _ActionItem(
                      icon: Icons.security_outlined,
                      title: 'Conta & Segurança',
                      subtitle: 'Dados pessoais, senha, sessão e exclusão (RN04)',
                      onTap: () => _open(const AccountSettingsScreen()),
                    ),
                    _ActionItem(
                      icon: Icons.notifications_none_outlined,
                      title: 'Preferências & Privacidade',
                      subtitle: 'Notificações e perfil público/privado (RN05)',
                      onTap: _requireProfile(() => _openPreferencesSheet(context, profile!)),
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selo de perfil sobre a Sala, com amostras de cor opcionais
class _RoomChip extends StatelessWidget {
  final String label;
  final List<Color> swatches;

  const _RoomChip({required this.label, this.swatches = const []});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairlineIvory, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final swatch in swatches.take(3))
            Container(
              margin: const EdgeInsets.only(right: 4),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.hairlineIvory, width: 0.6),
              ),
            ),
          if (swatches.isNotEmpty) const SizedBox(width: 2),
          Text(label, style: AppTypography.bodySmall(color: AppColors.ivoryText).copyWith(fontSize: 11.5)),
        ],
      ),
    );
  }
}

/// Linha de opção dentro da folha de papel
class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.hairlineInk, width: 0.6)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(icon, color: AppColors.gildedInk, size: 22),
        title: Text(title, style: AppTypography.uiHeadline(color: AppColors.inkText).copyWith(fontSize: 14)),
        subtitle: Text(subtitle, style: AppTypography.bodySmall(color: AppColors.inkSecondary)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.inkSecondary, size: 18),
        onTap: onTap,
      ),
    );
  }
}

/// Aviso sobre a Sala quando o perfil não pôde ser carregado
class _LoadErrorNotice extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _LoadErrorNotice({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
      child: Row(
        children: [
          Expanded(
            child: Text(message, style: AppTypography.bodyReading(color: AppColors.ivoryMuted)),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: AppSpacing.elementGap),
            RoomIconButton(icon: Icons.refresh, label: 'Tentar de novo', onTap: onRetry!),
          ],
        ],
      ),
    );
  }
}

/// Folha de Preferências e Privacidade (RN05, RF18)
class _PreferencesSheet extends StatefulWidget {
  final StyleProfile profile;
  final Future<void> Function(bool isPublic) onSave;

  const _PreferencesSheet({required this.profile, required this.onSave});

  @override
  State<_PreferencesSheet> createState() => _PreferencesSheetState();
}

class _PreferencesSheetState extends State<_PreferencesSheet> {
  late bool _isPublic;
  bool _dailyNotifications = true;
  bool _rotationAlerts = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isPublic = widget.profile.isPublic;
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    await widget.onSave(_isPublic);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paperBone,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLarge)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.paddingOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.hairlineInk,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'PREFERÊNCIAS & PRIVACIDADE • RN05',
              style: AppTypography.atelierMeta(color: AppColors.accentCinnabar),
            ),
            const SizedBox(height: 4),
            Text(
              'Privacidade do Ateliê',
              style: AppTypography.displayEditorial(color: AppColors.inkText).copyWith(fontSize: 24),
            ),
            const SizedBox(height: 6),
            Text(
              'Controle a visibilidade das suas publicações e notificações.',
              style: AppTypography.bodyReading(color: AppColors.inkSecondary),
            ),
            const SizedBox(height: 20),

            // Card Modo de Privacidade (RN05)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paperBoneRaised,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: AppColors.hairlineInk, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isPublic ? Icons.public : Icons.lock_outline,
                            color: _isPublic ? AppColors.accentCinnabar : AppColors.gildedInk,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isPublic ? 'Perfil Público' : 'Perfil Privado',
                            style: AppTypography.uiHeadline(color: AppColors.inkText).copyWith(fontSize: 15),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: _isPublic,
                        activeColor: AppColors.accentCinnabar,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _isPublic = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPublic
                        ? 'Seu perfil, biótipo e looks compartilhados aparecem no Feed Editorial comunitário para outros membros se inspirarem.'
                        : 'Modo Privado ativo. Seu acervo, biótipo e combinações são estritamente sigilosos e visíveis apenas para você (RN01).',
                    style: AppTypography.bodySmall(color: AppColors.inkSecondary).copyWith(height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notificações
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.paperBoneRaised,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: AppColors.hairlineInk, width: 0.8),
              ),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Lembretes Diários de Look', style: AppTypography.uiHeadline(color: AppColors.inkText).copyWith(fontSize: 13.5)),
                    subtitle: Text('Sugestões matinais ajustadas ao clima', style: AppTypography.bodySmall(color: AppColors.inkSecondary)),
                    value: _dailyNotifications,
                    activeColor: AppColors.accentCinnabar,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _dailyNotifications = val);
                    },
                  ),
                  const Divider(color: AppColors.hairlineInk, height: 1),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Alertas de Rotação ESG', style: AppTypography.uiHeadline(color: AppColors.inkText).copyWith(fontSize: 13.5)),
                    subtitle: Text('Avisos sobre peças ociosas há mais de 60 dias', style: AppTypography.bodySmall(color: AppColors.inkSecondary)),
                    value: _rotationAlerts,
                    activeColor: AppColors.accentCinnabar,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _rotationAlerts = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botão Salvar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCinnabar,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMedium)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ivoryText))
                    : Text('Salvar Preferências', style: AppTypography.uiHeadline(color: AppColors.ivoryText)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
