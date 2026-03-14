import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/neumorphic.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/core/models/track_model.dart';
import 'package:tune_bridge/features/player/bloc/player_bloc.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/features/player/bloc/player_event.dart';
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
        queueIndex: index
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neumorphic.background,
      appBar: AppBar(
        title: Text('Offline Songs', style: TextStyle(color: Neumorphic.textDark)),
        backgroundColor: Neumorphic.background,
        elevation: 0,
        iconTheme: IconThemeData(color: Neumorphic.iconColor),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Neumorphic.accent))
          : _songs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 64, color: Neumorphic.textLight),
                      const SizedBox(height: 16),
                      Text(
                        'No offline songs yet',
                        style: TextStyle(color: Neumorphic.textLight, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 100),
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    return SongTile(
                      title: song.title,
                      artist: song.artist,
                      albumArtUrl: song.albumArtUrl,
                      onTap: () => _playSong(index),
                    );
                  },
                ),
    );
  }
}
