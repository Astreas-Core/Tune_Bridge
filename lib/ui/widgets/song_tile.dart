import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/constants.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';

class SongTile extends StatelessWidget {
  final String title;
  final String artist;
  final String? albumArtUrl;
  final String? heroTag;
  final VoidCallback? onTap;
  final VoidCallback? onMorePressed;
  final bool isPlaying;

  const SongTile({
    super.key,
    required this.title,
    required this.artist,
    this.albumArtUrl,
    this.heroTag,
    this.onTap,
    this.onMorePressed,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final artwork = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: SizedBox(
        width: 52,
        height: 52,
        child: albumArtUrl != null
            ? CachedNetworkImage(
                imageUrl: albumArtUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _artPlaceholder(),
              )
            : _artPlaceholder(),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      child: GlassPanel(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        blur: 0,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        color: isPlaying ? const Color(0x33203B45) : const Color(0x33171B24),
        borderColor: isPlaying ? const Color(0x5500D7FF) : const Color(0x22FFFFFF),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Row(
            children: [
              heroTag != null ? Hero(tag: heroTag!, child: artwork) : artwork,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.splineSans(
                        color: GlassColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.splineSans(
                        color: GlassColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPlaying)
                const Icon(Icons.graphic_eq_rounded, color: GlassColors.accent)
              else if (onMorePressed != null)
                IconButton(
                  onPressed: onMorePressed,
                  icon: const Icon(Icons.more_horiz_rounded, color: GlassColors.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _artPlaceholder() {
    return Container(
      color: const Color(0x33202836),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 24,
          color: GlassColors.textSecondary.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
