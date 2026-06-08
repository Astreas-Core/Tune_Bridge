import 'package:tune_bridge/core/theme.dart';
import 'dart:math' as math;

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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _artwork(context, track),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Marquee(
                        child: Text(
                          track.title,
                          softWrap: false,
                          style: GoogleFonts.inter(
                            color: context.textPrimaryColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: context.textSecondaryColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PillControlButton(
                      icon: Icons.skip_previous_rounded,
                      onTap: () => context.read<PlayerBloc>().add(const PlayerPrevious()),
                    ),
                    SizedBox(width: 6),
                    state.isLoading
                        ? const _CuteMiniLoading()
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
                    SizedBox(width: 6),
                    _PillControlButton(
                      icon: Icons.skip_next_rounded,
                      onTap: () => context.read<PlayerBloc>().add(const PlayerNext()),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
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
                              context.textSecondaryColor.withValues(alpha: 0.22),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(context.primaryColor),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      _formatDuration(positionState.position),
                      style: GoogleFonts.inter(
                        color: context.textSecondaryColor,
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
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
                    child: content,
                  )
                : GlassPanel(
                    borderRadius: BorderRadius.circular(40),
                    blur: 0,
                    color: Color(0xFF151515),
                    borderColor: context.primaryColor.withValues(alpha: 0.14),
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                    child: content,
                  ),
          ),
        );
      },
    );
  }

  Widget _artPlaceholder(BuildContext context) {
    return Container(
      color: Color(0xFF2A2A2A),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: context.textSecondaryColor.withValues(alpha: 0.75),
          size: 20,
        ),
      ),
    );
  }

  Widget _artwork(BuildContext context, dynamic track) {
    final artwork = ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
      width: 42,
      height: 42,
        child: track.albumArtUrl != null
            ? CachedNetworkImage(
                imageUrl: track.albumArtUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _artPlaceholder(context),
                errorWidget: (_, __, ___) => _artPlaceholder(context),
              )
            : _artPlaceholder(context),
      ),
    );

    if (embedded) {
      return artwork;
    }

    return Hero(
      tag: 'art-${track.id}',
      child: artwork,
    );
  }
}

class _CuteMiniLoading extends StatefulWidget {
  const _CuteMiniLoading();

  @override
  State<_CuteMiniLoading> createState() => _CuteMiniLoadingState();
}

class _CuteMiniLoadingState extends State<_CuteMiniLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final phase = _controller.value * 6.283185307179586;
          double level(double offset) => (math.sin(phase + offset) + 1) / 2;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar(level(0.0)),
              SizedBox(width: 2),
              _bar(level(1.6)),
              SizedBox(width: 2),
              _bar(level(3.2)),
            ],
          );
        },
      ),
    );
  }

  Widget _bar(double t) {
    final height = 8.0 + (t * 12.0);
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.45 + (t * 0.55)),
        borderRadius: BorderRadius.circular(3),
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
            width: isPrimary ? 36 : 32,
            height: isPrimary ? 36 : 32,
          decoration: BoxDecoration(
            color: isPrimary ? context.primaryColor : Color(0xFF242424),
              borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPrimary ? context.primaryColor.withValues(alpha: 0.38) : context.textPrimaryColor.withValues(alpha: 0.13),
            ),
          ),
          child: Icon(
            icon,
              size: isPrimary ? 20 : 18,
            color: isPrimary ? context.colorScheme.onPrimary : context.textPrimaryColor,
          ),
        ),
      ),
    );
  }
}
