import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/constants.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = getIt<LocalLibraryService>();
    final librarySignal = Listenable.merge([
      library.likedSongsListenable,
      library.playlistsListenable,
      library.offlineSongsListenable,
    ]);

    return AnimatedBuilder(
      animation: librarySignal,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF131313),
          body: SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 10, AppSpacing.xl, 160),
              children: [
            Text(
              'Library',
              style: GoogleFonts.inter(
                color: GlassColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 56,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COLLECTION',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFB9CCB2),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Liked Songs',
                        style: GoogleFonts.inter(
                          color: GlassColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 34,
                          letterSpacing: -0.8,
                        ),
                      ),
                      Text(
                        '${library.likedCount} tracks',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFB9CCB2),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.likedSongs),
                  icon: const Icon(Icons.shuffle_rounded, size: 20),
                  label: const Text('SHUFFLE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF41),
                    foregroundColor: const Color(0xFF003907),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            _LibraryRow(
              title: 'Liked Songs',
              subtitle: '${library.likedCount} tracks',
              icon: Icons.favorite_rounded,
              onTap: () => Navigator.pushNamed(context, AppRoutes.likedSongs),
            ),
            _LibraryRow(
              title: 'Playlists',
              subtitle: '${library.playlistCount} collections',
              icon: Icons.queue_music_rounded,
              onTap: () => Navigator.pushNamed(context, AppRoutes.playlistsList),
            ),
            _LibraryRow(
              title: 'Offline Songs',
              subtitle: '${library.offlineCount} downloaded',
              icon: Icons.offline_pin_rounded,
              onTap: () => Navigator.pushNamed(context, AppRoutes.offlineSongs),
            ),
            _LibraryRow(
              title: 'Import Source',
              subtitle: 'Spotify and local files',
              icon: Icons.move_to_inbox_rounded,
              onTap: () => Navigator.pushNamed(context, AppRoutes.import_),
            ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LibraryRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _LibraryRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFF131313),
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(icon, color: const Color(0xFF00E639), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: GlassColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB9CCB2),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_vert_rounded, color: GlassColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
