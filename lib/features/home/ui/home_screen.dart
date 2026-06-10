import 'package:tune_bridge/core/theme.dart';
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
          backgroundColor: context.backgroundColor,
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
                final recommendedTracks =
                  isHomeLoading ? const <TrackModel>[] : (homeData?.recommendedTracks ?? recentTracks);

                return RefreshIndicator(
                  onRefresh: _onRefreshAll,
                  color: context.primaryColor,
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
                                  color: context.textPrimaryColor,
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
                                  color: Color(0xFF1F1F1F),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: context.textSecondaryColor,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Curated for your latest listening',
                          style: GoogleFonts.inter(
                            color: context.textSecondaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xxl),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Recommended',
                                style: GoogleFonts.inter(
                                  color: context.textPrimaryColor,
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
                                  color: context.primaryColor,
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
                    child: Text(
                      'Recently Played',
                      style: GoogleFonts.inter(
                        color: context.textPrimaryColor,
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
      _discoverUnseenRecommendations(limit: 10, seed: _recommendedRefreshSeed),
    ]);

    final localRecommendations = (results[0] as List<TrackModel>);
    final unseenRecommendations = (results[1] as List<TrackModel>);
    final uniqueRecommendations = _mergeUniqueRecommendations(
      primary: unseenRecommendations,
      secondary: localRecommendations,
      limit: 10,
    );

    return _HomeData(
      recommendedTracks: uniqueRecommendations,
    );
  }

  List<TrackModel> _mergeUniqueRecommendations({
    required List<TrackModel> primary,
    required List<TrackModel> secondary,
    required int limit,
  }) {
    final uniqueById = <String>{};
    final uniqueByIdentity = <String>{};
    final uniqueByTitle = <String>{};
    final out = <TrackModel>[];

    void addIfUnique(TrackModel track) {
      if (out.length >= limit) return;

      final id = track.id.trim();
      final identity = _titleArtistKey(track.title, track.artist);
      final titleKey = _normalizeTitle(track.title);

      if (id.isNotEmpty && uniqueById.contains(id)) return;
      if (identity.isNotEmpty && uniqueByIdentity.contains(identity)) return;
      if (titleKey.isNotEmpty && uniqueByTitle.contains(titleKey)) return;

      if (id.isNotEmpty) uniqueById.add(id);
      if (identity.isNotEmpty) uniqueByIdentity.add(identity);
      if (titleKey.isNotEmpty) uniqueByTitle.add(titleKey);
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
      queries.add('${entry.key} mix');
    }
    for (final t in recent.take(4)) {
      queries.add('${t.artist} mix');
    }
    if (queries.isEmpty) {
      queries.addAll(const [
        'trending songs 2026',
        'new music releases',
      ]);
    }

    final random = math.Random(seed + DateTime.now().day + queries.length);
    queries.shuffle(random);

    final discovered = <TrackModel>[];
    final discoveredIdentity = <String>{};
    final discoveredTitleKey = <String>{};
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

        // Title-only dedup: prevents same song from different channels
        final titleOnly = _normalizeTitle(track.title);
        if (discoveredTitleKey.contains(titleOnly)) continue;

        discovered.add(track);
        discoveredIdentity.add(identity);
        discoveredTitleKey.add(titleOnly);
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
    return '${_normalizeTitle(title)}::${_normalizeTitle(artist)}';
  }

  /// Normalize a title for dedup — strips parentheses, brackets, noise words,
  /// and special characters so the same song from different channels matches.
  String _normalizeTitle(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), ' ')
        .replaceAll(RegExp(r'\b(official|video|lyrics|audio|music|hd|hq|mv|full|visualizer|version|remastered|remaster|song|track)\b'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isLowQualityCandidate(TrackModel track) {
    final text = '${track.title} ${track.artist}'.toLowerCase();
    return text.contains('karaoke') ||
        text.contains('slowed') ||
        text.contains('reverb') ||
        text.contains('8d') ||
        text.contains('nightcore') ||
        text.contains('instrumental') ||
        text.contains('cover') ||
        text.contains('reaction') ||
        text.contains('tutorial') ||
        text.contains('mashup') ||
        text.contains('compilation') ||
        text.contains('ringtone');
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
                    color: Color(0xFF1F1F1F),
                    image: track.albumArtUrl == null
                        ? null
                        : DecorationImage(
                            image: NetworkImage(track.albumArtUrl!),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: track.albumArtUrl == null
                      ? Center(
                          child: Icon(Icons.music_note_rounded, color: context.textSecondaryColor, size: 36),
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w800,
                fontSize: isLarge ? 19 : 15,
              ),
            ),
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: context.textSecondaryColor,
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
      baseColor: Color(0xFF232A33),
      highlightColor: Color(0xFF2F3B47),
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
          SizedBox(height: 10),
          Container(
            width: isLarge ? 210 : 140,
            height: isLarge ? 20 : 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          SizedBox(height: 8),
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
                        color: Color(0xFF1F1F1F),
                        child: Icon(Icons.music_note_rounded, color: context.textSecondaryColor),
                      )
                    : Image.network(track.albumArtUrl!, fit: BoxFit.cover),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.more_vert_rounded, color: context.textSecondaryColor),
          ],
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
          color: Color(0xFF1B1B1B),
        ),
        child: Center(
          child: Text(
            'Play a track to generate recommendations',
            style: GoogleFonts.inter(
              color: context.textSecondaryColor,
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

  const _HomeData({
    required this.recommendedTracks,
  });
}


