import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/services/wardrobe_api_service.dart';
import '../../mocks/mock_clothes.dart';
import '../../models/clothing_item.dart';
import '../../theme/app_theme.dart';
import '../widgets/editorial_nav_bar.dart';
import 'community_feed_screen.dart';
import 'daily_outfit_screen.dart';
import 'profile_screen.dart';
import 'scan_item_screen.dart';
import 'store_mirror_screen.dart';
import 'wardrobe_screen.dart';

/// Shell principal de navegação editorial do HarmonIA
///
/// Abas: Sugestão, Acervo, Editorial e Ateliê. A ação central abre a
/// bandeja de captura (Digitalizar peça / Modo Provador). Análises,
/// Lacunas, Perfil de estilo e Conta ficam no Ateliê.
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
    EditorialNavDestination(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Ateliê',
    ),
  ];

  static const int wardrobeTab = 1;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex = widget.initialIndex;

  /// Recria o Acervo após uma captura feita fora dele
  int _wardrobeRevision = 0;

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  Future<void> _openCaptureTray() async {
    final action = await showModalBottomSheet<_CaptureOption>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.24),
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
    }
  }

  void _onItemCataloged(ClothingItem item) {
    WardrobeApiService().createClothingItem(item);
    mockClothes.insert(0, item);
    setState(() {
      _wardrobeRevision++;
      _currentIndex = MainNavigationScreen.wardrobeTab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const DailyOutfitScreen(),
          WardrobeScreen(key: ValueKey(_wardrobeRevision)),
          const CommunityFeedScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: EditorialNavBar(
        destinations: MainNavigationScreen.destinations,
        currentIndex: _currentIndex,
        onSelected: _onTabSelected,
        onCapture: _openCaptureTray,
      ),
    );
  }
}

enum _CaptureOption { scanItem, storeMirror }

/// Bandeja de captura: 2 toques até a câmera (RNF06)
class _CaptureTray extends StatelessWidget {
  const _CaptureTray();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin, 12, AppSpacing.pageMargin, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCanvas,
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
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('CAPTURAR', style: AppTypography.metadataBadge(color: AppColors.iheGold)),
            const SizedBox(height: 4),
            Text('O que vamos ver agora?', style: AppTypography.subtitleCuratorial(color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            const _TrayOption(
              option: _CaptureOption.scanItem,
              icon: Icons.photo_camera_outlined,
              title: 'Digitalizar peça',
              subtitle: 'Foto, recorte e catalogação no acervo',
            ),
            const Divider(height: 1, thickness: 0.6, color: AppColors.borderSubtle),
            const _TrayOption(
              option: _CaptureOption.storeMirror,
              icon: Icons.center_focus_strong_outlined,
              title: 'Modo Provador',
              subtitle: 'Paridade da peça da loja com o seu armário',
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textPrimary),
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
            const Icon(Icons.arrow_forward, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
