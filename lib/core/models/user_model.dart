import 'package:equatable/equatable.dart';

/// Represents the authenticated Spotify user.
class UserModel extends Equatable {
  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
  });

  factory UserModel.fromSpotifyJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>? ?? [];
    return UserModel(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      avatarUrl: images.isNotEmpty ? images.first['url'] as String? : null,
    );
  }

  @override
  List<Object?> get props => [id, displayName, email, avatarUrl];
}
