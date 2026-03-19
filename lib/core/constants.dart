/// App-wide constants for TuneBridge.
class AppConstants {
  AppConstants._();

  static const String appName = 'TuneBridge';

  // Spotify API
  static const String spotifyClientId = '30316bc52604440785bce01a5ad36705';
  static const String spotifyRedirectUri = 'tunebridge://callback';
  static const String spotifyAuthUrl = 'https://accounts.spotify.com/authorize';
  static const String spotifyTokenUrl = 'https://accounts.spotify.com/api/token';
  static const String spotifyBaseUrl = 'https://api.spotify.com/v1';
  static const List<String> spotifyScopes = [
  'user-read-private',
  'user-read-email',
  'playlist-read-private',
  'playlist-read-collaborative',
];

  // GitHub release updates (set these before using in-app update checker)
  static const String githubOwner = 'Astreas-Core';
  static const String githubRepo = 'Tune_Bridge';
  static const String githubLatestReleaseApi =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  // Pagination
  static const int defaultPageSize = 20;

  // Hive box names
  static const String userBox = 'user_box';
  static const String tracksBox = 'tracks_box';
  static const String playlistsBox = 'playlists_box';
  static const String settingsBox = 'settings_box';
}

/// Shared spacing scale used across screens/widgets.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 14;
}

/// Shared border radius tokens for consistent curves.
class AppRadii {
  AppRadii._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 28;
}
