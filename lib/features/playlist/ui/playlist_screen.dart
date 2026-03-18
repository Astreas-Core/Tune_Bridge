import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/features/library/bloc/playlist_detail_bloc.dart';
import 'package:tune_bridge/features/library/bloc/playlist_detail_event.dart';
import 'package:tune_bridge/features/library/bloc/playlist_detail_state.dart';
import 'package:tune_bridge/features/player/bloc/player_bloc.dart';
import 'package:tune_bridge/features/player/bloc/player_event.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';
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
        backgroundColor: GlassColors.background,
        body: BlocBuilder<PlaylistDetailBloc, PlaylistDetailState>(
          builder: (context, state) {
            if (state is PlaylistDetailLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00FF41)),
              );
            }

            if (state is PlaylistDetailLoaded) {
              return SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Color(0xFF00FF41),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Playlist.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFEBFFE2),
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                        child: GlassPanel(
                          blur: 0,
                          borderRadius: BorderRadius.circular(22),
                          color: const Color(0xFF161616),
                          borderColor: const Color(0x22FFFFFF),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  width: 78,
                                  height: 78,
                                  child: playlistImageUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: playlistImageUrl!,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => _placeholder(),
                                        )
                                      : _placeholder(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      playlistName ?? 'Playlist',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFEBFFE2),
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${state.tracks.length} tracks',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFB9CCB2),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00FF41),
                                  borderRadius: BorderRadius.circular(21),
                                ),
                                child: const Icon(
                                  Icons.queue_music_rounded,
                                  color: Color(0xFF03290C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (state.tracks.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No tracks in this playlist',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFB9CCB2),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
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
                              heroTag: 'playlist-art-${track.id}',
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
                ),
              );
            }

            if (state is PlaylistDetailError) {
              return Center(
                child: Text(
                  'Error loading playlist',
                  style: GoogleFonts.inter(color: const Color(0xFFB9CCB2)),
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
      color: const Color(0xFF2A2A2A),
      child: Center(
        child: Icon(
          Icons.queue_music_rounded,
          size: 60,
          color: const Color(0xFFB9CCB2),
        ),
      ),
    );
  }
}
