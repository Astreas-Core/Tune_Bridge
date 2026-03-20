import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:tune_bridge/core/constants.dart';

/// Resolves artist profile photos using public endpoints (no login/API key).
class ArtistImageService {
  static const String _cacheKey = 'artist_image_cache_v1';
  static const Duration _requestTimeout = Duration(seconds: 7);

  final Logger _log = Logger();

  Map<String, String> _cache = <String, String>{};
  bool _loaded = false;

  Box get _settings => Hive.box(AppConstants.settingsBox);

  Future<String?> resolveArtistImage(String artistName) async {
    final normalized = _normalize(artistName);
    if (normalized.isEmpty) return null;

    await _ensureLoaded();

    final cached = _cache[normalized];
    if (cached != null) {
      return cached.isEmpty ? null : cached;
    }

    try {
      final uri = Uri.https('api.deezer.com', '/search/artist', {
        'q': artistName,
      });
      final response = await http.get(uri).timeout(_requestTimeout);
      if (response.statusCode != 200) {
        _cache[normalized] = '';
        await _persist();
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? const [];
      if (data.isEmpty) {
        _cache[normalized] = '';
        await _persist();
        return null;
      }

      Map<String, dynamic>? best;
      var bestScore = -1;
      for (final item in data.take(8)) {
        if (item is! Map<String, dynamic>) continue;
        final name = (item['name'] as String? ?? '').trim();
        final score = _scoreMatch(normalized, _normalize(name));
        if (score > bestScore) {
          best = item;
          bestScore = score;
        }
      }

      final imageUrl = (best?['picture_xl'] as String?)?.trim().isNotEmpty == true
          ? (best!['picture_xl'] as String).trim()
          : (best?['picture_big'] as String?)?.trim().isNotEmpty == true
              ? (best!['picture_big'] as String).trim()
              : (best?['picture_medium'] as String?)?.trim();

      _cache[normalized] = imageUrl == null || imageUrl.isEmpty ? '' : imageUrl;
      await _persist();
      return imageUrl == null || imageUrl.isEmpty ? null : imageUrl;
    } catch (e) {
      _log.w('Artist image resolve failed for "$artistName": $e');
      return null;
    }
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final dynamic raw = _settings.get(_cacheKey, defaultValue: <String, String>{});
    if (raw is Map) {
      _cache = raw.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      );
    }
  }

  Future<void> _persist() async {
    await _settings.put(_cacheKey, _cache);
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  int _scoreMatch(String query, String candidate) {
    if (candidate == query) return 100;
    if (candidate.startsWith(query)) return 80;
    if (candidate.contains(query)) return 65;
    if (query.contains(candidate) && candidate.length >= 4) return 50;
    final overlap = query.split(' ').where(candidate.split(' ').contains).length;
    return overlap * 10;
  }
}
