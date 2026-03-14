import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/neumorphic.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/features/library/bloc/playlist_detail_bloc.dart';
import 'package:tune_bridge/features/library/bloc/playlist_detail_event.dart';
import 'package:tune_bridge/features/library/bloc/playlist_detail_state.dart';
import 'package:tune_bridge/features/player/bloc/player_bloc.dart';
import 'package:tune_bridge/features/player/bloc/player_event.dart';
import 'package:tune_bridge/ui/widgets/song_tile.dart';

class PlaylistScreen extends StatelessWidget {
  final String playlistId;
  final String? playlistName;
  final String? playlistImageUrl;

  const PlaylistScreen({
    super.key,
    required this.playlistId,
    this.playlistName,
    this.playlistImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlaylistDetailBloc(
        getIt<LocalLibraryService>(),
      )..add(PlaylistDetailRequested(playlistId)),
      child: Scaffold(
        backgroundColor: Neumorphic.background,
        appBar: AppBar(
          backgroundColor: Neumorphic.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: Neumorphic.textMedium),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            playlistName ?? 'Playlist',
            style: GoogleFonts.splineSans(
              color: Neumorphic.textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<PlaylistDetailBloc, PlaylistDetailState>(
          builder: (context, state) {
            if (state is PlaylistDetailLoading) {
              return Center(
                  child: CircularProgressIndicator(color: Neumorphic.accent));
            }

            if (state is PlaylistDetailLoaded) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Container(
                            width: 180,
                            height: 180,
                            decoration: Neumorphic.raised(
                              radius: 30,
                              blurRadius: 20,
                              offset: const Offset(10, 10),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: playlistImageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: playlistImageUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => _placeholder(),
                                    )
                                  : _placeholder(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            playlistName ?? 'Playlist',
                            style: GoogleFonts.splineSans(
                              color: Neumorphic.textDark,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${state.tracks.length} tracks',
                            style: GoogleFonts.splineSans(
                              color: Neumorphic.textMedium,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.tracks.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No tracks in this playlist',
                          style: GoogleFonts.splineSans(
                            color: Neumorphic.textMedium,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final track = state.tracks[index];
                          return SongTile(
                            title: track.title,
                            artist: track.artist,
                            albumArtUrl: track.albumArtUrl,
                            onTap: () {
                              context.read<PlayerBloc>().add(
                                    PlayerPlayTrack(
                                      track: track,
                                      queue: state.tracks,
                                      queueIndex: index,
                                    ),
                                  );
                              Navigator.pushNamed(context, AppRoutes.nowPlaying);
                            },
                          );
                        },
                        childCount: state.tracks.length,
                      ),
                    ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
              );
            }

            if (state is PlaylistDetailError) {
              return Center(
                child: Text(
                  'Error loading playlist',
                  style: GoogleFonts.splineSans(color: Neumorphic.textMedium),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Neumorphic.background,
      child: Center(
        child: Icon(
          Icons.queue_music_rounded,
          size: 60,
          color: Neumorphic.textLight.withOpacity(0.5),
        ),
      ),
    );
  }
}
