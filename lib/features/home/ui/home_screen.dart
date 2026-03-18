import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/models/track_model.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/features/player/bloc/player_bloc.dart';
import 'package:tune_bridge/features/player/bloc/player_event.dart';
import 'package:tune_bridge/features/player/bloc/player_state.dart' as ps;
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = getIt<LocalLibraryService>();

    return Scaffold(
      backgroundColor: GlassColors.background,
      body: SafeArea(
        child: BlocBuilder<PlayerBloc, ps.PlayerState>(
          buildWhen: (previous, current) =>
              previous.queue != current.queue ||
              previous.currentTrack?.id != current.currentTrack?.id,
          builder: (context, playerState) {
            final recentTracks = _recentTracks(library, playerState);

            return FutureBuilder<List<TrackModel>>(
              future: library.getPersonalizedRecommendations(limit: 10),
              builder: (context, snapshot) {
                final recommendedTracks = snapshot.data ?? recentTracks;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                        const SizedBox(height: 18),
                        _QuickActions(
                          likedCount: library.likedCount,
                          onShuffle: recommendedTracks.isEmpty
                              ? null
                              : () {
                                  context.read<PlayerBloc>().add(
                                        PlayerPlayTrack(
                                          track: recommendedTracks.first,
                                          queue: recommendedTracks,
                                          queueIndex: 0,
                                        ),
                                      );
                                },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Recommended.',
                                style: GoogleFonts.inter(
                                  color: GlassColors.textPrimary,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
                              child: Text(
                                'VIEW ALL',
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
                        ? const _EmptyRecent()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: recommendedTracks.length,
                            itemBuilder: (context, index) {
                              final track = recommendedTracks[index];
                              return _FeaturedCard(
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
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                    child: Text(
                      'Recently Played.',
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
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<TrackModel> _recentTracks(LocalLibraryService library, ps.PlayerState state) {
    return library.getRecentTracks(limit: 10);
  }
}

class _QuickActions extends StatelessWidget {
  final int likedCount;
  final VoidCallback? onShuffle;

  const _QuickActions({required this.likedCount, this.onShuffle});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.8,
      children: [
        _ActionTile(
          icon: Icons.shuffle_rounded,
          title: 'Shuffle All',
          subtitle: 'Action',
          highlighted: true,
          onTap: onShuffle,
        ),
        _ActionTile(
          icon: Icons.favorite_rounded,
          title: '$likedCount Liked',
          subtitle: 'Library',
          onTap: () => Navigator.pushNamed(context, AppRoutes.likedSongs),
        ),
        _ActionTile(
          icon: Icons.search_rounded,
          title: 'Search',
          subtitle: 'Discover',
          onTap: () => Navigator.pushNamed(context, AppRoutes.search),
        ),
        _ActionTile(
          icon: Icons.input_rounded,
          title: 'Import',
          subtitle: 'Spotify/Local',
          onTap: () => Navigator.pushNamed(context, AppRoutes.import_),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool highlighted;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: highlighted ? const Color(0x2200FF41) : Colors.transparent,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: highlighted ? const Color(0xFF00FF41) : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                icon,
                size: 18,
                color: highlighted ? const Color(0xFF003907) : GlassColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB9CCB2),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: GlassColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final TrackModel track;
  final bool isLarge;
  final VoidCallback onTap;

  const _FeaturedCard({required this.track, required this.isLarge, required this.onTap});

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

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
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


