import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/constants.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/models/track_model.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/features/player/bloc/player_bloc.dart';
import 'package:tune_bridge/features/player/bloc/player_event.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalLibraryService _library = getIt<LocalLibraryService>();
  int _refreshSeed = 0;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _rotationTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (!mounted) return;
      setState(() {
        _refreshSeed++;
      });
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    setState(() {
      _refreshSeed++;
    });
    await _library.getAllKnownTracks();
  }

  @override
  Widget build(BuildContext context) {
    final appRefreshSignal = Listenable.merge([
      _library.likedSongsListenable,
      _library.recentTracksListenable,
      _library.offlineSongsListenable,
      _library.playlistsListenable,
    ]);

    return AnimatedBuilder(
      animation: appRefreshSignal,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: GlassColors.background,
          body: SafeArea(
            child: FutureBuilder<_HomeData>(
              key: ValueKey(
                '$_refreshSeed-${_library.likedCount}-${_library.offlineCount}-${_library.playlistCount}',
              ),
              future: _loadHomeData(),
              builder: (context, snapshot) {
                final recentTracks = _recentTracks();
                final homeData = snapshot.data;
                final topArtists = homeData?.topArtists ?? const <_TopArtist>[];
                final recommendedTracks = homeData?.recommendedTracks ?? recentTracks;

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: const Color(0xFF00FF41),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'TuneBridge',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFEBFFE2),
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: -1.0,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F1F1F),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: GlassColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Curated for your latest listening',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFB9CCB2),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Recommended',
                                style: GoogleFonts.inter(
                                  color: GlassColors.textPrimary,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _onRefresh,
                              child: Text(
                                'REFRESH',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF00FF41),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 260,
                    child: recommendedTracks.isEmpty
                        ? const _EmptyRecommendations()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                            scrollDirection: Axis.horizontal,
                            itemCount: recommendedTracks.length,
                            itemBuilder: (context, index) {
                              final track = recommendedTracks[index];
                              return _RecommendationCard(
                                track: track,
                                isLarge: index == 0,
                                onTap: () {
                                  context.read<PlayerBloc>().add(
                                        PlayerPlayTrack(
                                          track: track,
                                          queue: recommendedTracks,
                                          queueIndex: index,
                                        ),
                                  );
                                  Navigator.pushNamed(context, AppRoutes.nowPlaying);
                                },
                              );
                            },
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm + 2, AppSpacing.xl, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Top Artists',
                            style: GoogleFonts.inter(
                              color: GlassColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _onRefresh,
                          child: Text(
                            'REFRESH',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF00FF41),
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 222,
                    child: topArtists.isEmpty
                        ? const _EmptyTopArtists()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                            scrollDirection: Axis.horizontal,
                            itemCount: topArtists.length,
                            itemBuilder: (context, index) {
                              final artist = topArtists[index];
                              return _TopArtistCard(
                                artist: artist,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.artistProfile,
                                    arguments: {
                                      'artist': artist.name,
                                      'tracks': artist.tracks,
                                    },
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm + 2, AppSpacing.xl, 6),
                    child: Text(
                      'Recently Played',
                      style: GoogleFonts.inter(
                        color: GlassColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: recentTracks.length,
                  itemBuilder: (context, index) {
                    final track = recentTracks[index];
                    return _TrackRow(
                      track: track,
                      onTap: () {
                        context.read<PlayerBloc>().add(
                              PlayerPlayTrack(
                                track: track,
                                queue: recentTracks,
                                queueIndex: index,
                              ),
                            );
                        Navigator.pushNamed(context, AppRoutes.nowPlaying);
                      },
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 160)),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<_HomeData> _loadHomeData() async {
    final results = await Future.wait<dynamic>([
      _library.getPersonalizedRecommendations(limit: 10, seed: _refreshSeed),
      _loadTopArtists(),
    ]);
    return _HomeData(
      recommendedTracks: (results[0] as List<TrackModel>),
      topArtists: (results[1] as List<_TopArtist>),
    );
  }

  Future<List<_TopArtist>> _loadTopArtists() async {
    final tracks = await _library.getAllKnownTracks();
    if (tracks.isEmpty) {
      return const <_TopArtist>[];
    }

    final byArtist = <String, List<TrackModel>>{};
    final displayNameByKey = <String, String>{};

    for (final track in tracks) {
      final rawArtist = track.artist.trim();
      if (rawArtist.isEmpty || rawArtist.toLowerCase() == 'unknown') continue;
      final key = rawArtist.toLowerCase();
      byArtist.putIfAbsent(key, () => <TrackModel>[]).add(track);
      displayNameByKey.putIfAbsent(key, () => rawArtist);
    }

    if (byArtist.isEmpty) {
      return const <_TopArtist>[];
    }

    final recent = _library.getRecentTracks(limit: 40);
    final liked = _library.getLikedSongs();

    final recencyBoost = <String, double>{};
    for (var i = 0; i < recent.length; i++) {
      final key = recent[i].artist.trim().toLowerCase();
      if (key.isEmpty) continue;
      final boost = (recent.length - i) / recent.length;
      recencyBoost[key] = (recencyBoost[key] ?? 0) + (boost * 3.0);
    }

    final likedBoost = <String, double>{};
    for (final track in liked) {
      final key = track.artist.trim().toLowerCase();
      if (key.isEmpty) continue;
      likedBoost[key] = (likedBoost[key] ?? 0) + 0.35;
    }

    final ranked = <_TopArtist>[];
    byArtist.forEach((key, artistTracks) {
      final dedup = <String, TrackModel>{};
      for (final track in artistTracks) {
        final fingerprint =
            '${track.id}::${track.title.toLowerCase().trim()}::${track.artist.toLowerCase().trim()}';
        dedup.putIfAbsent(fingerprint, () => track);
      }
      final uniqueTracks = dedup.values.toList(growable: false);
      uniqueTracks.sort((a, b) => b.title.compareTo(a.title));

      final score =
          uniqueTracks.length.toDouble() +
          (recencyBoost[key] ?? 0) +
          (likedBoost[key] ?? 0);

      ranked.add(
        _TopArtist(
          name: displayNameByKey[key] ?? key,
          tracks: uniqueTracks,
          highlightTrack: uniqueTracks.first,
          score: score,
        ),
      );
    });

    ranked.sort((a, b) => b.score.compareTo(a.score));

    final shortlist = ranked.take(12).toList(growable: false);
    if (shortlist.length <= 1) {
      return shortlist;
    }

    final bucket = DateTime.now().millisecondsSinceEpoch ~/
        const Duration(minutes: 5).inMilliseconds;
    final random = math.Random(bucket + _refreshSeed + shortlist.length);
    final rotatingHead = shortlist.take(math.min(6, shortlist.length)).toList();
    rotatingHead.shuffle(random);
    final stableTail = shortlist.skip(rotatingHead.length).toList(growable: false);
    return [...rotatingHead, ...stableTail].take(8).toList(growable: false);
  }

  List<TrackModel> _recentTracks() {
    return _library.getRecentTracks(limit: 10);
  }
}

class _RecommendationCard extends StatelessWidget {
  final TrackModel track;
  final bool isLarge;
  final VoidCallback onTap;

  const _RecommendationCard({required this.track, required this.isLarge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final width = isLarge ? 300.0 : 190.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'art-${track.id}',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF1F1F1F),
                    image: track.albumArtUrl == null
                        ? null
                        : DecorationImage(
                            image: NetworkImage(track.albumArtUrl!),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: track.albumArtUrl == null
                      ? const Center(
                          child: Icon(Icons.music_note_rounded, color: GlassColors.textSecondary, size: 36),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GlassColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: isLarge ? 19 : 15,
              ),
            ),
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFFB9CCB2),
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

class _TopArtistCard extends StatelessWidget {
  final _TopArtist artist;
  final VoidCallback onTap;

  const _TopArtistCard({required this.artist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  color: const Color(0xFF1F1F1F),
                  image: artist.highlightTrack.albumArtUrl == null
                      ? null
                      : DecorationImage(
                          image: NetworkImage(artist.highlightTrack.albumArtUrl!),
                          fit: BoxFit.cover,
                        ),
                ),
                child: artist.highlightTrack.albumArtUrl == null
                    ? const Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: GlassColors.textSecondary,
                          size: 38,
                        ),
                      )
                    : Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          margin: const EdgeInsets.all(AppSpacing.md),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Text(
                            '${artist.tracks.length} songs',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GlassColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              artist.highlightTrack.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFFB9CCB2),
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

class _TrackRow extends StatelessWidget {
  final TrackModel track;
  final VoidCallback onTap;

  const _TrackRow({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 58,
                height: 58,
                child: track.albumArtUrl == null
                    ? Container(
                        color: const Color(0xFF1F1F1F),
                        child: const Icon(Icons.music_note_rounded, color: GlassColors.textSecondary),
                      )
                    : Image.network(track.albumArtUrl!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
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
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB9CCB2),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_vert_rounded, color: GlassColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _EmptyTopArtists extends StatelessWidget {
  const _EmptyTopArtists();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          color: const Color(0xFF1B1B1B),
        ),
        child: Center(
          child: Text(
            'Play and like songs to generate top artists',
            style: GoogleFonts.inter(
              color: const Color(0xFFB9CCB2),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRecommendations extends StatelessWidget {
  const _EmptyRecommendations();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          color: const Color(0xFF1B1B1B),
        ),
        child: Center(
          child: Text(
            'Play a track to generate recommendations',
            style: GoogleFonts.inter(
              color: const Color(0xFFB9CCB2),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeData {
  final List<TrackModel> recommendedTracks;
  final List<_TopArtist> topArtists;

  const _HomeData({
    required this.recommendedTracks,
    required this.topArtists,
  });
}

class _TopArtist {
  final String name;
  final List<TrackModel> tracks;
  final TrackModel highlightTrack;
  final double score;

  const _TopArtist({
    required this.name,
    required this.tracks,
    required this.highlightTrack,
    required this.score,
  });
}


