import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_style_profile.dart';
import '../../theme/app_theme.dart';
import '../widgets/color_palette_preview.dart';
import '../widgets/silhouette_selector_card.dart';

/// Tela de Onboarding Estético e Perfil Pessoal (Morfologia e Colorimetria Sazonal Expandida)
/// Conforme AGENTS.md:
/// - Fundo Linho / Creme Quente (#FBF9F5)
/// - Transição editorial em etapas suaves via PageView
/// - Resposta háptica refinada com HapticFeedback
/// - Botão primário "Entrar no HarmonIA" em accentTerracotta
class OnboardingProfileScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const OnboardingProfileScreen({
    super.key,
    this.onCompleted,
  });

  @override
  State<OnboardingProfileScreen> createState() => _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState extends State<OnboardingProfileScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  BodySilhouetteType _selectedSilhouette = BodySilhouetteType.ampulheta;
  SeasonalPaletteType _selectedPalette = SeasonalPaletteType.outonoQuente;

  void _nextPage() {
    HapticFeedback.selectionClick();
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: AppMotion.medium,
        curve: AppMotion.editorialDecel,
      );
    }
  }

  void _previousPage() {
    HapticFeedback.selectionClick();
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: AppMotion.medium,
        curve: AppMotion.editorialDecel,
      );
    }
  }

  void _finishOnboarding() {
    HapticFeedback.mediumImpact();
    if (widget.onCompleted != null) {
      widget.onCompleted!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // Indicador Curatorial de Etapas (Linha Capilar sem Números de Fábrica)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    Expanded(
                      child: AnimatedContainer(
                        duration: AppMotion.fast,
                        curve: AppMotion.editorialDecel,
                        height: 3,
                        decoration: BoxDecoration(
                          color: i <= _currentStep
                              ? AppColors.accentTerracotta
                              : AppColors.borderSubtle,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                    if (i < 3) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),

            // Conteúdo do PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Controle guiado pelos botões
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                children: [
                  _buildStep0Welcome(),
                  _buildStep1Silhouette(),
                  _buildStep2Colorimetry(),
                  _buildStep3ProfileSummary(),
                ],
              ),
            ),

            // Barra de Navegação Inferior (Anterior / Próximo / Entrar)
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ETAPA 0: Boas-Vindas & Conceito Editorial
  Widget _buildStep0Welcome() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceRaised,
              border: Border.all(color: AppColors.borderGold, width: 1.0),
              boxShadow: AppColors.editorialShadow,
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_outlined,
                color: AppColors.iheGold,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'HarmonIA',
            style: AppTypography.displayEditorial().copyWith(
              fontSize: 38,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'CONSULTORIA DE ESTILO & MORFOCROMIA',
            style: AppTypography.metadataBadge(
              color: AppColors.accentTerracotta,
            ).copyWith(fontSize: 10, letterSpacing: 1.6),
          ),
          const SizedBox(height: 20),
          Text(
            'Descubra a harmonia matemática entre o seu biótipo corporal, cartela sazonal de cores e seu acervo pessoal.',
            style: AppTypography.bodyReading(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ETAPA 1: Análise de Biótipo Corporal (RF02)
  Widget _buildStep1Silhouette() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin, vertical: 12),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ETAPA 1 DE 3',
            style: AppTypography.metadataBadge(color: AppColors.accentTerracotta)
                .copyWith(fontSize: 9.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Análise de Biótipo Corporal',
            style: AppTypography.displayEditorial().copyWith(fontSize: 26),
          ),
          const SizedBox(height: 4),
          Text(
            'Selecione a silhueta que melhor descreve suas proporções naturais:',
            style: AppTypography.bodyReading(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          for (final type in BodySilhouetteType.values) ...[
            SilhouetteSelectorCard(
              silhouette: type,
              isSelected: type == _selectedSilhouette,
              onTap: () {
                setState(() => _selectedSilhouette = type);
              },
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  // ETAPA 2: Teste Assistido de Colorimetria Pessoal Sazonal
  Widget _buildStep2Colorimetry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin, vertical: 12),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ETAPA 2 DE 3',
            style: AppTypography.metadataBadge(color: AppColors.accentTerracotta)
                .copyWith(fontSize: 9.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Colorimetria Pessoal Sazonal',
            style: AppTypography.displayEditorial().copyWith(fontSize: 26),
          ),
          const SizedBox(height: 4),
          Text(
            'Análise assistida por IA para enquadramento da sua cartela de cores:',
            style: AppTypography.bodyReading(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ColorPalettePreview(
            paletteType: _selectedPalette,
            onPaletteSelected: (p) {
              setState(() => _selectedPalette = p);
            },
          ),
        ],
      ),
    );
  }

  // ETAPA 3: Resumo Curatorial do Perfil Final
  Widget _buildStep3ProfileSummary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin, vertical: 12),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEU PERFIL DE ESTILO PRONTO',
            style: AppTypography.metadataBadge(color: AppColors.accentTerracotta)
                .copyWith(fontSize: 9.5, letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          Text(
            'Resumo Curatorial',
            style: AppTypography.displayEditorial().copyWith(fontSize: 28),
          ),
          const SizedBox(height: 16),

          // Card de Síntese
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              border: Border.all(color: AppColors.borderSubtle, width: 0.8),
              boxShadow: AppColors.editorialShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BIÓTIPO: ${_selectedSilhouette.displayName.toUpperCase()}',
                      style: AppTypography.metadataBadge(color: AppColors.textPrimary)
                          .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                    const Icon(Icons.check_circle_outline, color: AppColors.iheGold, size: 18),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedSilhouette.recommendationNote,
                  style: AppTypography.bodyReading(color: AppColors.textSecondary)
                      .copyWith(fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CARTELA: ${_selectedPalette.displayName.toUpperCase()}',
                      style: AppTypography.metadataBadge(color: AppColors.accentTerracotta)
                          .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _selectedPalette.temperature,
                      style: AppTypography.metadataBadge(color: AppColors.textSecondary)
                          .copyWith(fontSize: 9),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final color in _selectedPalette.colorSwatches.take(5))
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(color: AppColors.surfaceCanvas, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
                child: Text(
                  'Voltar',
                  style: AppTypography.uiHeadline(color: AppColors.textSecondary)
                      .copyWith(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _currentStep == 3 ? _finishOnboarding : _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTerracotta,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
                child: Text(
                  _currentStep == 0
                      ? 'Iniciar Consultoria'
                      : _currentStep == 3
                          ? 'Entrar no HarmonIA'
                          : 'Avançar',
                  style: AppTypography.uiHeadline(color: AppColors.surfaceCanvas).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
