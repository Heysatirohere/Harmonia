import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'community_feed_screen.dart';
import 'daily_outfit_screen.dart';
import 'profile_screen.dart';

/// Sistema de Navegação Provisório & Simples do HarmonIA
///
/// Permite alternar rapidamente entre as interfaces principais do MVP:
/// - Daily Outfit (Sugestão Diária com Clima RF16)
/// - Feed Comunitário (Editorial Gallery)
/// - Perfil (Acervo Pessoal)
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    DailyOutfitScreen(),
    CommunityFeedScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.borderSubtle,
              width: 0.8,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          backgroundColor: AppColors.surfaceCanvas,
          selectedItemColor: AppColors.accentTerracotta,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarThemeData(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'Curadoria',
            ),
            BottomNavigationBarThemeData(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Editorial',
            ),
            BottomNavigationBarThemeData(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Ateliê',
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavigationBarThemeData extends BottomNavigationBarItem {
  const BottomNavigationBarThemeData({
    required Widget icon,
    Widget? activeIcon,
    required String label,
  }) : super(
          icon: icon,
          activeIcon: activeIcon,
          label: label,
        );
}
