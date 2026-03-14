import 'package:get_it/get_it.dart';
import 'package:tune_bridge/core/services/audio_handler.dart';
import 'package:tune_bridge/core/services/audio_player_service.dart';
import 'package:tune_bridge/core/services/download_service.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/core/services/spotify_public_service.dart';
import 'package:tune_bridge/core/services/youtube_service.dart';

/// Global service locator.
final getIt = GetIt.instance;

/// Register all dependencies. Called once at app startup.
/// [localLibrary] must be pre-initialised before calling this.
void setupServiceLocator(
  LocalLibraryService localLibrary,
  TuneBridgeAudioHandler audioHandler,
) {
  // Services
  getIt.registerSingleton<LocalLibraryService>(localLibrary);
  getIt.registerLazySingleton<SpotifyPublicService>(
      () => SpotifyPublicService());
  getIt.registerLazySingleton<YouTubeService>(() => YouTubeService());
  getIt.registerLazySingleton<AudioPlayerService>(
      () => AudioPlayerService(audioHandler));
  getIt.registerLazySingleton<DownloadService>(() => DownloadService());

  // Repositories
  // (Removed unused OAuth repositories)
}
