import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/neumorphic.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/features/library/bloc/playlists_bloc.dart';
import 'package:tune_bridge/features/library/bloc/playlists_event.dart';
import 'package:tune_bridge/features/library/bloc/playlists_state.dart';

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
      backgroundColor: Neumorphic.background,
      appBar: AppBar(
        backgroundColor: Neumorphic.background,
        centerTitle: true,
        elevation: 0,
        title: Text(
          'Playlists',
          style: GoogleFonts.splineSans(
            color: Neumorphic.textDark,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Neumorphic.textMedium),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<PlaylistsBloc, PlaylistsState>(
        builder: (context, state) {
          if (state is PlaylistsLoading) {
            return Center(
              child: CircularProgressIndicator(color: Neumorphic.accent),
            );
          }

          if (state is PlaylistsLoaded) {
            final playlists = state.playlists;
            if (playlists.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: Neumorphic.inset(
                        radius: 50,
                        blurRadius: 10,
                        offset: const Offset(5, 5),
                      ),
                      child: Icon(
                        Icons.queue_music_rounded,
                        size: 48,
                        color: Neumorphic.textLight.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No playlists yet',
                      style: GoogleFonts.splineSans(
                        color: Neumorphic.textMedium,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create one by importing from Spotify\nor adding songs manually.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.splineSans(
                        color: Neumorphic.textLight,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: playlists.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return _PlaylistTile(
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
                );
              },
            );
          }

          if (state is PlaylistsError) {
            return Center(
              child: Text(
                'Error loading playlists',
                style: GoogleFonts.splineSans(color: Neumorphic.textMedium),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: GestureDetector(
        onTap: () {
          // Add playlist logic
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create Playlist coming soon')),
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: Neumorphic.raised(
            radius: 28,
            blurRadius: 10,
            offset: const Offset(5, 5),
            color: Neumorphic.accent,
          ),
          child: const Icon(Icons.add, color: Colors.white),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: Neumorphic.raised(
          radius: 20,
          blurRadius: 10,
          offset: const Offset(4, 4),
        ),
        child: Row(
          children: [
            // Playlist Art
            Container(
              width: 60,
              height: 60,
              decoration: Neumorphic.inset(
                radius: 12,
                blurRadius: 4,
                offset: const Offset(2, 2),
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
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.splineSans(
                      color: Neumorphic.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$trackCount tracks',
                    style: GoogleFonts.splineSans(
                      color: Neumorphic.textMedium,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.chevron_right_rounded,
              color: Neumorphic.textMedium.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Center(
      child: Icon(
        Icons.queue_music_rounded,
        color: Neumorphic.textLight.withOpacity(0.5),
        size: 24,
      ),
    );
  }
}
