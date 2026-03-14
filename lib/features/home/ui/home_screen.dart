import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/neumorphic.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neumorphic.background,
      body: const _HomeTab(), // Removed bottom nav and IndexedStack
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final library = getIt<LocalLibraryService>();
    // final size = MediaQuery.of(context).size;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.graphic_eq, color: Neumorphic.accent, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'TuneBridge',
                    style: GoogleFonts.splineSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Neumorphic.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: Neumorphic.raised(
                    radius: 22,
                    blurRadius: 10,
                    offset: const Offset(4, 4),
                  ).copyWith(
                    color: Neumorphic.background,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Center(
                      child: Icon(Icons.person_outline_rounded, color: Neumorphic.textMedium),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Search Bar
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.search),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: Neumorphic.inset(
                radius: 16,
                blurRadius: 6,
                offset: const Offset(3, 3),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded,
                      color: Neumorphic.textMedium, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Search song, playslist, artist...',
                    style: TextStyle(
                      color: Neumorphic.textMedium,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Your Playlists / Quick Actions
          Text(
            'Your Library',
            style: GoogleFonts.splineSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Neumorphic.textDark,
            ),
          ),
          const SizedBox(height: 16),

          if (library.likedCount == 0 && library.playlistCount == 0)
            const _ImportPrompt()
          else ...[
            _LibraryQuickAction(
              title: 'Liked Songs',
              subtitle: '${library.likedCount} songs',
              icon: Icons.favorite_rounded,
              onTap: () => Navigator.pushNamed(context, AppRoutes.likedSongs),
            ),
            const SizedBox(height: 16),
            _LibraryQuickAction(
              title: 'Your Playlists',
              subtitle: '${library.playlistCount} playlists',
              icon: Icons.queue_music_rounded,
              onTap: () => Navigator.pushNamed(context, AppRoutes.playlistsList),
            ),
          ],
          
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }
}



class _LibraryQuickAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _LibraryQuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: Neumorphic.raised(
          radius: 20,
          blurRadius: 10,
          offset: const Offset(4, 4),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: Neumorphic.inset(
                radius: 25,
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
              child: Icon(icon, color: Neumorphic.accent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.splineSans(
                      color: Neumorphic.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.splineSans(
                      color: Neumorphic.textMedium,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Neumorphic.textMedium.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _ImportPrompt extends StatelessWidget {
  const _ImportPrompt();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.import_),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: Neumorphic.raised(
          radius: 24,
          blurRadius: 12,
          offset: const Offset(6, 6),
        ),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: Neumorphic.circleRaised(
                blurRadius: 10,
                offset: const Offset(5, 5),
              ),
              child: Icon(Icons.add_link_rounded,
                  size: 32, color: Neumorphic.accent),
            ),
            const SizedBox(height: 20),
            Text(
              'Start Listening',
              style: GoogleFonts.splineSans(
                color: Neumorphic.textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Import a playlist or song to get started.',
              textAlign: TextAlign.center,
              style: GoogleFonts.splineSans(
                color: Neumorphic.textMedium,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


