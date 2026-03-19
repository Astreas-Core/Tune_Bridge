import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tune_bridge/core/constants.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/audio_handler.dart';
import 'package:tune_bridge/core/services/audio_player_service.dart';
import 'package:tune_bridge/core/services/display_refresh_service.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/core/services/youtube_service.dart';
import 'package:tune_bridge/core/theme.dart';
import 'package:tune_bridge/core/theme_cubit.dart';
import 'package:tune_bridge/features/player/bloc/player_bloc.dart';

import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialise Hive local storage
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.settingsBox);

  // Init local library before DI
  final localLibrary = LocalLibraryService();
  await localLibrary.init();

  // Init Audio Service
  final audioHandler = await AudioService.init(
    builder: () => TuneBridgeAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.tunebridge.channel.audio',
      androidNotificationChannelName: 'TuneBridge',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  // Request notification permission for Android 13+
  await Permission.notification.request();

  // Register dependencies
  setupServiceLocator(localLibrary, audioHandler);

  // Apply display refresh mode preference before UI interaction.
  await getIt<DisplayRefreshService>().applySavedPreference();

  runApp(const TuneBridgeApp());
}

class TuneBridgeApp extends StatelessWidget {
  const TuneBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(
          create: (_) => PlayerBloc(
            getIt<AudioPlayerService>(),
            getIt<YouTubeService>(),
            getIt<LocalLibraryService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
