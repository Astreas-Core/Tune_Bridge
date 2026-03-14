import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/neumorphic.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/features/player/bloc/player_bloc.dart';
import 'package:tune_bridge/features/player/bloc/player_event.dart';
import 'package:tune_bridge/features/player/bloc/player_state.dart' as ps;
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
  
  // Track dragging state to prevent jitter
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  void initState() {
    super.initState();
    final track = context.read<PlayerBloc>().state.currentTrack;
    if (track != null) {
      final s = getIt<LocalLibraryService>();
      _isLiked = s.isLiked(track.id);
      _isDownloaded = s.isOffline(track.id);
    }
  }

  void _toggleLike() {
    final track = context.read<PlayerBloc>().state.currentTrack;
    if (track == null) return;

    setState(() => _isLiked = !_isLiked);
    
    final service = getIt<LocalLibraryService>();
    if (_isLiked) {
      service.addLikedSong(track);
    } else {
      service.removeLikedSong(track.id);
    }
  }

  void _toggleDownload() async {
    final track = context.read<PlayerBloc>().state.currentTrack;
    if (_isDownloaded || track == null) return;

    setState(() => _isDownloading = true);
    
    // Simulate download delay
    await Future.delayed(const Duration(seconds: 1));
    
    final service = getIt<LocalLibraryService>();
    await service.addOfflineSong(track);

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _isDownloaded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Downloaded for offline listening")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, ps.PlayerState>(
      builder: (context, state) {
        final track = state.currentTrack;
        final size = MediaQuery.of(context).size;
        
        // Show skeleton if loading or track is not ready
        // Specifically check duration == zero to detect initial load vs buffering
        if (track == null || (state.isLoading && state.duration == Duration.zero)) {
          return _buildSkeleton(context);
        }
        
        final title = track.title;
        final artist = track.artist;
        final artUrl = track.albumArtUrl;
        
        final durationInSeconds = state.duration.inSeconds;
        final positionInSeconds = state.position.inSeconds;
        
        // Use local drag value while dragging, otherwise use stream position
        double sliderValue = _isDragging ? _dragValue : positionInSeconds.toDouble();
        double maxDuration = durationInSeconds.toDouble();
        if (sliderValue > maxDuration) sliderValue = maxDuration;
        if (maxDuration <= 0) maxDuration = 1.0;

        return Scaffold(
          backgroundColor: Neumorphic.background,
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _NeuIconButton(
                        icon: Icons.keyboard_arrow_down_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      Text(
                        'Now Playing',
                        style: GoogleFonts.splineSans(
                          color: Neumorphic.textMedium,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      _NeuIconButton(
                        icon: Icons.person_rounded,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Album Art
                Container(
                  width: size.width * 0.75,
                  height: size.width * 0.75,
                  decoration: Neumorphic.raised(
                    radius: 40,
                    blurRadius: 30,
                    offset: const Offset(10, 10),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: artUrl != null
                        ? CachedNetworkImage(
                            imageUrl: artUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _artPlaceholder(),
                          )
                        : _artPlaceholder(),
                  ),
                ),

                const SizedBox(height: 40),

                // Title and Artist
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Marquee(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.splineSans(
                            color: Neumorphic.textDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        artist,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.splineSans(
                          color: Neumorphic.textMedium,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Progress Bar (Skippable Slider)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 4),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                          activeTrackColor: Neumorphic.accent,
                          inactiveTrackColor: Neumorphic.textLight.withOpacity(0.3),
                          thumbColor: Neumorphic.accent,
                          overlayColor: Neumorphic.accent.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: sliderValue,
                          min: 0.0,
                          max: maxDuration,
                          onChanged: (value) {
                            setState(() {
                              _isDragging = true;
                              _dragValue = value;
                            });
                          },
                          onChangeEnd: (value) {
                            setState(() {
                              _isDragging = false;
                            });
                            context.read<PlayerBloc>().add(PlayerSeek(Duration(seconds: value.toInt())));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(Duration(seconds: sliderValue.toInt())),
                              style: GoogleFonts.splineSans(
                                color: Neumorphic.textMedium,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatDuration(Duration(seconds: durationInSeconds)),
                              style: GoogleFonts.splineSans(
                                color: Neumorphic.textMedium,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Main Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionButton(
                        icon: _isDownloaded ? Icons.offline_pin_rounded : Icons.download_rounded,
                        isActive: _isDownloaded,
                        isLoading: _isDownloading,
                        onTap: _toggleDownload,
                      ),
                      _NeuControlButton(
                        icon: Icons.skip_previous_rounded,
                        size: 50,
                        onTap: () => context.read<PlayerBloc>().add(const PlayerPrevious()),
                      ),
                      _PlayPauseButton(isPlaying: state.isPlaying),
                      _NeuControlButton(
                        icon: Icons.skip_next_rounded,
                        size: 50,
                        onTap: () => context.read<PlayerBloc>().add(const PlayerNext()),
                      ),
                      _ActionButton(
                        icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        isActive: _isLiked,
                        isLikeButton: true,
                        onTap: _toggleLike,
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Neumorphic.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Top Bar
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NeuIconButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  Text(
                    'Now Playing',
                    style: GoogleFonts.splineSans(
                      color: Neumorphic.textMedium,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  _NeuIconButton(
                    icon: Icons.person_rounded,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Skeleton Art (Pulsing Effect Simulation via Opacity)
            Opacity(
              opacity: 0.6,
              child: Container(
                width: size.width * 0.75,
                height: size.width * 0.75,
                decoration: Neumorphic.raised(
                  radius: 40,
                  blurRadius: 30,
                  offset: const Offset(10, 10),
                  color: Neumorphic.background,
                ),
                child: Center(
                  child: SizedBox(
                   width: 50, height: 50,
                   child: CircularProgressIndicator(
                     color: Neumorphic.textMedium.withOpacity(0.3), 
                     strokeWidth: 2
                   )
                  )
                ),
              ),
            ),

            const SizedBox(height: 40),
            
            // Skeleton Text
            Container(
               width: size.width * 0.5, 
               height: 24, 
               decoration: BoxDecoration(
                 color: Neumorphic.textLight.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(8)
               )
            ),
            const SizedBox(height: 12),
            Container(
               width: size.width * 0.3, 
               height: 16, 
               decoration: BoxDecoration(
                 color: Neumorphic.textLight.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(8)
               )
            ),
            
            const Spacer(),
            
            // Skeleton Controls
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 40),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: List.generate(3, (i) => Container(
                   width: 60, height: 60,
                   decoration: BoxDecoration(
                     color: Neumorphic.textLight.withOpacity(0.05),
                     shape: BoxShape.circle
                   ),
                 )),
               ),
            ),
             const Spacer(),
             const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _artPlaceholder() {
    return Container(
      color: Neumorphic.background,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 80,
          color: Neumorphic.textLight.withOpacity(0.5),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}

class _NeuIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NeuIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: Neumorphic.raised(
          radius: 24,
          blurRadius: 8,
          offset: const Offset(4, 4),
        ),
        child: Icon(icon, color: Neumorphic.textMedium, size: 24),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isLoading;
  final bool isLikeButton; // To optionally color the heart red
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.isActive,
    this.isLoading = false,
    this.isLikeButton = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor = Neumorphic.textMedium;
    if (isActive) {
      iconColor = isLikeButton ? Colors.redAccent : Neumorphic.accent;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: isActive 
          ? Neumorphic.inset(radius: 24, blurRadius: 6, offset: const Offset(2, 2))
          : Neumorphic.raised(radius: 24, blurRadius: 8, offset: const Offset(4, 4)),
        child: Center(
          child: isLoading 
            ? SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(strokeWidth: 2, color: iconColor)
              )
            : Icon(icon, color: iconColor, size: 24),
        ),
      ),
    );
  }
}

class _NeuControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _NeuControlButton({
    required this.icon,
    this.size = 60,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: Neumorphic.raised(
          radius: size / 2,
          blurRadius: 10,
          offset: const Offset(5, 5),
        ),
        child: Icon(icon, color: Neumorphic.textDark, size: 32),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;

  const _PlayPauseButton({required this.isPlaying});

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
      child: Container(
        width: 80,
        height: 80,
        decoration: Neumorphic.raised(
          radius: 40,
          blurRadius: 16,
          offset: const Offset(6, 6),
          color: Neumorphic.accent,
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}
