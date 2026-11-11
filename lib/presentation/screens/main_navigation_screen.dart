import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/demo/demo_mode.dart';
import '../../data/services/community_api_service.dart';
import '../../domain/models/style_profile.dart';
import '../../mocks/mock_atelier_store.dart';
import '../../models/clothing_item.dart';
import '../../models/user_style_profile.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_widgets.dart';
import '../auth/auth_scope.dart';
import '../profile/style_profile_scope.dart';
import '../widgets/editorial_nav_bar.dart';
import '../widgets/share_outfit_sheet.dart';
import 'account_settings_screen.dart';
import 'circular_marketplace_screen.dart';
import 'community_feed_screen.dart';
import 'daily_outfit_screen.dart';
import 'gap_analysis_screen.dart';
import 'profile_screen.dart';
import 'scan_item_screen.dart';
import 'store_mirror_screen.dart';
import 'wardrobe_analytics_screen.dart';
import 'wardrobe_screen.dart';

/// Shell principal de navegação do HarmonIA (inspirado no app mobile do X)
///
/// - Barra inferior enxuta com apenas os 3 fluxos diários: Sugestão, Acervo e Editorial.
/// - Botão flutuante de criação/captura (FAB) no canto inferior direito.
/// - Gaveta lateral esquerda (Ateliê & Perfil) acionada pelo avatar no canto
///   superior esquerdo ou por gesto de arraste lateral, concentrando Perfil de
///   Estilo, Saúde ESG, Lacunas do Acervo, Brechó Circular e Conta & Segurança.
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  static const List<EditorialNavDestination> destinations = [
    EditorialNavDestination(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: 'Sugestão',
    ),
    EditorialNavDestination(
      icon: Icons.checkroom_outlined,
      activeIcon: Icons.checkroom,
      label: 'Acervo',
    ),
    EditorialNavDestination(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Editorial',
    ),
  ];

  static const int wardrobeTab = 1;
  static const int editorialTab = 2;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentIndex = widget.initialIndex.clamp(0, MainNavigationScreen.destinations.length - 1);

  /// Recria o Acervo e o Look do Dia após uma captura feita fora do Acervo
  int _wardrobeRevision = 0;

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _pushFromDrawer(Widget screen) async {
    Navigator.of(context).pop(); // Fecha a gaveta lateral
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  Future<void> _openCaptureTray() async {
    final action = await showModalBottomSheet<_CaptureOption>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.tapestryNoir.withValues(alpha: 0.55),
      builder: (_) => const _CaptureTray(),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _CaptureOption.scanItem:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ScanItemScreen(onItemCataloged: _onItemCataloged)),
        );
      case _CaptureOption.storeMirror:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StoreMirrorScreen()),
        );
      case _CaptureOption.shareEditorial:
        final post = await ShareOutfitSheet.show(
          context,
          service: CommunityApiService(),
        );
        if (post != null && mounted) {
          setState(() {
            _wardrobeRevision++;
            _currentIndex = MainNavigationScreen.editorialTab;
          });
        }
    }
  }

  /// A peça já foi salva pelo ScanItemScreen; aqui só se abre o Acervo atualizado
  void _onItemCataloged(ClothingItem item) {
    setState(() {
      _wardrobeRevision++;
      _currentIndex = MainNavigationScreen.wardrobeTab;
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = AuthScope.maybeOf(context)?.currentAccount;
    final monogram = account?.monogram ?? 'H';

    return AtelierShellScope(
      openDrawer: _openDrawer,
      monogram: monogram,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.tapestryNoir,
        drawerEdgeDragWidth: 36,
        drawerScrimColor: AppColors.tapestryNoir.withValues(alpha: 0.65),
        drawer: _AtelierSideDrawer(
          onOpenProfile: () => _pushFromDrawer(const ProfileScreen()),
          onOpenAnalytics: () => _pushFromDrawer(const WardrobeAnalyticsScreen()),
          onOpenGaps: () => _pushFromDrawer(const GapAnalysisScreen()),
          onOpenCircular: () => _pushFromDrawer(
            CircularMarketplaceScreen(
              onItemAcquired: (_) => setState(() => _wardrobeRevision++),
            ),
          ),
          onOpenMirror: () => _pushFromDrawer(const StoreMirrorScreen()),
          onOpenAccount: () => _pushFromDrawer(const AccountSettingsScreen()),
          onResetDemo: () {
            Navigator.of(context).pop();
            HapticFeedback.mediumImpact();
            MockAtelierStore.instance.reset();
            setState(() => _wardrobeRevision++);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.tapestryNoir,
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'Dados de demonstração restaurados com sucesso.',
                    style: AppTypography.bodySmall(color: AppColors.ivoryText),
                  ),
                ),
              );
          },
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            DailyOutfitScreen(key: ValueKey('outfit_$_wardrobeRevision')),
            WardrobeScreen(key: ValueKey('wardrobe_$_wardrobeRevision')),
            CommunityFeedScreen(key: ValueKey('editorial_$_wardrobeRevision')),
          ],
        ),
        floatingActionButton: AtelierCaptureFab(onTap: _openCaptureTray),
        bottomNavigationBar: EditorialNavBar(
          destinations: MainNavigationScreen.destinations,
          currentIndex: _currentIndex,
          onSelected: _onTabSelected,
          onCapture: _openCaptureTray,
        ),
      ),
    );
  }
}

