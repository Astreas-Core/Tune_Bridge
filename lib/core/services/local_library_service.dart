import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:tune_bridge/core/models/track_model.dart';
import 'package:tune_bridge/core/models/playlist_model.dart';

/// Hive-backed local library for liked songs and imported playlists.
/// No network access — all data is persisted on device.
class LocalLibraryService {
  final Logger _log = Logger();

  static const _likedBoxName = 'liked_songs';
  static const _playlistsBoxName = 'local_playlists';
  static const _playlistTracksPrefix = 'playlist_tracks_';

  // static const _offlineBoxName = 'offline_songs'; // Already defined

  static const _offlineBoxName = 'offline_songs';
  
  late Box _likedBox;
  late Box _playlistsBox;
  late Box _offlineBox;

  Future<void> init() async {
    _likedBox = await Hive.openBox(_likedBoxName);
    _playlistsBox = await Hive.openBox(_playlistsBoxName);
    _offlineBox = await Hive.openBox(_offlineBoxName);
    _log.i('LocalLibraryService initialised '
        '(${_likedBox.length} liked, ${_playlistsBox.length} playlists, ${_offlineBox.length} offline)');
  }
  
  // ── Offline Songs ──────────────────────────────────────────────

  List<TrackModel> getOfflineSongs() {
    return _offlineBox.values
        .map((e) => _trackFromJson(e))
        .toList()
        .reversed
        .toList();
  }

  int get offlineCount => _offlineBox.length;

  
  Future<void> addOfflineSong(TrackModel track) async {
    await _offlineBox.put(track.id, _trackToJson(track));
    _log.i('Saved offline: ${track.title}');
  }
  
  bool isOffline(String trackId) {
    return _offlineBox.containsKey(trackId);
  }

  // ── Liked Songs ──────────────────────────────────────────────

  List<TrackModel> getLikedSongs() {
    return _likedBox.values
        .map((e) => _trackFromJson(e))
        .toList()
        .reversed
        .toList(); // newest first
  }

  Future<void> addLikedSong(TrackModel track) async {
    await _likedBox.put(track.id, _trackToJson(track));
    _log.i('Liked: ${track.title}');
  }

  Future<void> addLikedSongs(List<TrackModel> tracks) async {
    final entries = {for (final t in tracks) t.id: _trackToJson(t)};
    await _likedBox.putAll(entries);
    _log.i('Added ${tracks.length} liked songs');
  }

  Future<void> removeLikedSong(String trackId) async {
    await _likedBox.delete(trackId);
  }

  bool isLiked(String trackId) => _likedBox.containsKey(trackId);

  int get likedCount => _likedBox.length;

  // ── Playlists ────────────────────────────────────────────────

  List<PlaylistModel> getPlaylists() {
    return _playlistsBox.values
        .map((e) => _playlistFromJson(e))
        .toList()
        .reversed
        .toList();
  }

  Future<void> savePlaylist(
    PlaylistModel playlist,
    List<TrackModel> tracks,
  ) async {
    await _playlistsBox.put(playlist.id, _playlistToJson(playlist));
    final box = await Hive.openBox('$_playlistTracksPrefix${playlist.id}');
    await box.clear();
    final entries = <String, Map<String, dynamic>>{};
    for (final t in tracks) {
      entries[t.id] = _trackToJson(t);
    }
    await box.putAll(entries);
    _log.i('Saved playlist "${playlist.name}" (${tracks.length} tracks)');
  }

  Future<List<TrackModel>> getPlaylistTracks(String playlistId) async {
    final box = await Hive.openBox('$_playlistTracksPrefix$playlistId');
    return box.values.map((e) => _trackFromJson(e)).toList();
  }

  Future<void> removePlaylist(String playlistId) async {
    await _playlistsBox.delete(playlistId);
    if (Hive.isBoxOpen('$_playlistTracksPrefix$playlistId')) {
      final box = Hive.box('$_playlistTracksPrefix$playlistId');
      await box.deleteFromDisk();
    } else {
      final box = await Hive.openBox('$_playlistTracksPrefix$playlistId');
      await box.deleteFromDisk();
    }
    _log.i('Removed playlist $playlistId');
  }

  int get playlistCount => _playlistsBox.length;

  // ── JSON serialisation helpers ───────────────────────────────

  Map<String, dynamic> _trackToJson(TrackModel t) => {
        'id': t.id,
        'title': t.title,
        'artist': t.artist,
        'albumName': t.albumName,
        'albumArtUrl': t.albumArtUrl,
        'durationMs': t.durationMs,
        'youtubeVideoId': t.youtubeVideoId,
        'localPath': t.localPath,
      };

  TrackModel _trackFromJson(dynamic raw) {
    final m = Map<String, dynamic>.from(raw as Map);
    return TrackModel(
      id: m['id'] as String? ?? '',
      title: m['title'] as String? ?? 'Unknown',
      artist: m['artist'] as String? ?? 'Unknown',
      albumName: m['albumName'] as String? ?? '',
      albumArtUrl: m['albumArtUrl'] as String?,
      durationMs: m['durationMs'] as int? ?? 0,
      youtubeVideoId: m['youtubeVideoId'] as String?,
      localPath: m['localPath'] as String?,
    );
  }

  Map<String, dynamic> _playlistToJson(PlaylistModel p) => {
        'id': p.id,
        'name': p.name,
        'description': p.description,
        'imageUrl': p.imageUrl,
        'trackCount': p.trackCount,
        'ownerName': p.ownerName,
        'folderName': p.folderName,
      };

  PlaylistModel _playlistFromJson(dynamic raw) {
    if (raw == null) {
      return const PlaylistModel(
        id: 'unknown',
        name: 'Corrupted Playlist',
        trackCount: 0,
        ownerName: 'System',
      );
    }
    final m = Map<String, dynamic>.from(raw as Map);
    return PlaylistModel(
      id: m['id'] as String? ?? '',
      name: m['name'] as String? ?? 'Untitled',
      description: m['description'] as String?,
      imageUrl: m['imageUrl'] as String?,
      trackCount: m['trackCount'] as int? ?? 0,
      ownerName: m['ownerName'] as String? ?? 'Unknown',
      folderName: m['folderName'] as String?,
    );
  }
}
