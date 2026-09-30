import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../mocks/mock_user_profile.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_room.dart';
import '../atelier/atelier_widgets.dart';
import '../atelier/room_scene.dart';
import '../auth/auth_scope.dart';
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
  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = MockUserProfile.defaultProfile;
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

  void _onBiotypeChanged(String newBiotype) {
    setState(() {
      _profile = _profile.copyWith(biotype: newBiotype);
    });
    _showMessage('Biótipo atualizado para: $newBiotype');
  }

  void _open(Widget screen) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) {
      // Reflete edições feitas em Conta & Segurança
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = AuthScope.maybeOf(context)?.currentAccount;
    final displayName = account?.displayName ?? _profile.name;
    final displayEmail = account?.email ?? _profile.email;
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
                      account?.monogram ?? _profile.name[0],
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
                        Text(displayEmail, style: AppTypography.bodySmall(color: AppColors.ivoryMuted)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _RoomChip(label: _profile.biotype),
                            _RoomChip(label: _profile.colorPalette, swatches: _profile.colorSwatchHexes),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
              child: FreemiumQuotaCard(
                profile: _profile,
                onUpgradeTap: () {
                  setState(() {
                    _profile = _profile.copyWith(isPremium: true);
                  });
                  _showMessage('Parabéns! Assinatura HarmonIA Ateliê ativada!');
                },
              ),
            ),

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
                      onTap: () => StyleRecalibrationDialogs.showColorimetryRecalibration(context),
                    ),
                    _ActionItem(
                      icon: Icons.accessibility_new_outlined,
                      title: 'Ajustar Biótipo Corporal',
                      subtitle: 'Atualizar proporções morfológicas',
                      onTap: () => StyleRecalibrationDialogs.showBodyTypeAdjustment(
                        context,
                        onSelected: _onBiotypeChanged,
                      ),
                    ),
                    _ActionItem(
                      icon: Icons.style_outlined,
                      title: 'Refazer Perfil de Estilo',
                      subtitle: 'Onboarding morfocromático completo',
                      onTap: () => _open(OnboardingProfileScreen(onCompleted: () => Navigator.pop(context))),
                    ),
                    _ActionItem(
                      icon: Icons.eco_outlined,
                      title: 'Saúde do Acervo & Rotação ESG (3.2.2)',
                      subtitle: 'Ociosidade (30/60/90d), custo por uso e cores',
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
                      onTap: () => HapticFeedback.lightImpact(),
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
  final List<String> swatches;

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
          for (final hex in swatches.take(3))
            Container(
              margin: const EdgeInsets.only(right: 4),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: Color(int.parse(hex.replaceAll('#', '0xFF'))),
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
