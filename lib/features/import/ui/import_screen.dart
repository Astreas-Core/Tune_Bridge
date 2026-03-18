import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/core/services/spotify_public_service.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';

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
      if (url.contains('track')) {
        type = 'track';
      } else if (url.contains('playlist')) {
        type = 'playlist';
      } else if (url.contains('album')) {
        type = 'album';
      }

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
      backgroundColor: GlassColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: GlassColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Import',
                    style: GoogleFonts.splineSans(
                      color: GlassColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GlassPanel(
                blur: 10,
                borderRadius: BorderRadius.circular(24),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: const Color(0x3300D7FF),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0x5500D7FF)),
                      ),
                      child: const Icon(
                        Icons.cloud_download_rounded,
                        size: 40,
                        color: GlassColors.accent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Import from Spotify',
                      style: GoogleFonts.splineSans(
                        color: GlassColors.textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Paste a Spotify track, album, or playlist link to add it to your local library.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.splineSans(
                        color: GlassColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    GlassPanel(
                      blur: 0,
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0x33182330),
                      borderColor: const Color(0x22FFFFFF),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextField(
                        controller: _controller,
                        style: GoogleFonts.splineSans(
                          color: GlassColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'https://open.spotify.com/...',
                          hintStyle: GoogleFonts.splineSans(
                            color: GlassColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.link_rounded, color: GlassColors.accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onImport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlassColors.accent,
                          foregroundColor: const Color(0xFF041118),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF041118),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Import',
                                style: GoogleFonts.splineSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
