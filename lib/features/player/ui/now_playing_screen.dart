import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/models/track_model.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/features/player/bloc/player_bloc.dart';
import 'package:tune_bridge/features/player/bloc/player_event.dart';
import 'package:tune_bridge/features/player/bloc/player_state.dart' as ps;
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';

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

  LocalLibraryService get _library => getIt<LocalLibraryService>();

  void _syncTrackFlags(TrackModel track) {
    if (_syncedTrackId == track.id) return;
    _syncedTrackId = track.id;
    _isLiked = _library.isLiked(track.id);
    _isDownloaded = _library.isOffline(track.id);
    _isDownloading = false;
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
    await _library.addOfflineSong(track);

    if (!mounted) return;
    setState(() {
      _isDownloading = false;
      _isDownloaded = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved for offline listening')),
    );
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -280) {
      context.read<PlayerBloc>().add(const PlayerNext());
    } else if (velocity > 280) {
      context.read<PlayerBloc>().add(const PlayerPrevious());
    }
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
          previous.shuffleEnabled != current.shuffleEnabled ||
          previous.repeatEnabled != current.repeatEnabled ||
          previous.queue != current.queue ||
          previous.queueIndex != current.queueIndex,
      builder: (context, state) {
        final track = state.currentTrack;
        if (track == null) {
          return const Scaffold(
            backgroundColor: GlassColors.background,
            body: Center(
              child: CircularProgressIndicator(color: GlassColors.accent),
            ),
          );
        }

        _syncTrackFlags(track);

        return Scaffold(
          backgroundColor: GlassColors.background,
          body: GestureDetector(
            onHorizontalDragEnd: _onHorizontalDragEnd,
            onVerticalDragEnd: (details) => _onVerticalDragEnd(details, state),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0B0B0F), Color(0xFF111A23), Color(0xFF0B0B0F)],
                ),
              ),
              child: SafeArea(
                child: Column(
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
                                  style: GoogleFonts.splineSans(
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
                                  style: GoogleFonts.splineSans(
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
                                      Text(
                                        track.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.splineSans(
                                          color: GlassColors.textPrimary,
                                          fontSize: 23,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        track.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.splineSans(
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
                                  previous.shuffleEnabled != current.shuffleEnabled ||
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDuration(
                                              Duration(seconds: sliderValue.toInt()),
                                            ),
                                            style: GoogleFonts.splineSans(
                                              color: GlassColors.textSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            _formatDuration(
                                              Duration(seconds: durationSeconds),
                                            ),
                                            style: GoogleFonts.splineSans(
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
                                          icon: Icons.shuffle_rounded,
                                          isActive: liveState.shuffleEnabled,
                                          onTap: () => context
                                              .read<PlayerBloc>()
                                              .add(const PlayerToggleShuffle()),
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
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _BottomLabelButton(
                                  icon: Icons.graphic_eq_rounded,
                                  label: 'EQ',
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Equalizer support is coming soon')),
                                    );
                                  },
                                ),
                                _BottomLabelButton(
                                  icon: Icons.nightlight_round,
                                  label: 'Sleep',
                                  onTap: () => _showSleepTimer(context),
                                ),
                                _BottomLabelButton(
                                  icon: Icons.more_horiz_rounded,
                                  label: 'More',
                                  onTap: () => _showMoreOptions(context, track),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
                  style: GoogleFonts.splineSans(
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
                          style: GoogleFonts.splineSans(
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
                          style: GoogleFonts.splineSans(
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

  void _showSleepTimer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassPanel(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        color: const Color(0xCC0D121B),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sleep Timer',
                style: GoogleFonts.splineSans(
                  color: GlassColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              for (final option in const ['15 minutes', '30 minutes', '1 hour', 'End of track'])
                ListTile(
                  title: Text(
                    option,
                    style: GoogleFonts.splineSans(color: GlassColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sleep timer set for $option')),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, TrackModel track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassPanel(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        color: const Color(0xCC0D121B),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.splineSans(
                  color: GlassColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: GlassColors.textPrimary),
                title: Text('Share', style: GoogleFonts.splineSans(color: GlassColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share action triggered')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.album_rounded, color: GlassColors.textPrimary),
                title: Text('View album', style: GoogleFonts.splineSans(color: GlassColors.textPrimary)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: GlassColors.textPrimary),
                title: Text('Song details', style: GoogleFonts.splineSans(color: GlassColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF121922),
                      title: Text(
                        track.title,
                        style: GoogleFonts.splineSans(color: GlassColors.textPrimary),
                      ),
                      content: Text(
                        'Artist: ${track.artist}\nAlbum: ${track.albumName}',
                        style: GoogleFonts.splineSans(color: GlassColors.textSecondary),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
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
            colors: [Color(0xFF13D6FF), Color(0xFF00AFC8)],
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
          color: const Color(0xFF03131A),
          size: 42,
        ),
      ),
    );
  }
}

class _BottomLabelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomLabelButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: GlassColors.textSecondary),
      label: Text(
        label,
        style: GoogleFonts.splineSans(
          color: GlassColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

