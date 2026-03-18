import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/features/library/bloc/liked_songs_bloc.dart';
import 'package:tune_bridge/features/library/bloc/liked_songs_event.dart';
import 'package:tune_bridge/features/library/bloc/liked_songs_state.dart';
import 'package:tune_bridge/features/player/bloc/player_bloc.dart';
import 'package:tune_bridge/features/player/bloc/player_event.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';
import 'package:tune_bridge/ui/widgets/song_tile.dart';

class LikedSongsScreen extends StatelessWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LikedSongsBloc(
        getIt<LocalLibraryService>(),
      )..add(const LikedSongsRequested()),
      child: const _LikedSongsView(),
    );
  }
}

class _LikedSongsView extends StatelessWidget {
  const _LikedSongsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassColors.background,
      body: BlocBuilder<LikedSongsBloc, LikedSongsState>(
        builder: (context, state) {
          if (state is LikedSongsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: GlassColors.accent),
            );
          }

          if (state is LikedSongsLoaded) {
            final tracks = state.tracks;
            if (tracks.isEmpty) {
              return _BaseShell(
                child: _EmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: 'No liked songs yet',
                  subtitle: 'Songs you like will appear here.',
                ),
              );
            }

            return _BaseShell(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                      child: GlassPanel(
                        blur: 8,
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0x44121A24),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0x3300D7FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0x5500D7FF)),
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: GlassColors.accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Liked Songs',
                                    style: GoogleFonts.splineSans(
                                      color: GlassColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                    ),
                                  ),
                                  Text(
                                    '${tracks.length} tracks',
                                    style: GoogleFonts.splineSans(
                                      color: GlassColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<PlayerBloc>().add(
                                      PlayerPlayTrack(
                                        track: tracks.first,
                                        queue: tracks,
                                        queueIndex: 0,
                                      ),
                                    );
                                Navigator.pushNamed(context, AppRoutes.nowPlaying);
                              },
                              child: Text(
                                'Play',
                                style: GoogleFonts.splineSans(
                                  color: GlassColors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return SongTile(
                        title: track.title,
                        artist: track.artist,
                        albumArtUrl: track.albumArtUrl,
                        heroTag: 'art-${track.id}',
                        onTap: () {
                          context.read<PlayerBloc>().add(
                                PlayerPlayTrack(
                                  track: track,
                                  queue: tracks,
                                  queueIndex: index,
                                ),
                              );
                          Navigator.pushNamed(context, AppRoutes.nowPlaying);
                        },
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            );
          }

          if (state is LikedSongsError) {
            return const _BaseShell(
              child: _EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Could not load liked songs',
                subtitle: 'Please try again in a moment.',
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _BaseShell extends StatelessWidget {
  final Widget child;

  const _BaseShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: GlassColors.textPrimary,
                  ),
                ),
                Text(
                  'Liked Songs',
                  style: GoogleFonts.splineSans(
                    color: GlassColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassPanel(
        blur: 8,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: GlassColors.textSecondary),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.splineSans(
                color: GlassColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.splineSans(
                color: GlassColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
