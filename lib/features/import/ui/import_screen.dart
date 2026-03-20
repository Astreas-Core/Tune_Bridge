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
      backgroundColor: const Color(0xFF0F1115),
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
                    'Import Music',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFEBFFE2),
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                      letterSpacing: -0.8,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B2A1F), Color(0xFF102018), Color(0xFF0F1512)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: const Color(0x3300FF41)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0x2200FF41),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.cloud_download_rounded,
                            color: Color(0xFF00FF41),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Spotify Link Import',
                            style: GoogleFonts.inter(
                              color: GlassColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Paste a Spotify track, album, or playlist URL to instantly import into TuneBridge.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB9CCB2),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _TypeChip(icon: Icons.music_note_rounded, label: 'Track'),
                        _TypeChip(icon: Icons.album_rounded, label: 'Album'),
                        _TypeChip(icon: Icons.queue_music_rounded, label: 'Playlist'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF171A20),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: const Color(0x22FFFFFF)),
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
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                children: [
                  _QuickLinkButton(
                    label: 'Paste Playlist',
                    onTap: () {
                      _controller.text =
                          'https://open.spotify.com/playlist/';
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: _controller.text.length),
                      );
                    },
                  ),
                  _QuickLinkButton(
                    label: 'Paste Album',
                    onTap: () {
                      _controller.text =
                          'https://open.spotify.com/album/';
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: _controller.text.length),
                      );
                    },
                  ),
                  _QuickLinkButton(
                    label: 'Paste Track',
                    onTap: () {
                      _controller.text =
                          'https://open.spotify.com/track/';
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: _controller.text.length),
                      );
                    },
                  ),
                ],
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14181F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x2200FF41)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _progressLabel,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFB9CCB2),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progress == 0 ? null : _progress,
                          minHeight: 8,
                          backgroundColor: const Color(0xFF2A2A2A),
                          color: const Color(0xFF00FF41),
                        ),
                      ),
                    ],
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

class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TypeChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1F00FF41),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x3300FF41)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF00FF41)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFFB9CCB2),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickLinkButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF171A20),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: GlassColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
