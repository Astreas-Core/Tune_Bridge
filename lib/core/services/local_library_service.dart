import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/foundation.dart';
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
  static const _recentBoxName = 'recent_tracks';

  // static const _offlineBoxName = 'offline_songs'; // Already defined

  static const _offlineBoxName = 'offline_songs';
  
  late Box _likedBox;
  late Box _playlistsBox;
  late Box _offlineBox;
  late Box _recentBox;
  List<TrackModel>? _knownTracksCache;
  int _knownTracksCacheAtMs = 0;

  Future<void> init() async {
    _likedBox = await Hive.openBox(_likedBoxName);
    _playlistsBox = await Hive.openBox(_playlistsBoxName);
    _offlineBox = await Hive.openBox(_offlineBoxName);
    _recentBox = await Hive.openBox(_recentBoxName);
    _log.i('LocalLibraryService initialised '
      '(${_likedBox.length} liked, ${_playlistsBox.length} playlists, ${_offlineBox.length} offline, ${_recentBox.length} recent)');
  }
  
  // ── Offline Songs ──────────────────────────────────────────────

  List<TrackModel> getOfflineSongs() {
    return _offlineBox.values
        .map((e) => _trackFromJson(e))
        .where((track) {
          final path = track.localPath;
          return path != null && path.isNotEmpty && File(path).existsSync();
        })
        .toList()
        .reversed
        .toList();
  }

  int get offlineCount => _offlineBox.length;
  ValueListenable<Box> get offlineSongsListenable => _offlineBox.listenable();

  // ── Recently Played ───────────────────────────────────────────

  List<TrackModel> getRecentTracks({int limit = 12}) {
    final entries = _recentBox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    entries.sort((a, b) {
      final aPlayed = a['playedAt'] as int? ?? 0;
      final bPlayed = b['playedAt'] as int? ?? 0;
      return bPlayed.compareTo(aPlayed);
    });

    return entries
        .take(limit)
        .map((e) => _trackFromJson(e['track']))
        .toList(growable: false);
  }

  Future<List<TrackModel>> getPersonalizedRecommendations({int limit = 10, int seed = 0}) async {
    final recentEntries = _recentBox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    recentEntries.sort((a, b) {
      final aPlayed = a['playedAt'] as int? ?? 0;
      final bPlayed = b['playedAt'] as int? ?? 0;
      return bPlayed.compareTo(aPlayed);
    });

    final history = recentEntries
        .map((e) => _trackFromJson(e['track']))
        .toList(growable: false);

    if (history.isEmpty) {
      return _fallbackRecommendations(limit: limit);
    }

    final candidates = await _collectCandidateTracks();
    if (candidates.isEmpty) {
      return const <TrackModel>[];
    }

    final profile = _buildPreferenceProfile(history);
    final excluded = history.take(3).map((t) => _trackFingerprint(t)).toSet();
    final likedIds = _likedBox.keys.map((e) => e.toString()).toSet();
    final recencyIndex = <String, int>{};
    for (var i = 0; i < history.length; i++) {
      recencyIndex[_trackFingerprint(history[i])] = i;
    }

    final scored = <({TrackModel track, double score, _TrackFeatures features})>[];
    for (final track in candidates) {
      final fp = _trackFingerprint(track);
      if (excluded.contains(fp)) continue;

      final features = _extractFeatures(track);
      final score = _scoreTrack(
        track: track,
        features: features,
        profile: profile,
        likedIds: likedIds,
        recencyIndex: recencyIndex,
        history: history,
        seed: seed,
      );
      if (score > 0) {
        scored.add((track: track, score: score, features: features));
      }
    }

    if (scored.isEmpty) {
      return _fallbackRecommendations(limit: limit);
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return _diversifiedPick(scored, limit, seed: seed);
  }

  Future<void> addRecentTrack(TrackModel track) async {
    _invalidateKnownTracksCache();
    await _recentBox.put(track.id, {
      'track': _trackToJson(track),
      'playedAt': DateTime.now().millisecondsSinceEpoch,
    });

    // Keep recent history bounded so the box does not grow unbounded.
    if (_recentBox.length > 30) {
      final entries = _recentBox.toMap().entries
          .map((e) => (
                key: e.key,
                playedAt: (Map<String, dynamic>.from(e.value as Map))['playedAt'] as int? ?? 0,
              ))
          .toList(growable: false)
        ..sort((a, b) => b.playedAt.compareTo(a.playedAt));

      final keysToDelete = entries.skip(30).map((e) => e.key).toList(growable: false);
      if (keysToDelete.isNotEmpty) {
        await _recentBox.deleteAll(keysToDelete);
      }
    }
  }

  ValueListenable<Box> get recentTracksListenable => _recentBox.listenable();

  /// Returns a deduplicated view of all locally known tracks.
  /// Includes liked, offline, playlist tracks and recent history.
  Future<List<TrackModel>> getAllKnownTracks() {
    return _collectCandidateTracks();
  }

  Future<List<TrackModel>> _collectCandidateTracks() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (_knownTracksCache != null && (nowMs - _knownTracksCacheAtMs) < 45000) {
      return _knownTracksCache!;
    }

    final dedup = <String, TrackModel>{};

    for (final raw in _likedBox.values) {
      final t = _trackFromJson(raw);
      dedup.putIfAbsent(_trackFingerprint(t), () => t);
    }

    for (final raw in _offlineBox.values) {
      final t = _trackFromJson(raw);
      dedup.putIfAbsent(_trackFingerprint(t), () => t);
    }

    for (final playlistId in _playlistsBox.keys.map((e) => e.toString())) {
      final box = await Hive.openBox('$_playlistTracksPrefix$playlistId');
      for (final raw in box.values) {
        final t = _trackFromJson(raw);
        dedup.putIfAbsent(_trackFingerprint(t), () => t);
      }
    }

    // Include history tracks as a fallback candidate set.
    for (final raw in _recentBox.values) {
      final m = Map<String, dynamic>.from(raw as Map);
      final t = _trackFromJson(m['track']);
      dedup.putIfAbsent(_trackFingerprint(t), () => t);
    }

    final result = dedup.values.toList(growable: false);
    _knownTracksCache = result;
    _knownTracksCacheAtMs = nowMs;
    return result;
  }

  List<TrackModel> _fallbackRecommendations({required int limit}) {
    final fallback = <TrackModel>[];
    fallback.addAll(getLikedSongs());
    fallback.addAll(getOfflineSongs());
    fallback.addAll(getRecentTracks(limit: limit * 2));

    final dedup = <String, TrackModel>{};
    for (final t in fallback) {
      dedup.putIfAbsent(_trackFingerprint(t), () => t);
    }

    return dedup.values.take(limit).toList(growable: false);
  }

  _PreferenceProfile _buildPreferenceProfile(List<TrackModel> history) {
    final profile = _PreferenceProfile();
    final top = history.take(30).toList(growable: false);

    for (var i = 0; i < top.length; i++) {
      final track = top[i];
      final weight = 1.0 / (1.0 + i / 3.0);
      final features = _extractFeatures(track);

      profile.artistAffinity.update(
        track.artist.toLowerCase().trim(),
        (v) => v + weight,
        ifAbsent: () => weight,
      );

      profile.languageAffinity.update(
        features.language,
        (v) => v + weight,
        ifAbsent: () => weight,
      );

      for (final t in features.typeTags) {
        profile.typeAffinity.update(t, (v) => v + weight, ifAbsent: () => weight);
      }

      for (final k in features.keywords) {
        profile.keywordAffinity.update(k, (v) => v + weight, ifAbsent: () => weight);
      }
    }

    return profile;
  }

  _TrackFeatures _extractFeatures(TrackModel track) {
    final text = '${track.title} ${track.artist} ${track.albumName}'.toLowerCase();
    final language = _guessLanguageBucket(track);

    final typeTags = <String>{};
    if (RegExp(r'\b(remix|mix|edit|version)\b').hasMatch(text)) {
      typeTags.add('mix');
    }
    if (RegExp(r'\b(live|concert|acoustic|unplugged)\b').hasMatch(text)) {
      typeTags.add('live');
    }
    if (RegExp(r'\b(inst|instrumental|karaoke|bgm)\b').hasMatch(text)) {
      typeTags.add('instrumental');
    }
    if (RegExp(r'\b(lofi|lo-fi|chill|ambient|sleep)\b').hasMatch(text)) {
      typeTags.add('chill');
    }
    if (RegExp(r'\b(rap|hip hop|hip-hop|trap)\b').hasMatch(text)) {
      typeTags.add('rap');
    }
    if (RegExp(r'\b(devotional|bhajan|qawwali|worship)\b').hasMatch(text)) {
      typeTags.add('devotional');
    }

    final keywords = <String>{};
    for (final match in RegExp(r'[a-z0-9]+').allMatches(text)) {
      final token = match.group(0)!;
      if (token.length < 3) continue;
      if (_stopWords.contains(token)) continue;
      keywords.add(token);
      if (keywords.length >= 18) break;
    }

    return _TrackFeatures(
      language: language,
      typeTags: typeTags,
      keywords: keywords,
    );
  }

  String _guessLanguageBucket(TrackModel track) {
    final text = '${track.title} ${track.artist} ${track.albumName}';
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) return 'indic-devanagari';
    if (RegExp(r'[\u0980-\u09FF]').hasMatch(text)) return 'indic-bengali';
    if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(text)) return 'indic-gujarati';
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(text)) return 'indic-tamil';
    if (RegExp(r'[\u0C00-\u0C7F]').hasMatch(text)) return 'indic-telugu-kannada';
    if (RegExp(r'[\u3040-\u30FF\u31F0-\u31FF]').hasMatch(text)) return 'japanese';
    if (RegExp(r'[\uAC00-\uD7AF]').hasMatch(text)) return 'korean';
    if (RegExp(r'[\u4E00-\u9FFF]').hasMatch(text)) return 'cjk';
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) return 'arabic';
    if (RegExp(r'[\u0400-\u04FF]').hasMatch(text)) return 'cyrillic';
    return 'latin';
  }

  double _scoreTrack({
    required TrackModel track,
    required _TrackFeatures features,
    required _PreferenceProfile profile,
    required Set<String> likedIds,
    required Map<String, int> recencyIndex,
    required List<TrackModel> history,
    required int seed,
  }) {
    var score = 0.0;

    final artistKey = track.artist.toLowerCase().trim();
    score += (profile.artistAffinity[artistKey] ?? 0) * 2.4;
    score += (profile.languageAffinity[features.language] ?? 0) * 1.8;

    for (final tag in features.typeTags) {
      score += (profile.typeAffinity[tag] ?? 0) * 1.2;
    }

    for (final token in features.keywords) {
      score += (profile.keywordAffinity[token] ?? 0) * 0.18;
    }

    if (likedIds.contains(track.id)) {
      score += 0.8;
    }

    final seenIndex = recencyIndex[_trackFingerprint(track)];
    if (seenIndex != null) {
      // Mild boost for known-good songs, with decay for older history.
      score += 0.9 * math.exp(-seenIndex / 8.0);
    }

    final normalizedTitle = track.title.toLowerCase();
    if (normalizedTitle.contains('instrumental') || normalizedTitle.contains('karaoke')) {
      score -= 0.55;
    }

    // Reward candidates that share meaningful title tokens with highly recent tracks.
    final recentHead = history.take(5);
    var semanticBoost = 0.0;
    for (final h in recentHead) {
      final hTokens = _extractFeatures(h).keywords;
      if (hTokens.isEmpty || features.keywords.isEmpty) continue;
      final overlap = hTokens.intersection(features.keywords).length;
      if (overlap > 0) {
        semanticBoost += 0.22 * overlap;
      }
    }
    score += semanticBoost;

    // Tiny deterministic jitter allows frequent refresh changes without random junk.
    final hashJitter = ((_trackFingerprint(track).hashCode ^ seed) & 0xFF) / 255.0;
    score += hashJitter * 0.18;

    return score;
  }

  List<TrackModel> _diversifiedPick(
    List<({TrackModel track, double score, _TrackFeatures features})> ranked,
    int limit,
    {int seed = 0}
  ) {
    if (ranked.isEmpty) return const <TrackModel>[];

    final selected = <TrackModel>[];
    final artistUsage = <String, int>{};
    final languageUsage = <String, int>{};

    final topWindow = ranked.take(math.min(18, ranked.length)).toList(growable: true);
    final tail = ranked.skip(topWindow.length).toList(growable: false);

    final bucket = DateTime.now().millisecondsSinceEpoch ~/
        const Duration(minutes: 3).inMilliseconds;
    topWindow.shuffle(math.Random(bucket + seed + ranked.length));

    final remaining = <({TrackModel track, double score, _TrackFeatures features})>[
      ...topWindow,
      ...tail,
    ];
    while (selected.length < limit && remaining.isNotEmpty) {
      var bestIdx = 0;
      var bestValue = -1e9;

      for (var i = 0; i < remaining.length; i++) {
        final entry = remaining[i];
        final artist = entry.track.artist.toLowerCase().trim();
        final lang = entry.features.language;

        final diversityPenalty =
            (artistUsage[artist] ?? 0) * 0.9 + (languageUsage[lang] ?? 0) * 0.35;
        final value = entry.score - diversityPenalty;

        if (value > bestValue) {
          bestValue = value;
          bestIdx = i;
        }
      }

      final picked = remaining.removeAt(bestIdx);
      selected.add(picked.track);
      final artist = picked.track.artist.toLowerCase().trim();
      final lang = picked.features.language;
      artistUsage[artist] = (artistUsage[artist] ?? 0) + 1;
      languageUsage[lang] = (languageUsage[lang] ?? 0) + 1;
    }

    return selected;
  }

  String _trackFingerprint(TrackModel t) {
    return '${t.id}::${t.title.toLowerCase().trim()}::${t.artist.toLowerCase().trim()}';
  }

  void _invalidateKnownTracksCache() {
    _knownTracksCache = null;
    _knownTracksCacheAtMs = 0;
  }

  static const Set<String> _stopWords = {
    'the', 'and', 'with', 'for', 'from', 'feat', 'feat.', 'ft', 'ft.', 'version',
    'song', 'track', 'official', 'audio', 'video', 'music', 'remastered', 'single',
    'original', 'edit', 'mix', 'live', 'album', 'ep', 'ost', 'vol', 'part',
  };

  
  Future<void> addOfflineSong(TrackModel track) async {
    _invalidateKnownTracksCache();
    await _offlineBox.put(track.id, _trackToJson(track));
    _log.i('Saved offline: ${track.title}');
  }

  Future<void> removeOfflineSong(String trackId, {bool deleteFile = true}) async {
    final existing = getOfflineSongById(trackId);
    if (existing == null) return;

    _invalidateKnownTracksCache();
    await _offlineBox.delete(trackId);

    if (deleteFile) {
      final path = existing.localPath;
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (file.existsSync()) {
          try {
            await file.delete();
          } catch (e) {
            _log.w('Failed to delete offline file at $path: $e');
          }
        }
      }
    }
    _log.i('Removed offline song: ${existing.title}');
  }
  
  bool isOffline(String trackId) {
    return _offlineBox.containsKey(trackId);
  }

  bool hasPlayableOfflineCopy(String trackId) {
    final track = getOfflineSongById(trackId);
    final path = track?.localPath;
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }

  TrackModel? getOfflineSongById(String trackId) {
    final raw = _offlineBox.get(trackId);
    if (raw == null) return null;
    return _trackFromJson(raw);
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
    _invalidateKnownTracksCache();
    await _likedBox.put(track.id, _trackToJson(track));
    _log.i('Liked: ${track.title}');
  }

  Future<void> addLikedSongs(List<TrackModel> tracks) async {
    _invalidateKnownTracksCache();
    final entries = {for (final t in tracks) t.id: _trackToJson(t)};
    await _likedBox.putAll(entries);
    _log.i('Added ${tracks.length} liked songs');
  }

  Future<void> removeLikedSong(String trackId) async {
    _invalidateKnownTracksCache();
    await _likedBox.delete(trackId);
  }

  bool isLiked(String trackId) => _likedBox.containsKey(trackId);

  int get likedCount => _likedBox.length;
  ValueListenable<Box> get likedSongsListenable => _likedBox.listenable();

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
    _invalidateKnownTracksCache();
    await _playlistsBox.put(playlist.id, _playlistToJson(playlist));
    final box = await Hive.openBox('$_playlistTracksPrefix${playlist.id}');
    await box.clear();
    final entries = <String, Map<String, dynamic>>{};
    for (var i = 0; i < tracks.length; i++) {
      final t = tracks[i];
      // Index-based key keeps exact Spotify order and allows duplicate track IDs.
      final key = '${i.toString().padLeft(6, '0')}::${t.id}';
      entries[key] = _trackToJson(t);
    }
    await box.putAll(entries);
    _log.i('Saved playlist "${playlist.name}" (${tracks.length} tracks)');
  }

  Future<List<TrackModel>> getPlaylistTracks(String playlistId) async {
    final box = await Hive.openBox('$_playlistTracksPrefix$playlistId');
    final keys = box.keys.map((e) => e.toString()).toList()..sort();
    return keys.map((k) => _trackFromJson(box.get(k))).toList();
  }

  Future<void> removePlaylist(String playlistId) async {
    _invalidateKnownTracksCache();
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
  ValueListenable<Box> get playlistsListenable => _playlistsBox.listenable();

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

class _TrackFeatures {
  final String language;
  final Set<String> typeTags;
  final Set<String> keywords;

  const _TrackFeatures({
    required this.language,
    required this.typeTags,
    required this.keywords,
  });
}

class _PreferenceProfile {
  final Map<String, double> artistAffinity = <String, double>{};
  final Map<String, double> languageAffinity = <String, double>{};
  final Map<String, double> typeAffinity = <String, double>{};
  final Map<String, double> keywordAffinity = <String, double>{};
}
