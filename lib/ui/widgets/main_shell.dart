import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune_bridge/core/neumorphic.dart';
import 'package:tune_bridge/core/theme_cubit.dart';
import 'package:tune_bridge/features/home/ui/home_screen.dart';
import 'package:tune_bridge/features/library/ui/library_screen.dart';
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
    // Watch ThemeCubit to force rebuild
    context.watch<ThemeCubit>();

    final screens = [
      HomeScreen(),
      LibraryScreen(),
    ];

    return Scaffold(
      backgroundColor: Neumorphic.background,
      body: Stack(
        children: [
          // Main Content
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable swipe to change tab
            children: screens,
          ),
          
          // Mini Player (Positioned above bottom nav)
          // Adjust bottom padding based on nav bar height + safe area
          Positioned(
            left: 0,
            right: 0,
            bottom: 80 + MediaQuery.of(context).padding.bottom, // Height of nav bar
            child: const MiniPlayer(),
          ),

          // Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 70 + MediaQuery.of(context).padding.bottom,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Neumorphic.background.withValues(alpha: 0.95), // Slight transparency
                boxShadow: [
                  BoxShadow(
                    color: Neumorphic.shadowDark.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, "Home", 0),
                  _buildNavItem(Icons.library_music_rounded, "Library", 1),
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
    return GestureDetector(
      onTap: () => _onItemTapped(index), // Corrected call
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: isSelected 
              ? Neumorphic.inset(radius: 12) // Pressed effect for selected
              : null, // Flat for unselected
            child: Icon(
              icon,
              color: isSelected ? Neumorphic.textDark : Neumorphic.textLight,
              size: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Neumorphic.textDark : Neumorphic.textLight,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
