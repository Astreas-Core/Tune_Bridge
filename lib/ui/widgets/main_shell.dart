import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: screens,
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 76 + MediaQuery.of(context).padding.bottom,
            child: const MiniPlayer(),
          ),

          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: GlassPanel(
              borderRadius: BorderRadius.circular(22),
              blur: 8,
              color: const Color(0xAA0F131B),
              padding: EdgeInsets.fromLTRB(
                8,
                8,
                8,
                8 + MediaQuery.of(context).padding.bottom,
              ),
              child: Row(
                children: [
                  _buildNavItem(Icons.home_rounded, 'Home', 0),
                  _buildNavItem(Icons.search_rounded, 'Search', 1),
                  _buildNavItem(Icons.library_music_rounded, 'Library', 2),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? GlassColors.accent.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? GlassColors.accent : GlassColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? GlassColors.textPrimary : GlassColors.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
