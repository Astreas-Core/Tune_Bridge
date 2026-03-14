import 'package:logger/logger.dart';
import 'package:tune_bridge/core/models/track_model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Searches YouTube and extracts audio stream URLs.
class YouTubeService {
  final Logger _log = Logger();
  final YoutubeExplode _yt = YoutubeExplode();

  /// General search method for UI, returning list of tracks.
  Future<List<TrackModel>> search(String query) async {
    try {
      final results = await _yt.search.search(query);
      return results.take(10).map((video) {
        return TrackModel(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          albumName: 'YouTube',
          albumArtUrl: video.thumbnails.highResUrl,
          durationMs: video.duration?.inMilliseconds ?? 0,
          youtubeVideoId: video.id.value,
        );
      }).toList();
    } catch (e) {
      _log.e('General search failed for "$query": $e');
      return [];
    }
  }

  /// Search YouTube for a matching video. Returns the video ID.
  Future<String?> searchVideo({
    required String title,
    required String artist,
  }) async {
    final queries = [
      '$title $artist',
      '$title $artist audio',
      title,
    ];

    for (final query in queries) {
      try {
        final results = await _yt.search.search(query);
        if (results.isNotEmpty) {
          final video = results.first;
          _log.i('YouTube match: "${video.title}" [${video.id}]');
          return video.id.value;
        }
      } catch (e) {
        _log.w('Search failed for "$query": $e');
      }
    }
    _log.w('No YouTube results for: $title $artist');
    return null;
  }

  /// Get a playable audio stream URL for a video.
  /// Uses a fresh client each time to avoid stale tokens.
  Future<String?> getStreamUrl(String videoId) async {
    final freshYt = YoutubeExplode();
    try {
      final manifest = await freshYt.videos.streamsClient.getManifest(videoId);

      // Prioritize Muxed streams (Video + Audio) to avoid 403 errors
      // YouTube throttles audio-only streams more frequently for non-browser clients
      final muxed = manifest.muxed.sortByBitrate();
      if (muxed.isNotEmpty) {
        // Pick the best quality muxed stream (usually 720p/1080p has decent AAC audio)
        final bestMuxed = muxed.last;
        _log.i('Selected muxed stream (stable): ${bestMuxed.bitrate}, ${bestMuxed.container}');
        return bestMuxed.url.toString();
      }

      // Fallback: Audio-only streams if no muxed found
      final audioStreams = manifest.audioOnly.sortByBitrate();
      if (audioStreams.isNotEmpty) {
        final bestAudio = audioStreams.last;
        _log.w('Fallback to audio-only stream: ${bestAudio.bitrate}, ${bestAudio.container}');
        return bestAudio.url.toString();
      }

      _log.w('No streams found for video: $videoId');
      return null;
    } catch (e) {
      _log.e('Failed to get stream URL for $videoId: $e');
      return null;
    } finally {
      freshYt.close();
    }
  }

  void dispose() {
    _yt.close();
  }
}
