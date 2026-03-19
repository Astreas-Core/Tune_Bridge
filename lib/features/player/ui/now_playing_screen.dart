import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/models/track_model.dart';
import 'package:tune_bridge/core/services/download_service.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/features/player/bloc/player_bloc.dart';
import 'package:tune_bridge/features/player/bloc/player_event.dart';
import 'package:tune_bridge/features/player/bloc/player_state.dart' as ps;
import 'package:tune_bridge/features/settings/ui/equalizer_screen.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';
import 'package:tune_bridge/ui/widgets/marquee.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool _isLiked = false;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  String? _syncedTrackId;

  bool _isDragging = false;
  double _dragValue = 0;
  String? _ambientTrackId;
  List<Color> _ambientGradient = const [
    Color(0xFF0E0E0E),
    Color(0xFF131313),
    Color(0xFF0E0E0E),
  ];

  LocalLibraryService get _library => getIt<LocalLibraryService>();
  DownloadService get _downloadService => getIt<DownloadService>();

  void _syncTrackFlags(TrackModel track) {
    if (_syncedTrackId == track.id) return;
    _syncedTrackId = track.id;
    _isLiked = _library.isLiked(track.id);
    _isDownloaded = _library.hasPlayableOfflineCopy(track.id);
    _isDownloading = false;
    _updateAmbientGradient(track);
  }

  Future<void> _updateAmbientGradient(TrackModel track) async {
    if (_ambientTrackId == track.id) return;
    _ambientTrackId = track.id;

    if (track.albumArtUrl == null || track.albumArtUrl!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _ambientGradient = const [
          Color(0xFF0E0E0E),
          Color(0xFF131313),
          Color(0xFF0E0E0E),
        ];
      });
      return;
    }

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(track.albumArtUrl!),
        maximumColorCount: 12,
      );

      final Color c1 =
          palette.darkMutedColor?.color ??
          palette.dominantColor?.color ??
          const Color(0xFF14211D);
      final Color c2 =
          palette.vibrantColor?.color ??
          palette.mutedColor?.color ??
          const Color(0xFF17332A);
      final Color c3 =
          palette.lightVibrantColor?.color ??
          palette.lightMutedColor?.color ??
          c2;

      if (!mounted || _ambientTrackId != track.id) return;
      setState(() {
        _ambientGradient = [
          _ambientize(c1, 0.82),
          _ambientize(c2, 0.74),
          _ambientize(c3, 0.60),
        ];
      });
    } catch (_) {
      if (!mounted || _ambientTrackId != track.id) return;
      setState(() {
        _ambientGradient = const [
          Color(0xFF0E0E0E),
          Color(0xFF131313),
          Color(0xFF0E0E0E),
        ];
      });
    }
  }

  Color _ambientize(Color base, double alpha) {
    final darkened = Color.lerp(base, Colors.black, 0.55) ?? base;
    return darkened.withValues(alpha: alpha);
  }

  Future<void> _toggleLike() async {
    final track = context.read<PlayerBloc>().state.currentTrack;
    if (track == null) return;

    setState(() => _isLiked = !_isLiked);
    if (_isLiked) {
      await _library.addLikedSong(track);
    } else {
      await _library.removeLikedSong(track.id);
    }
  }

  Future<void> _toggleDownload() async {
    final track = context.read<PlayerBloc>().state.currentTrack;
    if (track == null || _isDownloaded || _isDownloading) return;

    setState(() => _isDownloading = true);
    final localPath = await _downloadService.downloadTrack(track);

    if (!mounted) return;
    if (localPath == null || localPath.isEmpty) {
      setState(() {
        _isDownloading = false;
        _isDownloaded = _library.hasPlayableOfflineCopy(track.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed. Check network and try again.')),
      );
      return;
    }

    setState(() {
      _isDownloading = false;
      _isDownloaded = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved for offline listening')),
    );
  }

  void _onVerticalDragEnd(DragEndDetails details, ps.PlayerState state) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -260) {
      _showQueue(context, state);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, ps.PlayerState>(
      buildWhen: (previous, current) =>
          previous.currentTrack?.id != current.currentTrack?.id ||
          previous.isPlaying != current.isPlaying ||
          previous.isLoading != current.isLoading ||
          previous.repeatEnabled != current.repeatEnabled ||
          previous.queue != current.queue ||
          previous.queueIndex != current.queueIndex,
      builder: (context, state) {
        final track = state.currentTrack;
        if (track == null || (state.isLoading && !state.isPlaying)) {
          return const _NowPlayingSkeleton();
        }

        _syncTrackFlags(track);

        return Scaffold(
          backgroundColor: GlassColors.background,
          body: GestureDetector(
            onVerticalDragEnd: (details) => _onVerticalDragEnd(details, state),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _ambientGradient,
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.2),
                              radius: 1.05,
                              colors: [
                                Colors.white.withValues(alpha: 0.05),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: GlassColors.textPrimary,
                                  size: 30,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'Now Playing',
                                      style: GoogleFonts.inter(
                                        color: GlassColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    Text(
                                      track.albumName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: GlassColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GlassIconButton(
                                icon: Icons.queue_music_rounded,
                                onTap: () => _showQueue(context, state),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: Container(
                                key: ValueKey(track.id),
                                margin: const EdgeInsets.symmetric(horizontal: 26),
                                child: Hero(
                                  tag: 'art-${track.id}',
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(26),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A202C),
                                          boxShadow: [
                                            BoxShadow(
                                              color: GlassColors.accent.withValues(alpha: 0.16),
                                              blurRadius: 28,
                                              offset: const Offset(0, 16),
                                            ),
                                          ],
                                        ),
                                        child: track.albumArtUrl == null
                                            ? const Icon(
                                                Icons.music_note_rounded,
                                                size: 88,
                                                color: GlassColors.textSecondary,
                                              )
                                            : CachedNetworkImage(
                                                imageUrl: track.albumArtUrl!,
                                                fit: BoxFit.cover,
                                                errorWidget: (_, __, ___) => const Icon(
                                                  Icons.music_note_rounded,
                                                  size: 88,
                                                  color: GlassColors.textSecondary,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                          child: GlassPanel(
                            borderRadius: BorderRadius.circular(28),
                            blur: 10,
                            color: const Color(0x66101722),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Marquee(
                                            child: Text(
                                              track.title,
                                              softWrap: false,
                                              style: GoogleFonts.inter(
                                                color: GlassColors.textPrimary,
                                                fontSize: 23,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            track.artist,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: GlassColors.textSecondary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _SquareActionButton(
                                      icon: _isDownloading
                                          ? null
                                          : (_isDownloaded
                                              ? Icons.download_done_rounded
                                              : Icons.download_rounded),
                                      onTap: _toggleDownload,
                                      loading: _isDownloading,
                                    ),
                                    const SizedBox(width: 8),
                                    _SquareActionButton(
                                      icon: _isLiked
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      onTap: _toggleLike,
                                      active: _isLiked,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                BlocBuilder<PlayerBloc, ps.PlayerState>(
                                  buildWhen: (previous, current) =>
                                      previous.position != current.position ||
                                      previous.duration != current.duration ||
                                      previous.isPlaying != current.isPlaying ||
                                      previous.repeatEnabled != current.repeatEnabled,
                                  builder: (context, liveState) {
                                    final durationSeconds = liveState.duration.inSeconds;
                                    final positionSeconds = liveState.position.inSeconds;

                                    double sliderValue =
                                        _isDragging ? _dragValue : positionSeconds.toDouble();
                                    double maxDuration =
                                        durationSeconds <= 0 ? 1 : durationSeconds.toDouble();
                                    if (sliderValue > maxDuration) sliderValue = maxDuration;

                                    return Column(
                                      children: [
                                        SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            trackHeight: 4,
                                            activeTrackColor: GlassColors.accent,
                                            inactiveTrackColor: GlassColors.textSecondary
                                                .withValues(alpha: 0.22),
                                            thumbColor: GlassColors.textPrimary,
                                            thumbShape: const RoundSliderThumbShape(
                                              enabledThumbRadius: 5,
                                            ),
                                            overlayColor:
                                                GlassColors.accent.withValues(alpha: 0.16),
                                          ),
                                          child: Slider(
                                            value: sliderValue,
                                            min: 0,
                                            max: maxDuration,
                                            onChanged: (value) {
                                              setState(() {
                                                _isDragging = true;
                                                _dragValue = value;
                                              });
                                            },
                                            onChangeEnd: (value) {
                                              setState(() => _isDragging = false);
                                              context.read<PlayerBloc>().add(
                                                    PlayerSeek(
                                                      Duration(seconds: value.toInt()),
                                                    ),
                                                  );
                                            },
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _formatDuration(
                                                  Duration(seconds: sliderValue.toInt()),
                                                ),
                                                style: GoogleFonts.inter(
                                                  color: GlassColors.textSecondary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                _formatDuration(
                                                  Duration(seconds: durationSeconds),
                                                ),
                                                style: GoogleFonts.inter(
                                                  color: GlassColors.textSecondary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            GlassIconButton(
                                              icon: Icons.graphic_eq_rounded,
                                              onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute<void>(
                                                  builder: (_) => const EqualizerScreen(),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            IconButton(
                                              onPressed: () => context
                                                  .read<PlayerBloc>()
                                                  .add(const PlayerPrevious()),
                                              icon: const Icon(
                                                Icons.skip_previous_rounded,
                                                color: GlassColors.textPrimary,
                                                size: 38,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            _PlayButton(isPlaying: liveState.isPlaying),
                                            const SizedBox(width: 6),
                                            IconButton(
                                              onPressed: () => context
                                                  .read<PlayerBloc>()
                                                  .add(const PlayerNext()),
                                              icon: const Icon(
                                                Icons.skip_next_rounded,
                                                color: GlassColors.textPrimary,
                                                size: 38,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            GlassIconButton(
                                              icon: Icons.repeat_rounded,
                                              isActive: liveState.repeatEnabled,
                                              onTap: () => context
                                                  .read<PlayerBloc>()
                                                  .add(const PlayerToggleRepeat()),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showQueue(BuildContext context, ps.PlayerState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, controller) {
          return GlassPanel(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            blur: 10,
            color: const Color(0xCC0D121B),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: GlassColors.textSecondary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Queue',
                  style: GoogleFonts.inter(
                    color: GlassColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: state.queue.length,
                    itemBuilder: (context, index) {
                      final item = state.queue[index];
                      final isCurrent = index == state.queueIndex;
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: item.albumArtUrl == null
                                ? Container(color: const Color(0x33202A36))
                                : CachedNetworkImage(
                                    imageUrl: item.albumArtUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        Container(color: const Color(0x33202A36)),
                                  ),
                          ),
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color:
                                isCurrent ? GlassColors.accent : GlassColors.textPrimary,
                            fontWeight:
                                isCurrent ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          item.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: GlassColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: isCurrent
                            ? const Icon(Icons.graphic_eq_rounded,
                                color: GlassColors.accent)
                            : null,
                        onTap: () {
                          context.read<PlayerBloc>().add(PlayerPlayTrack(
                                track: item,
                                queue: state.queue,
                                queueIndex: index,
                              ));
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}

class _NowPlayingSkeleton extends StatelessWidget {
  const _NowPlayingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassColors.background,
      body: SafeArea(
        child: Shimmer.fromColors(
          baseColor: const Color(0xFF232A33),
          highlightColor: const Color(0xFF2F3B47),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    _skeletonBox(32, 32, radius: 16),
                    const Spacer(),
                    _skeletonBox(92, 14),
                    const Spacer(),
                    _skeletonBox(32, 32, radius: 16),
                  ],
                ),
                const SizedBox(height: 28),
                _skeletonBox(double.infinity, 330, radius: 26),
                const SizedBox(height: 26),
                Align(alignment: Alignment.centerLeft, child: _skeletonBox(220, 24)),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerLeft, child: _skeletonBox(150, 14)),
                const SizedBox(height: 22),
                _skeletonBox(double.infinity, 4, radius: 3),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _skeletonBox(44, 44, radius: 22),
                    _skeletonBox(54, 54, radius: 27),
                    _skeletonBox(76, 76, radius: 38),
                    _skeletonBox(54, 54, radius: 27),
                    _skeletonBox(44, 44, radius: 22),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _skeletonBox(double width, double height, {double radius = 10}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SquareActionButton extends StatelessWidget {
  final IconData? icon;
  final VoidCallback onTap;
  final bool active;
  final bool loading;

  const _SquareActionButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? GlassColors.accent.withValues(alpha: 0.16) : const Color(0x221D2530),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? GlassColors.accent.withValues(alpha: 0.6) : const Color(0x22FFFFFF),
          ),
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: GlassColors.accent,
                ),
              )
            : Icon(
                icon,
                color: active ? GlassColors.accent : GlassColors.textPrimary,
              ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool isPlaying;

  const _PlayButton({required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isPlaying) {
          context.read<PlayerBloc>().add(const PlayerPause());
        } else {
          context.read<PlayerBloc>().add(const PlayerResume());
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00FF41), Color(0xFF00E639)],
          ),
          boxShadow: [
            BoxShadow(
              color: GlassColors.accent.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: const Color(0xFF003907),
          size: 42,
        ),
      ),
    );
  }
}

