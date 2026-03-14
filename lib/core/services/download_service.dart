import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/core/services/youtube_service.dart';
import 'package:tune_bridge/core/models/track_model.dart';
import 'package:tune_bridge/core/di.dart';

/// Manages downloading tracks for offline playback.
class DownloadService {
  final Logger _log = Logger();
  final Dio _dio = Dio();
  
  // Lazily get dependencies to avoid circular init issues
  LocalLibraryService get _library => getIt<LocalLibraryService>();
  YouTubeService get _youtube => getIt<YouTubeService>();

  /// Downloads a track and saves it to the offline library.
  /// Returns the local file path on success.
  Future<String?> downloadTrack(TrackModel track) async {
    try {
      _log.i('Starting download for: ${track.title}');
      
      // 1. Get Audio Stream URL
      // Use existing search/stream logic from YouTubeService
      // Note: YouTubeService usually exposes getStreamUrl directly
      String? videoId = track.youtubeVideoId;

      if (videoId == null) {
        _log.i('No video ID for "${track.title}", searching YouTube...');
        videoId = await _youtube.searchVideo(
          title: track.title,
          artist: track.artist,
        );

        if (videoId == null) {
          _log.w('Cannot download track without videoId: ${track.title}');
          return null;
        }
      }

      final streamUrl = await _youtube.getStreamUrl(videoId);
      
      if (streamUrl == null) {
        _log.e('Could not get stream URL');
        return null;
      }

      // 2. Prepare File Path
      final dir = await getApplicationDocumentsDirectory();
      final offlineDir = Directory('${dir.path}/offline_tracks');
      if (!offlineDir.existsSync()) {
        await offlineDir.create(recursive: true);
      }
      
      // Sanitize filename
      final safeId = track.id.replaceAll(RegExp(r'[^\w\d]'), '_');
      final savePath = '${offlineDir.path}/$safeId.m4a';

      // 3. Download File
      await _dio.download(streamUrl, savePath);
      _log.i('Download completed: $savePath');

      // 4. Update Library
      final offlineTrack = track.copyWith(localPath: savePath);
      await _library.addOfflineSong(offlineTrack);
      
      return savePath;
    } catch (e) {
      _log.e('Download failed', error: e);
      return null;
    }
  }

  Future<void> deleteTrack(String trackId) async {
      // Logic to delete file would go here
  }
}
