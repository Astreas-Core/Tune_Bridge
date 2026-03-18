import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:tune_bridge/core/models/track_model.dart';
import 'package:tune_bridge/core/models/playlist_model.dart';

/// Fetches public Spotify data by parsing embed pages directly.
/// No OAuth login, no Premium, no developer app required.
/// Uses __NEXT_DATA__ JSON from embed pages — no API calls needed.
class SpotifyPublicService {
  final Logger _log = Logger();
  static const Duration _requestTimeout = Duration(seconds: 12);
  static const int _artworkConcurrency = 8;

  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 15; Pixel 9) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';

  // ── URL parsing ──────────────────────────────────────────────

  static ({String type, String id})? parseSpotifyUrl(String input) {
    input = input.trim();

    final uriMatch = RegExp(r'^spotify:(track|album|playlist):([A-Za-z0-9]+)')
        .firstMatch(input);
    if (uriMatch != null) {
      return (type: uriMatch.group(1)!, id: uriMatch.group(2)!);
    }

    final urlMatch = RegExp(
      r'open\.spotify\.com/(track|album|playlist)/([A-Za-z0-9]+)',
    ).firstMatch(input);
    if (urlMatch != null) {
      return (type: urlMatch.group(1)!, id: urlMatch.group(2)!);
    }

    return null;
  }

  // ── Embed page fetching ──────────────────────────────────────

  /// Fetch the embed page and extract the entity from __NEXT_DATA__.
  Future<Map<String, dynamic>> _fetchEntity(String type, String id) async {
    final url = 'https://open.spotify.com/embed/$type/$id';
    _log.i('Fetching embed: $url');

    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': _userAgent,
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
    }).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception(
          'Spotify embed returned ${response.statusCode} for $type/$id');
    }

    final nextDataMatch = RegExp(
      r'<script\s+id="__NEXT_DATA__"\s+type="application/json">\s*({.+?})\s*</script>',
      dotAll: true,
    ).firstMatch(response.body);

    if (nextDataMatch == null) {
      throw Exception('No __NEXT_DATA__ found in embed page');
    }

    final json = jsonDecode(nextDataMatch.group(1)!) as Map<String, dynamic>;
    final entity = json['props']?['pageProps']?['state']?['data']?['entity']
        as Map<String, dynamic>?;

    if (entity == null) {
      throw Exception('No entity found in embed page JSON');
    }

    _log.i('Got entity: type=${entity['type']}, name=${entity['name'] ?? entity['title']}');
    return entity;
  }

  // ── Spotify oEmbed API (always works, no auth) ──────────────

  Future<({String title, String? thumbnailUrl})> _fetchOembed(
      String type, String id) async {
    final url =
        'https://open.spotify.com/oembed?url=https://open.spotify.com/$type/$id';
    final res = await http.get(Uri.parse(url), headers: {
      'User-Agent': _userAgent,
      'Accept': 'application/json',
    }).timeout(_requestTimeout);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return (
        title: json['title'] as String? ?? 'Unknown',
        thumbnailUrl: json['thumbnail_url'] as String?,
      );
    }
    throw Exception('oEmbed failed: ${res.statusCode}');
  }

  // ── Track import ─────────────────────────────────────────────

  Future<TrackModel> getTrack(String id) async {
    try {
      final entity = await _fetchEntity('track', id);
      final coverArt = entity['coverArt']?['sources'] as List<dynamic>? ?? [];
      final imageUrl = _getLargestImageUrl(coverArt);

      return TrackModel(
        id: entity['id'] as String? ??
            entity['uri']?.toString().split(':').last ?? id,
        title: entity['title'] as String? ??
            entity['name'] as String? ?? 'Unknown',
        artist: entity['subtitle'] as String? ??
            _extractArtistFromEntity(entity),
        albumName: '',
        albumArtUrl: imageUrl,
        durationMs: entity['duration'] as int? ?? 0,
      );
    } catch (e) {
      _log.w('Embed track failed: $e, trying oEmbed');
      final oembed = await _fetchOembed('track', id);
      // oEmbed title format: "Artist - Title"
      final parts = oembed.title.split(' - ');
      return TrackModel(
        id: id,
        title: parts.length > 1 ? parts.sublist(1).join(' - ').trim() : oembed.title,
        artist: parts.isNotEmpty ? parts[0].trim() : 'Unknown',
        albumName: '',
        albumArtUrl: oembed.thumbnailUrl,
        durationMs: 0,
      );
    }
  }

  String? _getLargestImageUrl(List<dynamic>? coverArt) {
    if (coverArt == null || coverArt.isEmpty) return null;

    dynamic largestImage;
    int maxWidth = -1;

    for (final source in coverArt) {
      final w = source['width'] as int? ?? 0;
      if (w > maxWidth) {
        maxWidth = w;
        largestImage = source;
      }
    }
    
    // Fallback to first if no width found or something matched
    largestImage ??= coverArt.first;
    
    return largestImage['url'] as String?;
  }

  String _extractArtistFromEntity(Map<String, dynamic> entity) {
    final authors = entity['authors'] as List<dynamic>?;
    if (authors != null && authors.isNotEmpty) {
      return authors.first['name'] as String? ?? 'Unknown';
    }
    final artists = entity['artists'] as List<dynamic>?;
    if (artists != null && artists.isNotEmpty) {
      final first = artists.first;
      if (first is Map) return first['name'] as String? ?? 'Unknown';
      return first.toString();
    }
    return 'Unknown';
  }

  // ── Playlist import ──────────────────────────────────────────

  Future<PlaylistModel> getPlaylistInfo(String id) async {
      // Playlist
    try {
      final entity = await _fetchEntity('playlist', id);
      final coverArt = entity['coverArt']?['sources'] as List<dynamic>? ?? [];
      final imageUrl = _getLargestImageUrl(coverArt);
      final trackList = entity['trackList'] as List<dynamic>? ?? [];

      return PlaylistModel(
        id: entity['id'] as String? ?? id,
        name: entity['name'] as String? ??
            entity['title'] as String? ?? 'Unknown Playlist',
        imageUrl: imageUrl,
        trackCount: trackList.length,
        ownerName: _extractArtistFromEntity(entity),
      );
    } catch (e) {
      _log.w('Embed playlist info failed: $e, trying oEmbed');
      final oembed = await _fetchOembed('playlist', id);
      return PlaylistModel(
        id: id,
        name: oembed.title,
        imageUrl: oembed.thumbnailUrl,
        trackCount: 0,
        ownerName: 'Spotify',
      );
    }
  }

  Future<List<TrackModel>> getPlaylistTracks(
    String id, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final entity = await _fetchEntity('playlist', id);
    final trackList = entity['trackList'] as List<dynamic>? ?? [];
    final coverArt = entity['coverArt']?['sources'] as List<dynamic>? ?? [];
    final playlistImageUrl = _getLargestImageUrl(coverArt);
    final artworkCache = <String, String?>{};
    final tracks = List<TrackModel?>.filled(trackList.length, null, growable: false);
    var completed = 0;
    onProgress?.call(completed, trackList.length);

    for (var i = 0; i < trackList.length; i += _artworkConcurrency) {
      final end = (i + _artworkConcurrency > trackList.length)
          ? trackList.length
          : i + _artworkConcurrency;

      final futures = <Future<void>>[];
      for (var idx = i; idx < end; idx++) {
        futures.add(() async {
          final t = trackList[idx] as Map<String, dynamic>;
          final uri = t['uri'] as String? ?? '';
          final trackId = uri.contains(':') ? uri.split(':').last : 'embed_$idx';

          final embeddedTrackArt = _extractTrackImageFromEmbedItem(t);
          final trackArtwork = embeddedTrackArt ??
              await _resolveTrackArtwork(
                trackId,
                cache: artworkCache,
                fallbackUrl: playlistImageUrl,
              );

          tracks[idx] = TrackModel(
            id: trackId,
            title: t['title'] as String? ?? 'Unknown',
            artist: t['subtitle'] as String? ?? 'Unknown',
            albumName: '',
            albumArtUrl: trackArtwork,
            durationMs: t['duration'] as int? ?? 0,
          );
          completed += 1;
          onProgress?.call(completed, trackList.length);
        }());
      }
      await Future.wait(futures);
    }

    final resolvedTracks = tracks
        .whereType<TrackModel>()
        .toList(growable: false);

    _log.i('Parsed ${resolvedTracks.length} tracks from embed page');
    if (resolvedTracks.isEmpty) {
      throw Exception('No tracks found in playlist');
    }
    return resolvedTracks;
  }

  Future<String?> _resolveTrackArtwork(
    String trackId, {
    required Map<String, String?> cache,
    String? fallbackUrl,
  }) async {
    if (cache.containsKey(trackId)) {
      return cache[trackId] ?? fallbackUrl;
    }

    try {
      final oembed = await _fetchOembed('track', trackId);
      final thumbnail = oembed.thumbnailUrl;
      cache[trackId] = thumbnail;
      return thumbnail ?? fallbackUrl;
    } catch (_) {
      cache[trackId] = null;
      return fallbackUrl;
    }
  }

  String? _extractTrackImageFromEmbedItem(Map<String, dynamic> item) {
    final direct = item['imageUrl'] as String? ?? item['image_url'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;

    final images = item['images'];
    if (images is List && images.isNotEmpty) {
      final image = images.first;
      if (image is Map<String, dynamic>) {
        final url = image['url'] as String?;
        if (url != null && url.isNotEmpty) return url;
      }
    }

    final coverArt = item['coverArt'];
    if (coverArt is Map<String, dynamic>) {
      final sources = coverArt['sources'] as List<dynamic>?;
      final url = _getLargestImageUrl(sources);
      if (url != null && url.isNotEmpty) return url;
    }

    return null;
  }

  // ── Album import ─────────────────────────────────────────────

  Future<PlaylistModel> getAlbumInfo(String id) async {
      // Album
    try {
      final entity = await _fetchEntity('album', id);
      final coverArt = entity['coverArt']?['sources'] as List<dynamic>? ?? [];
      final imageUrl = _getLargestImageUrl(coverArt);
      final trackList = entity['trackList'] as List<dynamic>? ?? [];

      return PlaylistModel(
        id: entity['id'] as String? ?? id,
        name: entity['name'] as String? ??
            entity['title'] as String? ?? 'Unknown Album',
        description: 'Album',
        imageUrl: imageUrl,
        trackCount: trackList.length,
        ownerName: entity['subtitle'] as String? ??
            _extractArtistFromEntity(entity),
      );
    } catch (e) {
      _log.w('Embed album info failed: $e, trying oEmbed');
      final oembed = await _fetchOembed('album', id);
      return PlaylistModel(
        id: id,
        name: oembed.title,
        imageUrl: oembed.thumbnailUrl,
        trackCount: 0,
        ownerName: 'Unknown',
      );
    }
  }

  Future<List<TrackModel>> getAlbumTracks(
    String id, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final entity = await _fetchEntity('album', id);
    final trackList = entity['trackList'] as List<dynamic>? ?? [];
    final coverArt = entity['coverArt']?['sources'] as List<dynamic>? ?? [];
    final albumImageUrl = _getLargestImageUrl(coverArt);
    final albumName = entity['name'] as String? ??
        entity['title'] as String? ?? '';

    final tracks = <TrackModel>[];
    var completed = 0;
    onProgress?.call(completed, trackList.length);
    for (final item in trackList) {
      final t = item as Map<String, dynamic>;
      final uri = t['uri'] as String? ?? '';
      final trackId = uri.contains(':') ? uri.split(':').last : 'embed_${tracks.length}';

      tracks.add(TrackModel(
        id: trackId,
        title: t['title'] as String? ?? 'Unknown',
        artist: t['subtitle'] as String? ?? 'Unknown',
        albumName: albumName,
        albumArtUrl: albumImageUrl,
        durationMs: t['duration'] as int? ?? 0,
      ));
      completed += 1;
      onProgress?.call(completed, trackList.length);
    }

    _log.i('Parsed ${tracks.length} album tracks from embed');
    if (tracks.isEmpty) {
      throw Exception('No tracks found in album');
    }
    return tracks;
  }

  // ── High-level import ────────────────────────────────────────

  Future<({String name, List<TrackModel> tracks})> importFromUrl(
      String url) async {
    final parsed = parseSpotifyUrl(url);
    if (parsed == null) {
      throw Exception('Invalid Spotify URL');
    }

    _log.i('Importing ${parsed.type}/${parsed.id}');

    switch (parsed.type) {
      case 'track':
        final track = await getTrack(parsed.id);
        return (name: track.title, tracks: [track]);
      case 'playlist':
        final info = await getPlaylistInfo(parsed.id);
        final tracks = await getPlaylistTracks(parsed.id);
        return (name: info.name, tracks: tracks);
      case 'album':
        final info = await getAlbumInfo(parsed.id);
        final tracks = await getAlbumTracks(parsed.id);
        return (name: info.name, tracks: tracks);
      default:
        throw Exception('Unsupported Spotify type: ${parsed.type}');
    }
  }
}
