import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tune_bridge/core/constants.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/models/track_model.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/artist_image_service.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/core/services/youtube_service.dart';
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
  final ArtistImageService _artistImageService = getIt<ArtistImageService>();
  final YouTubeService _youtubeService = getIt<YouTubeService>();
  int _recommendedRefreshSeed = 0;
  int _artistsRefreshSeed = 0;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _rotationTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (!mounted) return;
      setState(() {
        _recommendedRefreshSeed++;
        _artistsRefreshSeed++;
      });
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  Future<void> _onRefreshAll() async {
    if (!mounted) return;
    setState(() {
      _recommendedRefreshSeed++;
      _artistsRefreshSeed++;
    });
    await _library.getAllKnownTracks();
  }

  void _refreshRecommended() {
    if (!mounted) return;
    setState(() {
      _recommendedRefreshSeed++;
    });
  }

  void _refreshArtists() {
    if (!mounted) return;
    setState(() {
      _artistsRefreshSeed++;
    });
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
                '$_recommendedRefreshSeed-$_artistsRefreshSeed-${_library.likedCount}-${_library.offlineCount}-${_library.playlistCount}',
              ),
              future: _loadHomeData(),
              builder: (context, snapshot) {
                final recentTracks = _recentTracks();
                final isHomeLoading = snapshot.connectionState != ConnectionState.done;
                final homeData = snapshot.data;
                final topArtists =
                  isHomeLoading ? const <_TopArtist>[] : (homeData?.topArtists ?? const <_TopArtist>[]);
                final recommendedTracks =
                  isHomeLoading ? const <TrackModel>[] : (homeData?.recommendedTracks ?? recentTracks);

                return RefreshIndicator(
                  onRefresh: _onRefreshAll,
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
                              onPressed: _refreshRecommended,
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
                    child: isHomeLoading
                        ? const _RecommendedSkeletonCarousel()
                        : recommendedTracks.isEmpty
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
                const SliverToBoxAdapter(
                  child: SizedBox(height: 10),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm + 2, AppSpacing.xl, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Top artists for you',
                            style: GoogleFonts.inter(
                              color: GlassColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _refreshArtists,
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
                    child: isHomeLoading
                        ? const _TopArtistsSkeletonRow()
                        : topArtists.isEmpty
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
      _library.getPersonalizedRecommendations(limit: 10, seed: _recommendedRefreshSeed),
      _loadTopArtists(seed: _artistsRefreshSeed),
      _discoverUnseenRecommendations(limit: 10, seed: _recommendedRefreshSeed),
    ]);

    final localRecommendations = (results[0] as List<TrackModel>);
    final unseenRecommendations = (results[2] as List<TrackModel>);
    final uniqueRecommendations = _mergeUniqueRecommendations(
      primary: unseenRecommendations,
      secondary: localRecommendations,
      limit: 10,
    );

    return _HomeData(
      recommendedTracks: uniqueRecommendations,
      topArtists: (results[1] as List<_TopArtist>),
    );
  }

  List<TrackModel> _mergeUniqueRecommendations({
    required List<TrackModel> primary,
    required List<TrackModel> secondary,
    required int limit,
  }) {
    final uniqueById = <String>{};
    final uniqueByIdentity = <String>{};
    final out = <TrackModel>[];

    void addIfUnique(TrackModel track) {
      if (out.length >= limit) return;

      final id = track.id.trim();
      final identity = _titleArtistKey(track.title, track.artist);

      if (id.isNotEmpty && uniqueById.contains(id)) return;
      if (identity.isNotEmpty && uniqueByIdentity.contains(identity)) return;

      if (id.isNotEmpty) uniqueById.add(id);
      if (identity.isNotEmpty) uniqueByIdentity.add(identity);
      out.add(track);
    }

    for (final track in primary) {
      addIfUnique(track);
      if (out.length >= limit) return out;
    }

    for (final track in secondary) {
      addIfUnique(track);
      if (out.length >= limit) return out;
    }

    return out;
  }

  Future<List<TrackModel>> _discoverUnseenRecommendations({
    required int limit,
    required int seed,
  }) async {
    final known = await _library.getAllKnownTracks();
    final recent = _library.getRecentTracks(limit: 20);
    final liked = _library.getLikedSongs().take(20).toList(growable: false);

    final knownIds = <String>{
      ...known.map((t) => t.id),
      ...recent.map((t) => t.id),
      ...liked.map((t) => t.id),
    };
    final knownIdentity = <String>{
      ...known.map((t) => _titleArtistKey(t.title, t.artist)),
      ...recent.map((t) => _titleArtistKey(t.title, t.artist)),
      ...liked.map((t) => _titleArtistKey(t.title, t.artist)),
    };

    final artistCounts = <String, int>{};
    for (final track in [...recent, ...liked, ...known.take(60)]) {
      final artist = track.artist.trim();
      if (artist.isEmpty || artist.toLowerCase() == 'unknown') continue;
      artistCounts[artist] = (artistCounts[artist] ?? 0) + 1;
    }

    final topArtists = artistCounts.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    final queries = <String>[];
    for (final entry in topArtists.take(6)) {
      queries.add('${entry.key} latest song');
      queries.add('${entry.key} new release');
    }
    for (final t in recent.take(4)) {
      queries.add('${t.artist} songs like ${_shortTitle(t.title)}');
    }
    if (queries.isEmpty) {
      queries.addAll(const [
        'trending songs 2026',
        'new music releases',
        'viral songs official audio',
      ]);
    }

    final random = math.Random(seed + DateTime.now().day + queries.length);
    queries.shuffle(random);

    final discovered = <TrackModel>[];
    final discoveredIdentity = <String>{};
    final discoveredArtistUsage = <String, int>{};

    for (final query in queries.take(10)) {
      List<TrackModel> results;
      try {
        results = await _youtubeService.search(query);
      } catch (_) {
        continue;
      }

      for (final track in results) {
        final artistKey = track.artist.trim().toLowerCase();
        if ((discoveredArtistUsage[artistKey] ?? 0) >= 2) continue;
        if (knownIds.contains(track.id)) continue;
        if (_isLowQualityCandidate(track)) continue;

        final identity = _titleArtistKey(track.title, track.artist);
        if (knownIdentity.contains(identity)) continue;
        if (discoveredIdentity.contains(identity)) continue;

        discovered.add(track);
        discoveredIdentity.add(identity);
        discoveredArtistUsage[artistKey] = (discoveredArtistUsage[artistKey] ?? 0) + 1;

        if (discovered.length >= limit) {
          return discovered;
        }
      }
    }

    return discovered;
  }

  String _shortTitle(String title) {
    final cleaned = title.replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '').trim();
    if (cleaned.isEmpty) return title;
    return cleaned.split(RegExp(r'\s+')).take(5).join(' ');
  }

  String _titleArtistKey(String title, String artist) {
    String normalize(String value) {
      return value
          .toLowerCase()
          .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), ' ')
          .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    return '${normalize(title)}::${normalize(artist)}';
  }

  bool _isLowQualityCandidate(TrackModel track) {
    final text = '${track.title} ${track.artist}'.toLowerCase();
    return text.contains('karaoke') ||
        text.contains('slowed') ||
        text.contains('reverb') ||
        text.contains('8d') ||
        text.contains('nightcore') ||
        text.contains('instrumental');
  }

  Future<List<_TopArtist>> _loadTopArtists({required int seed}) async {
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
    final random = math.Random(bucket + seed + shortlist.length);
    final rotatingHead = shortlist.take(math.min(6, shortlist.length)).toList();
    rotatingHead.shuffle(random);
    final stableTail = shortlist.skip(rotatingHead.length).toList(growable: false);

    final selected = [...rotatingHead, ...stableTail].take(8).toList(growable: false);
    final withImages = await Future.wait(
      selected.map((artist) async {
        final profileImageUrl = await _artistImageService.resolveArtistImage(artist.name);
        return artist.copyWith(profileImageUrl: profileImageUrl);
      }),
    );
    return withImages;
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

class _RecommendedSkeletonCarousel extends StatelessWidget {
  const _RecommendedSkeletonCarousel();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF232A33),
      highlightColor: const Color(0xFF2F3B47),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        scrollDirection: Axis.horizontal,
        children: const [
          _RecommendationSkeletonCard(isLarge: true),
          _RecommendationSkeletonCard(isLarge: false),
          _RecommendationSkeletonCard(isLarge: false),
        ],
      ),
    );
  }
}

