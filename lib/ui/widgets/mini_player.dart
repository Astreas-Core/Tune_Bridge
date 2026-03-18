import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/features/player/bloc/player_bloc.dart';
import 'package:tune_bridge/features/player/bloc/player_event.dart';
import 'package:tune_bridge/features/player/bloc/player_state.dart' as ps;
import 'package:tune_bridge/ui/widgets/marquee.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';

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
      buildWhen: (previous, current) =>
          previous.currentTrack?.id != current.currentTrack?.id ||
          previous.isPlaying != current.isPlaying ||
          previous.isLoading != current.isLoading ||
          previous.position != current.position ||
          previous.duration != current.duration,
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
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: GlassPanel(
              borderRadius: BorderRadius.circular(20),
              blur: 8,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'art-${track.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 46,
                            height: 46,
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
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Marquee(
                              child: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                style: GoogleFonts.splineSans(
                                  color: GlassColors.textPrimary,
                                  fontSize: 13.5,
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
                                color: GlassColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.read<PlayerBloc>().add(const PlayerPrevious()),
                        icon: const Icon(Icons.skip_previous_rounded, color: GlassColors.textPrimary),
                      ),
                      state.isLoading
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: GlassColors.accent,
                              ),
                            )
                          : IconButton(
                              onPressed: () {
                                context.read<PlayerBloc>().add(
                                    state.isPlaying ? const PlayerPause() : const PlayerResume());
                              },
                              icon: Icon(
                                state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: GlassColors.textPrimary,
                              ),
                            ),
                      IconButton(
                        onPressed: () => context.read<PlayerBloc>().add(const PlayerNext()),
                        icon: const Icon(Icons.skip_next_rounded, color: GlassColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: GlassColors.textSecondary.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(GlassColors.accent),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatDuration(state.position),
                      style: GoogleFonts.splineSans(
                        color: GlassColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _artPlaceholder() {
    return Container(
      color: const Color(0x33202834),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: GlassColors.textSecondary.withValues(alpha: 0.7),
          size: 20,
        ),
      ),
    );
  }
}
