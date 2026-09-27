import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../mocks/mock_user_profile.dart';
import '../../models/user_profile.dart';
import '../widgets/freemium_quota_card.dart';
import '../widgets/gap_analysis_sheet.dart';
import '../widgets/style_recalibration_dialogs.dart';

/// Tela Completa de Perfil, Configurações de Conta e Monitor Freemium (RF18 & RN02)
///
/// Segue rigorosamente o AGENTS.md:
/// - Fundo creme quente (#FBF9F5)
/// - Tipografia com contraste e atmosfera editorial (Playfair Display + Plus Jakarta Sans)
/// - Monitor de cota com réguas tipográficas finas (RN02)
/// - Seções de recalibração morfocromática e dados da conta (RF18)
class ProfileScreen extends StatefulWidget {
  final UserProfile? initialProfile;

  const ProfileScreen({
    super.key,
    this.initialProfile,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile ?? MockUserProfile.defaultUser;
  }

  void _handleTogglePrivacy(bool value) {
    HapticFeedback.selectionClick();
    setState(() {
      _profile = _profile.copyWith(isPublicProfile: value);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              value ? Icons.public : Icons.lock_outline,
              color: AppColors.iheGold,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              value
                  ? 'Perfil definido como PÚBLICO (visível na comunidade).'
                  : 'Perfil definido como PRIVADO (apenas para si).',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.surfaceCanvas,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBodyTypeChange() async {
    final selected = await StyleRecalibrationDialogs.showBodyTypePicker(
      context,
      currentBodyType: _profile.bodyType,
    );
    if (selected != null) {
      setState(() {
        _profile = _profile.copyWith(bodyType: selected);
      });
    }
  }

  void _handleEditAccount() async {
    final updated = await StyleRecalibrationDialogs.showEditAccountModal(
      context,
      profile: _profile,
    );
    if (updated != null) {
      setState(() {
        _profile = updated;
      });
    }
  }

  void _toggleMockScenario() {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_profile.isPremium && !_profile.hasReachedPiecesLimit) {
        _profile = MockUserProfile.limitReachedUser; // Cenário Teto Atingido
      } else if (!_profile.isPremium) {
        _profile = MockUserProfile.premiumUser; // Cenário Premium
      } else {
        _profile = MockUserProfile.defaultUser; // Cenário Freemium normal
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ATELIÊ HARMONIA • CONFIGURAÇÕES',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Perfil & Governança',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Simular Cenário de Cota Freemium (RN02)',
            icon: const Icon(Icons.swap_calls_rounded,
                color: AppColors.iheGold, size: 22),
            onPressed: _toggleMockScenario,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.textPrimary, size: 22),
            onPressed: _handleEditAccount,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER DE IDENTIDADE DO USUÁRIO
              _buildUserIdentityHeader(),

              const SizedBox(height: 20),

              // 2. MONITOR DE COTA FREEMIUM & RÉGUAS ANALÍTICAS (RN02)
              FreemiumQuotaCard(
                profile: _profile,
                onUpgradeTap: () {
                  setState(() {
                    _profile = _profile.copyWith(isPremium: true);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.accentOlive,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      content: Text(
                        'Parabéns! Upgrade para HarmonIA Premium ativado!',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 3. CARD DE ACESSO À ANÁLISE DE LACUNAS (GAP ANALYSIS - RF11)
              _buildGapAnalysisCard(),

              const SizedBox(height: 20),

              // 4. SEÇÃO DE RECALIBRAÇÃO DE ESTILO E SEGURANÇA (RF18)
              Text(
                'RECALIBRAÇÃO & CONFIGURAÇÕES DA CONTA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 12),

              _buildSettingsTile(
                icon: Icons.camera_front_rounded,
                title: 'Recalibrar Colorimetria Pessoal',
                subtitle:
                    'Reabrir scanner assistido via câmera para atualizar cartela.',
                onTap: () =>
                    StyleRecalibrationDialogs.showColorimetryTestModal(context),
              ),

              const SizedBox(height: 10),

              _buildSettingsTile(
                icon: Icons.accessibility_new_rounded,
                title: 'Ajustar Biótipo Corporal',
                subtitle:
                    'Silhueta atual: ${_profile.bodyType}. Toque para alterar.',
                onTap: _handleBodyTypeChange,
              ),

              const SizedBox(height: 10),

              _buildSettingsTile(
                icon: Icons.badge_outlined,
                title: 'Dados da Conta & Segurança',
                subtitle: 'Editar e-mail, nome de exibição e credenciais.',
                onTap: _handleEditAccount,
              ),

              const SizedBox(height: 10),

              // 5. CHAVE SELETORA DE PRIVACIDADE E NOTIFICAÇÕES (RN05)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCanvas,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.borderSubtle,
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        _profile.isPublicProfile
                            ? Icons.public_rounded
                            : Icons.lock_outline_rounded,
                        color: _profile.isPublicProfile
                            ? AppColors.accentOlive
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perfil Público na Comunidade',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _profile.isPublicProfile
                                ? 'Seu acervo e looks compartilhados estão visíveis (RN05).'
                                : 'Modo Privado ativado. Visível apenas para si.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _profile.isPublicProfile,
                      activeTrackColor: AppColors.accentOlive,
                      onChanged: _handleTogglePrivacy,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  /// Header de Identidade com Avatar e Badges Morfocromáticos
  Widget _buildUserIdentityHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 0.8,
        ),
        boxShadow: AppColors.editorialShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.accentSand,
                child: Text(
                  _profile.name.substring(0, 2).toUpperCase(),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile.name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_profile.handle} • ${_profile.email}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Badges de Diagnóstico Morfocromático
          Row(
            children: [
              // Badge Biótipo
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCanvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.accessibility_new_rounded,
                        size: 13, color: AppColors.accentTerracotta),
                    const SizedBox(width: 5),
                    Text(
                      _profile.bodyType,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Badge Cartela Cromática com Amostras Tonares
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCanvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    // Swatches da cartela
                    ...List.generate(_profile.paletteColors.length, (i) {
                      return Container(
                        margin: const EdgeInsets.only(right: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _profile.paletteColors[i],
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                    Text(
                      _profile.colorPalette,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Banner de Acesso ao Módulo de Gap Analysis
  Widget _buildGapAnalysisCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        GapAnalysisSheet.show(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.borderGold,
            width: 0.8,
          ),
          boxShadow: AppColors.editorialShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.iheGoldLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderGold,
                  width: 0.8,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.iheGold,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OTIMIZAÇÃO DE ACERVO • RF11',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.accentTerracotta,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Análise de Lacunas do Armário',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ver sugestões de peças C&A e Renner com afiliação.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  /// Tile de Ação de Configuração / Recalibração (RF18)
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCanvas,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.accentTerracotta,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
