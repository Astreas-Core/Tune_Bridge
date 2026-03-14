import 'package:equatable/equatable.dart';

/// Represents a Spotify playlist.
class PlaylistModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int trackCount;
  final String ownerName;
  final String? folderName;

  const PlaylistModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.trackCount,
    required this.ownerName,
    this.folderName,
  });

  PlaylistModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? trackCount,
    String? ownerName,
    String? folderName,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      trackCount: trackCount ?? this.trackCount,
      ownerName: ownerName ?? this.ownerName,
      folderName: folderName ?? this.folderName,
    );
  }

  factory PlaylistModel.fromSpotifyJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>? ?? [];
    final owner = json['owner'] as Map<String, dynamic>? ?? {};
    final tracks = json['tracks'] as Map<String, dynamic>? ?? {};

    return PlaylistModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled',
      description: json['description'] as String?,
      imageUrl: images.isNotEmpty ? images.first['url'] as String? : null,
      trackCount: tracks['total'] as int? ?? 0,
      ownerName: owner['display_name'] as String? ?? 'Unknown',
    );
  }

  @override
  List<Object?> get props =>
      [id, name, description, imageUrl, trackCount, ownerName, folderName];
}
