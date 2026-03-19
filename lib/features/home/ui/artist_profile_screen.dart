import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/constants.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/models/track_model.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/youtube_service.dart';
import 'package:tune_bridge/features/player/bloc/player_bloc.dart';
import 'package:tune_bridge/features/player/bloc/player_event.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';

class ArtistProfileScreen extends StatefulWidget {
  final String artistName;
  final List<TrackModel> tracks;

  const ArtistProfileScreen({
    super.key,
    required this.artistName,
    required this.tracks,
  });

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  late final Future<List<TrackModel>> _tracksFuture;
  final YouTubeService _youtubeService = getIt<YouTubeService>();

  @override
  void initState() {
    super.initState();
    _tracksFuture = _loadArtistTracks();
  }

  Future<List<TrackModel>> _loadArtistTracks() async {
    final merged = <String, TrackModel>{};

    for (final track in widget.tracks) {
      merged[_key(track)] = track;
    }

    final searched = await _youtubeService.search('${widget.artistName} songs');
    for (final track in searched) {
      final haystack =
          '${track.artist.toLowerCase()} ${track.title.toLowerCase()} ${track.albumName.toLowerCase()}';
      if (!haystack.contains(widget.artistName.toLowerCase())) continue;
      merged.putIfAbsent(_key(track), () => track);
    }

    final all = merged.values.toList(growable: false);
    all.sort((a, b) {
      final artistA = a.artist.toLowerCase().contains(widget.artistName.toLowerCase());
      final artistB = b.artist.toLowerCase().contains(widget.artistName.toLowerCase());
      if (artistA != artistB) return artistA ? -1 : 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return all;
  }

  String _key(TrackModel track) {
    return '${track.id}::${track.title.toLowerCase().trim()}::${track.artist.toLowerCase().trim()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassColors.background,
      appBar: AppBar(
        backgroundColor: GlassColors.background,
        elevation: 0,
        title: Text(
          widget.artistName,
          style: GoogleFonts.inter(
            color: GlassColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: FutureBuilder<List<TrackModel>>(
        future: _tracksFuture,
        builder: (context, snapshot) {
          final uniqueTracks = snapshot.data ?? const <TrackModel>[];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF41)),
            );
          }

          if (uniqueTracks.isEmpty) {
            return Center(
              child: Text(
                'No songs found for this artist',
                style: GoogleFonts.inter(
                  color: GlassColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              120,
            ),
            itemCount: uniqueTracks.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final track = uniqueTracks[index];
              return InkWell(
                borderRadius: BorderRadius.circular(AppRadii.md),
                onTap: () {
                  context.read<PlayerBloc>().add(
                        PlayerPlayTrack(
                          track: track,
                          queue: uniqueTracks,
                          queueIndex: index,
                        ),
                      );
                  Navigator.pushNamed(context, AppRoutes.nowPlaying);
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1B1B),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: track.albumArtUrl == null
                              ? Container(
                                  color: const Color(0xFF252525),
                                  child: const Icon(
                                    Icons.music_note_rounded,
                                    color: GlassColors.textSecondary,
                                  ),
                                )
                              : Image.network(
                                  track.albumArtUrl!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: GlassColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.albumName.isNotEmpty ? track.albumName : track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: GlassColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        color: Color(0xFF00FF41),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
