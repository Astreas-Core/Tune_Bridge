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
        backgroundColor: GlassColors.accent,
        foregroundColor: const Color(0xFF041118),
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
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: GlassColors.textPrimary,
                  ),
                ),
                Text(
                  'Playlists',
                  style: GoogleFonts.splineSans(
                    color: GlassColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
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
        blur: 8,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.queue_music_rounded, size: 42, color: GlassColors.textSecondary),
            const SizedBox(height: 10),
            Text(
              'No playlists yet',
              style: GoogleFonts.splineSans(
                color: GlassColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Import one from Spotify to get started.',
              style: GoogleFonts.splineSans(
                color: GlassColors.textSecondary,
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
        style: GoogleFonts.splineSans(
          color: GlassColors.textSecondary,
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
        blur: 8,
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x22FFFFFF)),
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
                    style: GoogleFonts.splineSans(
                      color: GlassColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$trackCount tracks',
                    style: GoogleFonts.splineSans(
                      color: GlassColors.textSecondary,
                      fontSize: 13,
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
