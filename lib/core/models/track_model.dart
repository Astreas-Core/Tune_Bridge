import 'package:equatable/equatable.dart';

/// Represents a Spotify track with metadata needed for display and matching.
class TrackModel extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String albumName;
  final String? albumArtUrl;
  final int durationMs;
  final String? youtubeVideoId;
  final String? localPath; // Added for offline playback

  const TrackModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumName,
    this.albumArtUrl,
    required this.durationMs,
    this.youtubeVideoId,
    this.localPath,
  });

  TrackModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumName,
    String? albumArtUrl,
    int? durationMs,
    String? youtubeVideoId,
    String? localPath,
  }) {
    return TrackModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumName: albumName ?? this.albumName,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      durationMs: durationMs ?? this.durationMs,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      localPath: localPath ?? this.localPath,
    );
  }

  /// Creates a TrackModel from Spotify API JSON for a saved-track item.
  factory TrackModel.fromSpotifyJson(Map<String, dynamic> json) {
    final track = json['track'] as Map<String, dynamic>? ?? json;
    final album = track['album'] as Map<String, dynamic>? ?? {};
    final artists = track['artists'] as List<dynamic>? ?? [];
    final images = album['images'] as List<dynamic>? ?? [];

    return TrackModel(
      id: track['id'] as String? ?? '',
      title: track['name'] as String? ?? 'Unknown',
      artist: artists.isNotEmpty
          ? (artists.first['name'] as String? ?? 'Unknown')
          : 'Unknown',
      albumName: album['name'] as String? ?? 'Unknown',
      albumArtUrl: images.isNotEmpty ? images.first['url'] as String? : null,
      durationMs: track['duration_ms'] as int? ?? 0,
    );
  }

  TrackModel copyWithId({String? youtubeVideoId}) {
    return copyWith(youtubeVideoId: youtubeVideoId);
  }

  @override
  List<Object?> get props =>
      [id, title, artist, albumName, albumArtUrl, durationMs, youtubeVideoId, localPath];
}