class _RecommendationSkeletonCard extends StatelessWidget {
  final bool isLarge;

  const _RecommendationSkeletonCard({required this.isLarge});

  @override
  Widget build(BuildContext context) {
    final width = isLarge ? 300.0 : 190.0;
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: isLarge ? 210 : 140,
            height: isLarge ? 20 : 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: isLarge ? 120 : 90,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
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
    final avatarUrl = artist.profileImageUrl;
    final avatarColors = _avatarGradientForName(artist.name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 158,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 132,
              height: 132,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: avatarColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: avatarColors.last.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  color: const Color(0xFF131A22),
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Center(
                          child: Text(
                            _artistInitials(artist.name),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        )
                      : Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              _artistInitials(artist.name),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
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
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GlassColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopArtistsSkeletonRow extends StatelessWidget {
  const _TopArtistsSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF232A33),
      highlightColor: const Color(0xFF2F3B47),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        scrollDirection: Axis.horizontal,
        children: const [
          _TopArtistSkeletonCard(),
          _TopArtistSkeletonCard(),
          _TopArtistSkeletonCard(),
          _TopArtistSkeletonCard(),
        ],
      ),
    );
  }
}

class _TopArtistSkeletonCard extends StatelessWidget {
  const _TopArtistSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 158,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      child: Column(
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 112,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

List<Color> _avatarGradientForName(String name) {
  final palettes = <List<Color>>[
    const [Color(0xFF1B8A5A), Color(0xFF0D3B2F)],
    const [Color(0xFF3A6EA5), Color(0xFF1B3654)],
    const [Color(0xFF8A5A9E), Color(0xFF3F2A55)],
    const [Color(0xFF9A6A3A), Color(0xFF4B321B)],
    const [Color(0xFF2F7E95), Color(0xFF1A3D4A)],
  ];
  final hash = name.toLowerCase().codeUnits.fold<int>(0, (a, b) => a + b);
  return palettes[hash % palettes.length];
}

String _artistInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return 'A';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  final first = parts.first.characters.first.toUpperCase();
  final second = parts.last.characters.first.toUpperCase();
  return '$first$second';
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
  final String? profileImageUrl;

  const _TopArtist({
    required this.name,
    required this.tracks,
    required this.highlightTrack,
    required this.score,
    this.profileImageUrl,
  });

  _TopArtist copyWith({
    String? name,
    List<TrackModel>? tracks,
    TrackModel? highlightTrack,
    double? score,
    String? profileImageUrl,
  }) {
    return _TopArtist(
      name: name ?? this.name,
      tracks: tracks ?? this.tracks,
      highlightTrack: highlightTrack ?? this.highlightTrack,
      score: score ?? this.score,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}


