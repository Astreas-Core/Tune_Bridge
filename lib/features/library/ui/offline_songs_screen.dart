import 'package:tune_bridge/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/core/models/track_model.dart';
import 'package:tune_bridge/features/player/bloc/player_bloc.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/features/player/bloc/player_event.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';
import 'package:tune_bridge/ui/widgets/song_tile.dart';

class OfflineSongsScreen extends StatefulWidget {
  const OfflineSongsScreen({super.key});

  @override
  State<OfflineSongsScreen> createState() => _OfflineSongsScreenState();
}

class _OfflineSongsScreenState extends State<OfflineSongsScreen> {
  final _library = getIt<LocalLibraryService>();
  List<TrackModel> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  void _loadSongs() {
    final songs = _library.getOfflineSongs();
    if (mounted) {
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    }
  }

  void _playSong(int index) {
    if (_songs.isEmpty) return;
    final track = _songs[index];
    final currentTrack = context.read<PlayerBloc>().state.currentTrack;

    if (currentTrack?.id == track.id) {
      Navigator.pushNamed(context, AppRoutes.nowPlaying);
      return;
    }

    context.read<PlayerBloc>().add(
      PlayerPlayTrack(
        track: track,
        queue: _songs,
        queueIndex: index,
      ),
    );
  }

  Future<void> _confirmDelete(TrackModel song) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.surfaceColor,
          title: Text(
            'Remove offline song?',
            style: GoogleFonts.inter(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'This will remove "${song.title}" from offline storage.',
            style: GoogleFonts.inter(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: context.textSecondaryColor),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await _library.removeOfflineSong(song.id, deleteFile: true);
    _loadSongs();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed ${song.title} from offline songs')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
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
                    child: Text(
                      'Offline Songs.',
                      style: GoogleFonts.inter(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 30,
                        letterSpacing: -0.8,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: context.primaryColor),
                    )
                  : _songs.isEmpty
                      ? Center(
                          child: GlassPanel(
                            blur: 0,
                            borderRadius: BorderRadius.circular(20),
                            color: context.surfaceColor,
                            borderColor: context.textPrimaryColor.withValues(alpha: 0.13),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cloud_off_rounded,
                                  size: 48,
                                  color: context.textSecondaryColor,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'No offline songs yet',
                                  style: GoogleFonts.inter(
                                    color: context.textPrimaryColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Download tracks from now playing to see them here.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: context.textSecondaryColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8, bottom: 120),
                          itemCount: _songs.length,
                          itemBuilder: (context, index) {
                            final song = _songs[index];
                            return SongTile(
                              title: song.title,
                              artist: song.artist,
                              albumArtUrl: song.albumArtUrl,
                              heroTag: 'art-${song.id}',
                              onTap: () => _playSong(index),
                              onMorePressed: () => _confirmDelete(song),
                              moreIcon: Icons.delete_outline_rounded,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
