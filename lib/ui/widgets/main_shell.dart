import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/theme_cubit.dart';
import 'package:tune_bridge/features/home/ui/home_screen.dart';
import 'package:tune_bridge/features/library/ui/library_screen.dart';
import 'package:tune_bridge/features/search/ui/search_screen.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';
import 'package:tune_bridge/ui/widgets/mini_player.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // Removed _screens list to define in build for reactivity

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeCubit>();

    const screens = [
      HomeScreen(),
      SearchScreen(),
      LibraryScreen(),
    ];

    return Scaffold(
      backgroundColor: GlassColors.background,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF040404), Color(0xFF0A0A0D), Color(0xFF040404)],
              ),
            ),
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: screens,
            ),
          ),

          Positioned(
            left: 10,
            right: 10,
            bottom: 6,
            child: GlassPanel(
              borderRadius: BorderRadius.circular(24),
              blur: 0,
              color: const Color(0xCC171717),
              borderColor: const Color(0x2200FF41),
              padding: EdgeInsets.fromLTRB(
                8,
                8,
                8,
                6 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MiniPlayer(
                    embedded: true,
                    margin: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: const Color(0x22FFFFFF),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildNavItem(Icons.home_rounded, 'Home', 0),
                      _buildNavItem(Icons.search_rounded, 'Search', 1),
                      _buildNavItem(Icons.library_music_rounded, 'Library', 2),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF353535)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFFEBFFE2) : const Color(0xFFB9CCB2),
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  color: isSelected ? const Color(0xFFEBFFE2) : const Color(0xFFB9CCB2),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
