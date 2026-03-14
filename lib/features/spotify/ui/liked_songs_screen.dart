import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/neumorphic.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/features/library/bloc/liked_songs_bloc.dart';
import 'package:tune_bridge/features/library/bloc/liked_songs_event.dart';
import 'package:tune_bridge/features/library/bloc/liked_songs_state.dart';
import 'package:tune_bridge/features/player/bloc/player_bloc.dart';
import 'package:tune_bridge/features/player/bloc/player_event.dart';
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
      backgroundColor: Neumorphic.background,
      appBar: AppBar(
        backgroundColor: Neumorphic.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Neumorphic.textMedium),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Liked Songs',
          style: GoogleFonts.splineSans(
            color: Neumorphic.textDark,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<LikedSongsBloc, LikedSongsState>(
        builder: (context, state) {
          if (state is LikedSongsLoading) {
            return Center(
              child: CircularProgressIndicator(color: Neumorphic.accent),
            );
          }

          if (state is LikedSongsLoaded) {
            final tracks = state.tracks;
            if (tracks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: Neumorphic.inset(
                        radius: 50,
                        blurRadius: 10,
                        offset: const Offset(5, 5),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 40,
                        color: Neumorphic.textLight.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No liked songs yet',
                      style: GoogleFonts.splineSans(
                        color: Neumorphic.textMedium,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: Neumorphic.raised(
                          radius: 30,
                          blurRadius: 16,
                          offset: const Offset(8, 8),
                          color: Neumorphic.accent.withOpacity(0.1),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.favorite_rounded,
                            size: 60,
                            color: Neumorphic.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = tracks[index];
                        return SongTile(
                          title: track.title,
                          artist: track.artist,
                          albumArtUrl: track.albumArtUrl,
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
                      childCount: tracks.length,
                    ),
                  ),
                ),
              ],
            );
          }

          if (state is LikedSongsError) {
             return Center(
              child: Text(
                'Error loading liked songs',
                style: GoogleFonts.splineSans(color: Neumorphic.textMedium),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
