import 'package:flutter/material.dart';
import 'package:tune_bridge/features/library/ui/offline_songs_screen.dart';
import 'package:tune_bridge/features/home/ui/artist_profile_screen.dart';
import 'package:tune_bridge/core/models/track_model.dart';
import 'package:tune_bridge/ui/widgets/main_shell.dart';
import 'package:tune_bridge/ui/widgets/splash_screen.dart';
import 'package:tune_bridge/features/player/ui/now_playing_screen.dart';
import 'package:tune_bridge/features/playlist/ui/playlist_screen.dart';
import 'package:tune_bridge/features/playlist/ui/playlists_list_screen.dart';
import 'package:tune_bridge/features/spotify/ui/liked_songs_screen.dart';
import 'package:tune_bridge/features/search/ui/search_screen.dart';
import 'package:tune_bridge/features/settings/ui/settings_screen.dart';
import 'package:tune_bridge/features/import/ui/import_screen.dart';

/// Centralised route definitions.
class AppRoutes {
  AppRoutes._();

  static const String home = '/home';
  static const String splash = '/splash';
  static const String likedSongs = '/liked-songs';
  static const String offlineSongs = '/offline-songs';
  static const String playlistsList = '/playlists';
  static const String playlist = '/playlist';
  static const String nowPlaying = '/now-playing';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String import_ = '/import';
  static const String artistProfile = '/artist-profile';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return _fade(const SplashScreen());
      case home:
        return _fade(const MainShell());
      case likedSongs:
        return _fade(const LikedSongsScreen());
      case offlineSongs:
        return _fade(const OfflineSongsScreen());
      case playlistsList:
        return _fade(const PlaylistsListScreen());
      case playlist:
        final args = routeSettings.arguments;
        if (args is Map<String, dynamic>) {
          return _fade(PlaylistScreen(
            playlistId: args['id'] as String? ?? '',
            playlistName: args['name'] as String?,
            playlistImageUrl: args['imageUrl'] as String?,
          ));
        }
        final playlistId = args as String? ?? '';
        return _fade(PlaylistScreen(playlistId: playlistId));
      case nowPlaying:
        return _slide(const NowPlayingScreen());
      case search:
        return _fade(const SearchScreen());
      case settings:
        return _fade(const SettingsScreen());
      case import_:
        return _fade(const ImportScreen());
      case artistProfile:
        final args = routeSettings.arguments;
        if (args is Map<String, dynamic>) {
          final artist = args['artist'] as String? ?? 'Artist';
          final tracks = (args['tracks'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<TrackModel>()
              .toList(growable: false);
          return _fade(ArtistProfileScreen(artistName: artist, tracks: tracks));
        }
        return _fade(const ArtistProfileScreen(artistName: 'Artist', tracks: <TrackModel>[]));
      default:
        return _fade(const MainShell());
    }
  }

  static PageRouteBuilder _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static PageRouteBuilder _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }
}
