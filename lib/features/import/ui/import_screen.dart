import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/constants.dart';
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
  final LocalLibraryService _library = getIt<LocalLibraryService>();

  bool _isLoading = false;
  double _progress = 0;
  String _progressLabel = '';

  Future<void> _onImport() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _progress = 0;
      _progressLabel = 'Starting import...';
    });
    try {
      final service = getIt<SpotifyPublicService>();

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
        await _library.addLikedSong(track);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added ${track.title} to Liked Songs')),
          );
        }
      } else if (type == 'playlist') {
        final id = url.split('playlist/').last.split('?').first;
        setState(() => _progressLabel = 'Fetching playlist info...');
        final info = await service.getPlaylistInfo(id);
        setState(() => _progressLabel = 'Importing tracks...');
        final tracks = await service.getPlaylistTracks(
          id,
          onProgress: (completed, total) {
            if (!mounted) return;
            setState(() {
              _progress = total == 0 ? 0 : completed / total;
              _progressLabel = 'Importing tracks... $completed/$total';
            });
          },
        );
        setState(() => _progressLabel = 'Saving playlist...');
        await _library.savePlaylist(info, tracks);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported playlist ${info.name} (${tracks.length} tracks)')),
          );
        }
      } else if (type == 'album') {
        final id = url.split('album/').last.split('?').first;
        setState(() => _progressLabel = 'Fetching album info...');
        final info = await service.getAlbumInfo(id);
        setState(() => _progressLabel = 'Importing tracks...');
        final tracks = await service.getAlbumTracks(
          id,
          onProgress: (completed, total) {
            if (!mounted) return;
            setState(() {
              _progress = total == 0 ? 0 : completed / total;
              _progressLabel = 'Importing tracks... $completed/$total';
            });
          },
        );
        setState(() => _progressLabel = 'Saving album...');
        await _library.savePlaylist(info, tracks);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported album ${info.name} (${tracks.length} tracks)')),
          );
        }
      } else {
        throw Exception('Could not determine import type from URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _progress = 0;
          _progressLabel = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 140),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF00FF41)),
                  ),
                  Text(
                    'Import Local Files',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00FF41),
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B1B),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: const Border(
                    left: BorderSide(color: Color(0xFF00FF41), width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spotify Link Import',
                      style: GoogleFonts.inter(
                        color: GlassColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Paste a Spotify track, album, or playlist URL below to import.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB9CCB2),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.inter(color: GlassColors.textPrimary, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'https://open.spotify.com/...',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFFB9CCB2)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF00E639)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _onImport,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF003907)),
                        )
                      : const Icon(Icons.download_for_offline_rounded),
                  label: Text(_isLoading ? 'IMPORTING...' : 'IMPORT SELECTED'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF41),
                    foregroundColor: const Color(0xFF003907),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xl)),
                    textStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: AppSpacing.xl),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF2A2A2A),
                    color: const Color(0xFF00FF41),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                Text(
                  _progressLabel,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB9CCB2),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
