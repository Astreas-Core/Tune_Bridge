import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/neumorphic.dart';
import 'package:tune_bridge/core/routes.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neumorphic.background,
      appBar: AppBar(
        title: Text(
          'Your Library', 
          style: GoogleFonts.splineSans(
            color: Neumorphic.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false, 
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          _buildLibraryTile(
            title: 'Liked Songs',
            icon: Icons.favorite_rounded,
            onTap: () => Navigator.pushNamed(context, AppRoutes.likedSongs),
          ),
          const SizedBox(height: 16),
          _buildLibraryTile(
            title: 'Playlists',
            icon: Icons.queue_music_rounded,
            onTap: () => Navigator.pushNamed(context, AppRoutes.playlistsList),
          ),
          const SizedBox(height: 16),
          _buildLibraryTile(
            title: 'Offline Songs',
            icon: Icons.offline_pin_rounded,
            onTap: () => Navigator.pushNamed(context, AppRoutes.offlineSongs),
          ),
          const SizedBox(height: 16),
          _buildLibraryTile(
            title: 'Import',
            icon: Icons.move_to_inbox_rounded,
            onTap: () => Navigator.pushNamed(context, AppRoutes.import_),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLibraryTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: Neumorphic.raised(
          radius: 16,
          blurRadius: 10,
          offset: const Offset(4, 4),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Neumorphic.background,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Neumorphic.shadowDark.withOpacity(0.1),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(icon, color: Neumorphic.accent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.splineSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Neumorphic.textDark,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Neumorphic.textLight),
          ],
        ),
      ),
    );
  }
}
