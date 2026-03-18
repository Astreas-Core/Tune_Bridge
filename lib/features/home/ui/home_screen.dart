import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/models/track_model.dart';
import 'package:tune_bridge/core/di.dart';
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
    return const Scaffold(
      backgroundColor: GlassColors.background,
      body: _HomeTab(),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final library = getIt<LocalLibraryService>();
    // final size = MediaQuery.of(context).size;
      return BlocBuilder<PlayerBloc, ps.PlayerState>(
        buildWhen: (previous, current) =>
            previous.queue != current.queue ||
            previous.queueIndex != current.queueIndex ||
            previous.currentTrack?.id != current.currentTrack?.id,
        builder: (context, playerState) {
          final recentTracks = _recentTracks(library, playerState);

          return SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(likedCount: library.likedCount),
                        const SizedBox(height: 18),
                        _SearchLauncher(
                          onTap: () => Navigator.pushNamed(context, AppRoutes.search),
                        ),
                        const SizedBox(height: 24),
                        _SectionTitle(
                          title: 'Recently Played',
                          actionLabel: recentTracks.isNotEmpty ? 'Play all' : null,
                          onActionTap: recentTracks.isEmpty
                              ? null
                              : () {
                                  context.read<PlayerBloc>().add(PlayerPlayTrack(
                                        track: recentTracks.first,
                                        queue: recentTracks,
                                        queueIndex: 0,
                                      ));
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 210,
                    child: recentTracks.isEmpty
                        ? const _EmptyRecent()
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: recentTracks.length,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemBuilder: (context, index) {
                              final track = recentTracks[index];
                              return _RecentTrackCard(
                                track: track,
                                onTap: () {
                                  context.read<PlayerBloc>().add(PlayerPlayTrack(
                                        track: track,
                                        queue: recentTracks,
                                        queueIndex: index,
                                      ));
                                },
                              );
                            },
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _LikedSongsCard(
                      likedCount: library.likedCount,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.likedSongs),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: _SectionTitle(title: 'Library'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _LibraryQuickAction(
                          title: 'Your Playlists',
                          subtitle: '${library.playlistCount} playlists',
                          icon: Icons.queue_music_rounded,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.playlistsList),
                        ),
                        const SizedBox(height: 10),
                        _LibraryQuickAction(
                          title: 'Offline Downloads',
                          subtitle: '${library.offlineCount} songs available',
                          icon: Icons.offline_pin_rounded,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.offlineSongs),
                        ),
                        const SizedBox(height: 10),
                        _LibraryQuickAction(
                          title: 'Import from Spotify',
                          subtitle: 'Sync playlists and tracks',
                          icon: Icons.input_rounded,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.import_),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 150)),
              ],
            ),
          );
        },
      );
}

    List<TrackModel> _recentTracks(LocalLibraryService library, ps.PlayerState state) {
      final queue = state.queue.where((track) => track.id.isNotEmpty).toList();
      if (queue.isNotEmpty) {
        return queue.take(8).toList(growable: false);
      }
      final liked = library.getLikedSongs();
      return liked.take(8).toList(growable: false);
    }

}


class _Header extends StatelessWidget {
    final int likedCount;

    const _Header({required this.likedCount});

    @override
    Widget build(BuildContext context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TuneBridge',
                style: GoogleFonts.splineSans(
                  color: GlassColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$likedCount tracks saved',
                style: GoogleFonts.splineSans(
                  color: GlassColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          GlassIconButton(
            icon: Icons.settings_rounded,
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      );
    }
  }

class _SearchLauncher extends StatelessWidget {
    final VoidCallback onTap;

    const _SearchLauncher({required this.onTap});

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: onTap,
        child: const GlassPanel(
          blur: 8,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: GlassColors.textSecondary),
              SizedBox(width: 10),
              Text(
                'Search songs, artists, albums',
                style: TextStyle(
                  color: GlassColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

class _SectionTitle extends StatelessWidget {
    final String title;
    final String? actionLabel;
    final VoidCallback? onActionTap;

    const _SectionTitle({
      required this.title,
      this.actionLabel,
      this.onActionTap,
    });

    @override
    Widget build(BuildContext context) {
      return Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.splineSans(
                color: GlassColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionLabel!,
                style: GoogleFonts.splineSans(
                  color: GlassColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      );
    }
  }

class _RecentTrackCard extends StatelessWidget {
    final TrackModel track;
    final VoidCallback onTap;

    const _RecentTrackCard({required this.track, required this.onTap});

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 162,
          margin: const EdgeInsets.only(right: 12),
          child: GlassPanel(
            blur: 0,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'art-${track.id}',
                  child: Container(
                    height: 118,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      image: track.albumArtUrl != null
                          ? DecorationImage(
                              image: NetworkImage(track.albumArtUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: const Color(0x331A202C),
                    ),
                    child: track.albumArtUrl == null
                        ? const Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              color: GlassColors.textSecondary,
                              size: 30,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.splineSans(
                    color: GlassColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.splineSans(
                    color: GlassColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

class _LikedSongsCard extends StatelessWidget {
    final int likedCount;
    final VoidCallback onTap;

    const _LikedSongsCard({required this.likedCount, required this.onTap});

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0x6618E0FF), Color(0x4400C5B8), Color(0x22121B26)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: GlassPanel(
            blur: 8,
            padding: const EdgeInsets.all(18),
            borderRadius: const BorderRadius.all(Radius.circular(22)),
            color: const Color(0x33212936),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xAA0A111A),
                  child: Icon(Icons.favorite_rounded, color: GlassColors.accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _LikedText(likedCount: likedCount),
                ),
                const Icon(Icons.chevron_right_rounded, color: GlassColors.textPrimary),
              ],
            ),
          ),
        ),
      );
    }
  }

class _LikedText extends StatelessWidget {
    final int likedCount;

    const _LikedText({required this.likedCount});

    @override
    Widget build(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spotify Liked Songs',
            style: GoogleFonts.splineSans(
              color: GlassColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$likedCount tracks synced',
            style: GoogleFonts.splineSans(
              color: GlassColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }


class _LibraryQuickAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _LibraryQuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        blur: 0,
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0x33242C36),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: GlassColors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.splineSans(
                      color: GlassColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.splineSans(
                      color: GlassColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: GlassColors.textSecondary),
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
      child: GlassPanel(
        blur: 0,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.graphic_eq_rounded, color: GlassColors.textSecondary, size: 34),
            const SizedBox(height: 10),
            Text(
              'Play something to build your recent list',
              textAlign: TextAlign.center,
              style: GoogleFonts.splineSans(
                color: GlassColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


