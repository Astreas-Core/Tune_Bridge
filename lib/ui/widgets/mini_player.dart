import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/neumorphic.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/features/player/bloc/player_bloc.dart';
import 'package:tune_bridge/features/player/bloc/player_event.dart';
import 'package:tune_bridge/features/player/bloc/player_state.dart' as ps;
import 'package:tune_bridge/ui/widgets/marquee.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return "--:--";
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, ps.PlayerState>(
      builder: (context, state) {
        if (!state.hasTrack || state.currentTrack == null) {
          return const SizedBox.shrink();
        }

        final track = state.currentTrack!;
        final durationMillis = state.duration.inMilliseconds;
        final positionMillis = state.position.inMilliseconds;

        final progress = durationMillis > 0
            ? (positionMillis / durationMillis).clamp(0.0, 1.0)
            : 0.0;

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.nowPlaying),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: Neumorphic.raised(
              radius: 24,
              blurRadius: 16,
              offset: const Offset(4, 4),
              color: Neumorphic.background,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Album Art
                    Container(
                      width: 48,
                      height: 48,
                      decoration: Neumorphic.inset(
                        radius: 12,
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: track.albumArtUrl != null
                            ? CachedNetworkImage(
                                imageUrl: track.albumArtUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _artPlaceholder(),
                                errorWidget: (_, __, ___) => _artPlaceholder(),
                              )
                            : _artPlaceholder(),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Song Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Marquee(
                            child: Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              style: GoogleFonts.splineSans(
                                color: Neumorphic.textDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.splineSans(
                              color: Neumorphic.textMedium,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Duration
                    Text(
                      _formatDuration(state.position),
                      style: GoogleFonts.splineSans(
                        color: Neumorphic.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Play/Pause Button
                    GestureDetector(
                      onTap: () {
                        context.read<PlayerBloc>().add(
                            state.isPlaying
                                ? const PlayerPause()
                                : const PlayerResume());
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: Neumorphic.raised(
                          radius: 22,
                          blurRadius: 8,
                          offset: const Offset(3, 3),
                        ),
                        child: state.isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Neumorphic.accent,
                                ),
                              )
                            : Icon(
                                state.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 26,
                                color: Neumorphic.textDark,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: Neumorphic.textLight.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(Neumorphic.accent),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _artPlaceholder() {
    return Container(
      color: Neumorphic.background,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: Neumorphic.textLight.withValues(alpha: 0.5),
          size: 20,
        ),
      ),
    );
  }
}
