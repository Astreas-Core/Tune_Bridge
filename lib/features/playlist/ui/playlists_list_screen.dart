import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/features/library/bloc/playlists_bloc.dart';
import 'package:tune_bridge/features/library/bloc/playlists_event.dart';
import 'package:tune_bridge/features/library/bloc/playlists_state.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';

class PlaylistsListScreen extends StatelessWidget {
  const PlaylistsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlaylistsBloc(
        getIt<LocalLibraryService>(),
      )..add(const PlaylistsRequested()),
      child: const _PlaylistsContent(),
    );
  }
}

class _PlaylistsContent extends StatelessWidget {
  const _PlaylistsContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassColors.background,
      body: BlocBuilder<PlaylistsBloc, PlaylistsState>(
        builder: (context, state) {
          if (state is PlaylistsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: GlassColors.accent),
            );
          }

          if (state is PlaylistsLoaded) {
            final playlists = state.playlists;
            if (playlists.isEmpty) {
              return const _PlaylistsShell(
                child: _PlaylistsEmpty(),
              );
            }

            return _PlaylistsShell(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PlaylistTile(
                      name: playlist.name,
                      trackCount: playlist.trackCount,
                      imageUrl: playlist.imageUrl,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.playlist,
                          arguments: {
                            'id': playlist.id,
                            'name': playlist.name,
                            'imageUrl': playlist.imageUrl,
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            );
          }

          if (state is PlaylistsError) {
            return const _PlaylistsShell(
              child: _PlaylistsError(),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00FF41),
        foregroundColor: const Color(0xFF04210A),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create playlist flow coming soon')),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _PlaylistsShell extends StatelessWidget {
  final Widget child;

  const _PlaylistsShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 10),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Playlists.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFEBFFE2),
                          fontWeight: FontWeight.w900,
                          fontSize: 30,
                          letterSpacing: -0.8,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Text(
                        'All your imported collections',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFB9CCB2),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
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

class _PlaylistsEmpty extends StatelessWidget {
  const _PlaylistsEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassPanel(
        blur: 0,
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF161616),
        borderColor: const Color(0x22FFFFFF),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.queue_music_rounded, size: 42, color: GlassColors.textSecondary),
            const SizedBox(height: 10),
            Text(
              'No playlists yet',
              style: GoogleFonts.inter(
                color: const Color(0xFFEBFFE2),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Import one from Spotify to get started.',
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

class _PlaylistsError extends StatelessWidget {
  const _PlaylistsError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Error loading playlists',
        style: GoogleFonts.inter(
          color: const Color(0xFFB9CCB2),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final String name;
  final int trackCount;
  final String? imageUrl;
  final VoidCallback onTap;

  const _PlaylistTile({
    required this.name,
    required this.trackCount,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: GlassPanel(
        blur: 0,
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF171717),
        borderColor: const Color(0x26FFFFFF),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x2200FF41)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderIcon(),
                      )
                    : _placeholderIcon(),
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFEBFFE2),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$trackCount tracks',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB9CCB2),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF00FF41)),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Center(
      child: Icon(
        Icons.queue_music_rounded,
        color: GlassColors.textSecondary,
        size: 24,
      ),
    );
  }
}
