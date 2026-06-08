import 'package:tune_bridge/core/theme.dart';
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

  Future<void> _confirmAndDeletePlaylist(
    BuildContext context, {
    required String playlistId,
    required String playlistName,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: context.surfaceColor,
          title: Text(
            'Delete playlist?',
            style: GoogleFonts.inter(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            '"$playlistName" will be removed from imported playlists.',
            style: GoogleFonts.inter(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: context.textSecondaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  color: Color(0xFFFF6B6B),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) return;

    try {
      await getIt<LocalLibraryService>().removePlaylist(playlistId);
      if (!context.mounted) return;
      context.read<PlaylistsBloc>().add(PlaylistsRequested());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "$playlistName"')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete playlist: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: BlocBuilder<PlaylistsBloc, PlaylistsState>(
        builder: (context, state) {
          if (state is PlaylistsLoading) {
            return Center(
              child: CircularProgressIndicator(color: context.primaryColor),
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
                      onDelete: () => _confirmAndDeletePlaylist(
                        context,
                        playlistId: playlist.id,
                        playlistName: playlist.name,
                      ),
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
        backgroundColor: context.primaryColor,
        foregroundColor: context.backgroundColor,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create playlist flow coming soon')),
          );
        },
        child: Icon(Icons.add_rounded),
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
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: context.primaryColor,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Playlists.',
                        style: GoogleFonts.inter(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 30,
                          letterSpacing: -0.8,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Text(
                        'All your imported collections',
                        style: GoogleFonts.inter(
                          color: context.textSecondaryColor,
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
        color: context.surfaceColor,
        borderColor: context.textPrimaryColor.withValues(alpha: 0.13),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.queue_music_rounded, size: 42, color: context.textSecondaryColor),
            SizedBox(height: 10),
            Text(
              'No playlists yet',
              style: GoogleFonts.inter(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Import one from Spotify to get started.',
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

class _PlaylistsError extends StatelessWidget {
  const _PlaylistsError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Error loading playlists',
        style: GoogleFonts.inter(
          color: context.textSecondaryColor,
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
  final VoidCallback onDelete;

  const _PlaylistTile({
    required this.name,
    required this.trackCount,
    this.imageUrl,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: GlassPanel(
        blur: 0,
        borderRadius: BorderRadius.circular(18),
        color: context.surfaceColor,
        borderColor: context.textPrimaryColor.withValues(alpha: 0.15),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.primaryColor.withValues(alpha: 0.13)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderIcon(context),
                      )
                    : _placeholderIcon(context),
              ),
            ),
            SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      color: context.textPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$trackCount tracks',
                    style: GoogleFonts.inter(
                      color: context.textSecondaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              tooltip: 'Delete playlist',
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFFF6B6B),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon(BuildContext context) {
    return Center(
      child: Icon(
        Icons.queue_music_rounded,
        color: context.textSecondaryColor,
        size: 24,
      ),
    );
  }
}
