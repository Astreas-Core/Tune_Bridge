import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = getIt<LocalLibraryService>();
    final sections = <_LibraryItem>[
      _LibraryItem(
        title: 'Liked Songs',
        subtitle: '${library.likedCount} tracks',
        icon: Icons.favorite_rounded,
        accent: const Color(0xFF00D7FF),
        onTap: () => Navigator.pushNamed(context, AppRoutes.likedSongs),
      ),
      _LibraryItem(
        title: 'Playlists',
        subtitle: '${library.playlistCount} collections',
        icon: Icons.queue_music_rounded,
        accent: const Color(0xFF00B7D4),
        onTap: () => Navigator.pushNamed(context, AppRoutes.playlistsList),
      ),
      _LibraryItem(
        title: 'Offline Songs',
        subtitle: '${library.offlineCount} downloaded',
        icon: Icons.offline_pin_rounded,
        accent: const Color(0xFF00C6B8),
        onTap: () => Navigator.pushNamed(context, AppRoutes.offlineSongs),
      ),
      _LibraryItem(
        title: 'Import',
        subtitle: 'Sync from Spotify / links',
        icon: Icons.move_to_inbox_rounded,
        accent: const Color(0xFF18E0FF),
        onTap: () => Navigator.pushNamed(context, AppRoutes.import_),
      ),
    ];

    return Scaffold(
      backgroundColor: GlassColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Library',
                      style: GoogleFonts.splineSans(
                        color: GlassColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your music, downloads, and playlists in one place.',
                      style: GoogleFonts.splineSans(
                        color: GlassColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _LibraryHeaderStats(),
                  ],
                ),
              ),
            ),
            SliverList.builder(
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final item = sections[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _LibraryTile(item: item),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 140)),
          ],
        ),
      ),
    );
  }
}

class _LibraryHeaderStats extends StatelessWidget {
  const _LibraryHeaderStats();

  @override
  Widget build(BuildContext context) {
    final library = getIt<LocalLibraryService>();

    return GlassPanel(
      blur: 10,
      borderRadius: BorderRadius.circular(20),
      color: const Color(0x44121A24),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _StatBubble(label: 'Liked', value: library.likedCount),
          const SizedBox(width: 10),
          _StatBubble(label: 'Playlists', value: library.playlistCount),
          const SizedBox(width: 10),
          _StatBubble(label: 'Offline', value: library.offlineCount),
        ],
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String label;
  final int value;

  const _StatBubble({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x33182330),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: GoogleFonts.splineSans(
                color: GlassColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.splineSans(
                color: GlassColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  final _LibraryItem item;

  const _LibraryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: GlassPanel(
        blur: 10,
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: item.accent.withValues(alpha: 0.45)),
              ),
              child: Icon(item.icon, color: item.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.splineSans(
                      color: GlassColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.splineSans(
                      color: GlassColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: GlassColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _LibraryItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _LibraryItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });
}
