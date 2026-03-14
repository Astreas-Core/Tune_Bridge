import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/neumorphic.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/core/services/spotify_public_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  void _onImport() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final service = getIt<SpotifyPublicService>();
      final library = getIt<LocalLibraryService>();
      
      // Basic type detection
      String type = 'unknown';
      if (url.contains('track')) type = 'track';
      else if (url.contains('playlist')) type = 'playlist';
      else if (url.contains('album')) type = 'album';

      if (type == 'track') {
        final id = url.split('track/').last.split('?').first;
        final track = await service.getTrack(id);
        await library.addLikedSong(track);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added "${track.title}" to Liked Songs')),
          );
        }
      } else if (type == 'playlist') {
        final id = url.split('playlist/').last.split('?').first;
        final info = await service.getPlaylistInfo(id);
        final tracks = await service.getPlaylistTracks(id);
        await library.savePlaylist(info, tracks);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported playlist "${info.name}" (${tracks.length} tracks)')),
          );
        }
      } else if (type == 'album') {
        final id = url.split('album/').last.split('?').first;
        final info = await service.getAlbumInfo(id);
        final tracks = await service.getAlbumTracks(id);
        await library.savePlaylist(info, tracks);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported album "${info.name}" (${tracks.length} tracks)')),
          );
        }
      } else {
        throw Exception('Could not determine import type. Please use a valid Spotify link.');
      }
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neumorphic.background,
      appBar: AppBar(
        backgroundColor: Neumorphic.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'IMPORT',
          style: GoogleFonts.splineSans(
            color: Neumorphic.textDark,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Neumorphic.textMedium),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 120,
              height: 120,
              decoration: Neumorphic.raised(
                radius: 60,
                blurRadius: 20,
                offset: const Offset(10, 10),
              ),
              child: Icon(
                Icons.cloud_download_rounded,
                size: 50,
                color: Neumorphic.accent,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Import from Spotify',
              style: GoogleFonts.splineSans(
                color: Neumorphic.textDark,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Paste a Spotify playlist or song link below to add it to your library.',
              textAlign: TextAlign.center,
              style: GoogleFonts.splineSans(
                color: Neumorphic.textMedium,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),

            // Text Field Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: Neumorphic.inset(
                radius: 16,
                blurRadius: 8,
                offset: const Offset(3, 3),
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.splineSans(color: Neumorphic.textDark, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'https://open.spotify.com/...',
                  hintStyle: GoogleFonts.splineSans(color: Neumorphic.textMedium),
                  border: InputBorder.none,
                  icon: Icon(Icons.link, color: Neumorphic.accent),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Import Button
            GestureDetector(
              onTap: _isLoading ? null : _onImport,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: Neumorphic.raised(
                  radius: 16,
                  color: Neumorphic.accent,
                  blurRadius: 16,
                  offset: const Offset(6, 6),
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'IMPORT',
                          style: GoogleFonts.splineSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
