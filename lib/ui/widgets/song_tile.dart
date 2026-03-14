import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/neumorphic.dart';

class SongTile extends StatelessWidget {
  final String title;
  final String artist;
  final String? albumArtUrl;
  final VoidCallback? onTap;
  final VoidCallback? onMorePressed;
  final bool isPlaying;

  const SongTile({
    super.key,
    required this.title,
    required this.artist,
    this.albumArtUrl,
    this.onTap,
    this.onMorePressed,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: isPlaying
            ? Neumorphic.inset(
                radius: 16,
                blurRadius: 8,
                offset: const Offset(2, 2),
              )
            : Neumorphic.raised(
                radius: 16,
                blurRadius: 8,
                offset: const Offset(3, 3),
              ),
        child: Row(
          children: [
            // Album Art
            Container(
              width: 50,
              height: 50,
              decoration: isPlaying
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Neumorphic.accent.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 0),
                        )
                      ],
                    )
                  : Neumorphic.raised(radius: 10, blurRadius: 4, offset: const Offset(2, 2)), // Using raised style for non-playing
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: albumArtUrl != null
                    ? CachedNetworkImage(
                        imageUrl: albumArtUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _artPlaceholder(),
                      )
                    : _artPlaceholder(),
              ),
            ),
            const SizedBox(width: 16),
            
            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.splineSans(
                      color: isPlaying ? Neumorphic.accent : Neumorphic.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.splineSans(
                      color: Neumorphic.textMedium,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Action / State Icon
            if (isPlaying)
               Icon(Icons.graphic_eq_rounded, color: Neumorphic.accent, size: 24)
            else if (onMorePressed != null)
              GestureDetector(
                onTap: onMorePressed,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: Neumorphic.raised(
                    radius: 18,
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                  child: Icon(Icons.more_vert_rounded,
                      size: 20, color: Neumorphic.textMedium),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _artPlaceholder() {
    return Container(
      color: Neumorphic.background,
      child: Center(
        child: Icon(Icons.music_note_rounded,
            size: 24, color: Neumorphic.textMedium.withValues(alpha: 0.5)),
      ),
    );
  }
}