/// Gaveta lateral esquerda (inspirada no app mobile do X)
///
/// Reúne a identidade morfocromática da usuária e os destinos analíticos,
/// estratégicos e de conta sem poluir a barra de navegação inferior.
class _AtelierSideDrawer extends StatefulWidget {
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onOpenGaps;
  final VoidCallback onOpenCircular;
  final VoidCallback onOpenMirror;
  final VoidCallback onOpenAccount;
  final VoidCallback? onResetDemo;

  const _AtelierSideDrawer({
    required this.onOpenProfile,
    required this.onOpenAnalytics,
    required this.onOpenGaps,
    required this.onOpenCircular,
    required this.onOpenMirror,
    required this.onOpenAccount,
    this.onResetDemo,
  });

  @override
  State<_AtelierSideDrawer> createState() => _AtelierSideDrawerState();
}

class _AtelierSideDrawerState extends State<_AtelierSideDrawer> {
  StyleProfile? _profile;

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
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final repo = StyleProfileScope.maybeOf(context);
    if (repo == null) {
      if (kDemoMode && mounted) setState(() => _profile = _demoProfile);
      return;
    }
    try {
      final profile = await repo.fetch();
      if (mounted) setState(() => _profile = profile);
    } catch (_) {
      if (kDemoMode && mounted) setState(() => _profile = _demoProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = AuthScope.maybeOf(context)?.currentAccount;
    final displayName = account?.displayName ?? 'Ateliê pessoal';
    final displayEmail = account?.email ?? 'Curadoria HarmonIA';
    final profile = _profile;

    return Drawer(
      width: 312,
      backgroundColor: AppColors.tapestryNoir,
      shape: const RoundedRectangleBorder(),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.velvetBordeaux,
              AppColors.tapestryNoir,
            ],
            stops: [0.0, 0.55],
          ),
          border: Border(right: BorderSide(color: AppColors.hairlineIvory, width: 0.8)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho de identidade (estilo X: Avatar, Nome, Handle/Email e métricas de perfil)
              GestureDetector(
                onTap: widget.onOpenProfile,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.tapestryNoir.withValues(alpha: 0.4),
                              border: Border.all(color: AppColors.gildedLeaf, width: 1.2),
                            ),
                            child: Text(
                              account?.monogram ?? 'H',
                              style: AppTypography.heroDisplay(color: AppColors.gildedLeaf).copyWith(fontSize: 22),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.hairlineGold, width: 0.8),
                              color: AppColors.gildedVeil,
                            ),
                            child: Text(
                              profile?.isPremium == true ? '✦ ATELIÊ PRO' : 'PLANO GRATUITO',
                              style: AppTypography.atelierMeta(color: AppColors.gildedLeaf).copyWith(fontSize: 9.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        displayName,
                        style: AppTypography.displayEditorial(color: AppColors.ivoryText).copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(displayEmail, style: AppTypography.bodySmall(color: AppColors.ivoryMuted)),
                      if (profile != null) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _DrawerBadge(label: profile.silhouette?.displayName ?? 'Biótipo a definir'),
                            _DrawerBadge(
                              label: profile.palette?.displayName ?? 'Cartela a definir',
                              dotColor: profile.palette?.colorSwatches.firstOrNull,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 0.6, color: AppColors.hairlineIvory),

              // Lista principal de destinos da gaveta
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    _DrawerNavTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Ateliê & Perfil de Estilo',
                      subtitle: 'Colorimetria, biótipo e recalibração',
                      onTap: widget.onOpenProfile,
                    ),
                    _DrawerNavTile(
                      icon: Icons.eco_outlined,
                      title: 'Saúde do Acervo & ESG',
                      subtitle: 'Rotação (30/60/90d) e custo por uso',
                      onTap: widget.onOpenAnalytics,
                    ),
                    _DrawerNavTile(
                      icon: Icons.extension_outlined,
                      title: 'Lacunas do Acervo (3.6.1)',
                      subtitle: 'Peças-chave que destravam looks',
                      onTap: widget.onOpenGaps,
                    ),
                    _DrawerNavTile(
                      icon: Icons.sync_alt_rounded,
                      title: 'Brechó Circular',
                      subtitle: 'Moda circular compatível com sua cartela',
                      onTap: widget.onOpenCircular,
                    ),
                    _DrawerNavTile(
                      icon: Icons.center_focus_strong_outlined,
                      title: 'Modo Provador (AR)',
                      subtitle: 'Paridade de peça em loja com o armário',
                      onTap: widget.onOpenMirror,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 0.6, color: AppColors.hairlineIvory),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DrawerNavTile(
                      icon: Icons.security_outlined,
                      title: 'Conta & Segurança',
                      subtitle: 'Dados pessoais, sessão e exclusão (RN04)',
                      onTap: widget.onOpenAccount,
                    ),
                    if (kDemoMode && widget.onResetDemo != null)
                      _DrawerNavTile(
                        icon: Icons.restart_alt_rounded,
                        title: 'Restaurar Dados da Demo',
                        subtitle: 'Modo offline ativo • reiniciar acervo e looks',
                        onTap: widget.onResetDemo!,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerBadge extends StatelessWidget {
  final String label;
  final Color? dotColor;

  const _DrawerBadge({required this.label, this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairlineIvory, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.hairlineIvory, width: 0.6),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTypography.bodySmall(color: AppColors.ivoryText).copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DrawerNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(icon, color: AppColors.gildedLeaf, size: 22),
      title: Text(
        title,
        style: AppTypography.uiHeadline(color: AppColors.ivoryText).copyWith(fontSize: 14.5),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall(color: AppColors.ivoryMuted).copyWith(fontSize: 12),
      ),
      onTap: onTap,
    );
  }
}

enum _CaptureOption { scanItem, storeMirror, shareEditorial }

/// Bandeja de captura e criação rápida: 2 toques até a câmera (RNF06)
class _CaptureTray extends StatelessWidget {
  const _CaptureTray();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin, 12, AppSpacing.pageMargin, 12),
      decoration: const BoxDecoration(
        color: AppColors.paperBone,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLarge)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.hairlineInk,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('AÇÃO RÁPIDA', style: AppTypography.atelierMeta(color: AppColors.gildedInk)),
            const SizedBox(height: 4),
            Text(
              'O que vamos fazer agora?',
              style: AppTypography.sectionDisplay(color: AppColors.inkText).copyWith(fontSize: 24),
            ),
            const SizedBox(height: 20),
            const _TrayOption(
              option: _CaptureOption.scanItem,
              icon: Icons.photo_camera_outlined,
              title: 'Digitalizar peça',
              subtitle: 'Foto, recorte semântico e catalogação no acervo',
            ),
            const Divider(height: 1, thickness: 0.6, color: AppColors.hairlineInk),
            const _TrayOption(
              option: _CaptureOption.storeMirror,
              icon: Icons.center_focus_strong_outlined,
              title: 'Modo Provador',
              subtitle: 'Paridade da peça da loja com o seu armário',
            ),
            const Divider(height: 1, thickness: 0.6, color: AppColors.hairlineInk),
            const _TrayOption(
              option: _CaptureOption.shareEditorial,
              icon: Icons.add_photo_alternate_outlined,
              title: 'Publicar no Editorial',
              subtitle: 'Compartilhar look na galeria comunitária',
            ),
          ],
        ),
      ),
    );
  }
}

class _TrayOption extends StatelessWidget {
  final _CaptureOption option;
  final IconData icon;
  final String title;
  final String subtitle;

  const _TrayOption({
    required this.option,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context, option);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.inkText),
            const SizedBox(width: AppSpacing.elementGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.uiHeadline()),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodySmall()),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, size: 16, color: AppColors.inkSecondary),
          ],
        ),
      ),
    );
  }
}
