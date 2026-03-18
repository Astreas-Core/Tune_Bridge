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
  final bool embedded;
  final EdgeInsetsGeometry? margin;

  const MiniPlayer({
    super.key,
    this.embedded = false,
    this.margin,
  });

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
          previous.duration != current.duration,
      builder: (context, state) {
        if (!state.hasTrack || state.currentTrack == null) {
          return const SizedBox.shrink();
        }

        final track = state.currentTrack!;

        final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Hero(
                  tag: 'art-${track.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      width: 44,
                      height: 44,
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Marquee(
                        child: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFEBFFE2),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFB9CCB2),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _PillControlButton(
                  icon: Icons.skip_previous_rounded,
                  onTap: () => context.read<PlayerBloc>().add(const PlayerPrevious()),
                ),
                const SizedBox(width: 4),
                state.isLoading
                    ? const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00FF41),
                        ),
                      )
                    : _PillControlButton(
                        icon: state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        isPrimary: true,
                        onTap: () {
                          context.read<PlayerBloc>().add(
                                state.isPlaying
                                    ? const PlayerPause()
                                    : const PlayerResume(),
                              );
                        },
                      ),
                const SizedBox(width: 4),
                _PillControlButton(
                  icon: Icons.skip_next_rounded,
                  onTap: () => context.read<PlayerBloc>().add(const PlayerNext()),
                ),
              ],
            ),
            const SizedBox(height: 6),
            BlocBuilder<PlayerBloc, ps.PlayerState>(
              buildWhen: (previous, current) => previous.position != current.position,
              builder: (context, positionState) {
                final durationMillis = state.duration.inMilliseconds;
                final positionMillis = positionState.position.inMilliseconds;
                final progress = durationMillis > 0
                    ? (positionMillis / durationMillis).clamp(0.0, 1.0)
                    : 0.0;

                return Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor:
                              const Color(0xFFB9CCB2).withValues(alpha: 0.22),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Color(0xFF00FF41)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(positionState.position),
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB9CCB2),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.nowPlaying),
          child: Container(
            margin: margin ?? const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: embedded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
                    child: content,
                  )
                : GlassPanel(
                    borderRadius: BorderRadius.circular(40),
                    blur: 0,
                    color: const Color(0xFF151515),
                    borderColor: const Color(0x2400FF41),
                    padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                    child: content,
                  ),
          ),
        );
      },
    );
  }

  Widget _artPlaceholder() {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: const Color(0xFFB9CCB2).withValues(alpha: 0.75),
          size: 20,
        ),
      ),
    );
  }
}

class _PillControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _PillControlButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFF00FF41) : const Color(0xFF242424),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isPrimary ? const Color(0x6000FF41) : const Color(0x22FFFFFF),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isPrimary ? const Color(0xFF003907) : const Color(0xFFEBFFE2),
          ),
        ),
      ),
    );
  }
}
