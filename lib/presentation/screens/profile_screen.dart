import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/services/supabase_auth_service.dart';
import '../../mocks/mock_user_profile.dart';
import '../../models/user_profile.dart';
import '../widgets/auth_modal_sheet.dart';
import '../widgets/freemium_quota_card.dart';
import '../widgets/style_recalibration_dialogs.dart';
import 'wardrobe_analytics_screen.dart';

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

  void _onBiotypeChanged(String newBiotype) {
    setState(() {
      _profile = _profile.copyWith(biotype: newBiotype);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        content: Text(
          'Biótipo atualizado para: $newBiotype',
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCanvas,
        title: Text(
          'Encerrar Sessão',
          style: GoogleFonts.playfairDisplay(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Deseja sair da sua conta no HarmonIA?',
          style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseAuthService().signOut();
              setState(() {});
            },
            child: Text('Sair', style: GoogleFonts.plusJakartaSans(color: AppColors.accentTerracotta, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = SupabaseAuthService().currentUser;
    final displayEmail = authUser?.email ?? _profile.email;

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCanvas,
        elevation: 0,
        title: Text(
          'Ateliê & Perfil',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Identity Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCanvas,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle, width: 0.8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.surfaceRaised,
                  child: Text(
                    _profile.name[0],
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.iheGold,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile.name,
                        style: GoogleFonts.playfairDisplay(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayEmail,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildChip(_profile.biotype),
                          const SizedBox(width: 8),
                          _buildColorimetryChip(_profile.colorPalette, _profile.colorSwatchHexes),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Freemium Quota Card (RN02)
          FreemiumQuotaCard(
            profile: _profile,
            onUpgradeTap: () {
              setState(() {
                _profile = _profile.copyWith(isPremium: true);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.textPrimary,
                  content: Text(
                    'Parabéns! Assinatura HarmonIA Ateliê ativada!',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Style Recalibration Options (RF18)
          Text(
            'RECALIBRAÇÃO & CONFIGURAÇÕES (RF18)',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          _buildActionItem(
            icon: Icons.camera_front_outlined,
            title: 'Recalibrar Colorimetria',
            subtitle: 'Refazer teste de iluminação selfie via câmera',
            onTap: () => StyleRecalibrationDialogs.showColorimetryRecalibration(context),
          ),
          _buildActionItem(
            icon: Icons.accessibility_new_outlined,
            title: 'Ajustar Biótipo Corporal',
            subtitle: 'Atualizar proporções morfológicas',
            onTap: () => StyleRecalibrationDialogs.showBodyTypeAdjustment(
              context,
              onSelected: _onBiotypeChanged,
            ),
          ),
          _buildActionItem(
            icon: Icons.eco_outlined,
            title: 'Saúde do Acervo & Rotação ESG (3.2.2)',
            subtitle: 'Ociosidade (30/60/90d), custo por uso e cores',
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WardrobeAnalyticsScreen(),
                ),
              );
            },
          ),
          _buildActionItem(
            icon: Icons.security_outlined,
            title: 'Dados da Conta & Segurança',
            subtitle: 'Editar credenciais e e-mail',
            onTap: () {
              HapticFeedback.lightImpact();
            },
          ),
          _buildActionItem(
            icon: Icons.key_outlined,
            title: authUser != null ? 'Sessão Supabase Ativa' : 'Acessar Conta (Supabase Auth)',
            subtitle: authUser != null
                ? 'Conectado como ${authUser.email}. Toque para sair.'
                : 'Entrar ou registrar com e-mail e senha (RF01)',
            onTap: () {
              HapticFeedback.lightImpact();
              if (authUser != null) {
                _showLogoutDialog();
              } else {
                AuthModalSheet.show(context, onAuthSuccess: () {
                  setState(() {});
                });
              }
            },
          ),
          _buildActionItem(
            icon: Icons.notifications_none_outlined,
            title: 'Preferências & Privacidade',
            subtitle: 'Notificações e perfil público/privado (RN05)',
            onTap: () {
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildColorimetryChip(String label, List<String> swatches) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderGold, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: swatches.take(3).map((hex) {
              return Container(
                margin: const EdgeInsets.only(right: 3),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(int.parse(hex.replaceAll('#', '0xFF'))),
                  shape: BoxShape.circle,
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textPrimary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: Icon(icon, color: AppColors.iheGold, size: 22),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textSecondary,
              fontSize: 11.5,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          onTap: onTap,
        ),
      ),
    );
  }
}
