import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:tune_bridge/core/constants.dart';

/// The specific AudioHandler implementation for TuneBridge.
class TuneBridgeAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  final Logger _log = Logger();

  // Streams for external control (e.g. BLoC)
  final _skipNextController = StreamController<void>.broadcast();
  final _skipPreviousController = StreamController<void>.broadcast();
  
  Stream<void> get skipNextStream => _skipNextController.stream;
  Stream<void> get skipPreviousStream => _skipPreviousController.stream;

  // Custom Equalizer via MethodChannel
  static const _channel = MethodChannel('com.tunebridge/equalizer');
  bool _equalizerInitialized = false;

  TuneBridgeAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Audio Session Configuration for Music
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Ensure max volume
    await _player.setVolume(1.0);

    // Propagate playback events to audio_service clients
    _player.playbackEventStream.listen(_broadcastState);

    // Propagate processing state changes for completion logic
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
      }
    });

    // Handle audio interruptions (optional but recommended)
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(0.5);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(1.0);
            break;
          case AudioInterruptionType.pause:
            play();
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });
  }

  /// Expose easier access for internal usage if needed
  AudioPlayer get player => _player;

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
    try {
      // Assuming ID is the URL for now
      final url = mediaItem.id;
      // Revert to plain URI for muxed streams to avoid header conflicts
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      // Ensure volume is max
      await _player.setVolume(1.0);
      play();
    } catch (e) {
      _log.e('Error playing media item: ${mediaItem.title}', error: e);
    }
  }

  /// Plays from a URI with metadata.
  @override
  Future<void> playFromUri(Uri uri, [Map<String, dynamic>? extras]) async {
    try {
      if (extras != null) {
        final item = MediaItem(
          id: uri.toString(),
          album: extras['album'] ?? 'Unknown Album',
          title: extras['title'] ?? 'Unknown Title',
          artist: extras['artist'] ?? 'Unknown Artist',
          artUri: extras['artUri'] != null ? Uri.parse(extras['artUri']) : null,
          duration: extras['duration'] != null
              ? Duration(milliseconds: extras['duration'])
              : null,
        );
        mediaItem.add(item);
      }

      await _player.setAudioSource(AudioSource.uri(uri));
      await _player.setVolume(1.0);
      play();
    } catch (e) {
      _log.e('Error playing from URI: $uri', error: e);
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    if (Platform.isAndroid && _equalizerInitialized) {
      try {
        await _channel.invokeMethod('release');
        _equalizerInitialized = false;
      } catch (e) {
         _log.e('Equalizer release error', error: e);
      }
    }
    await super.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  @override
  Future<void> skipToNext() async {
    _skipNextController.add(null);
  }

  @override
  Future<void> skipToPrevious() async {
    _skipPreviousController.add(null);
  }

  // --- State Broadcasting ---

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: _mapProcessingState(_player.processingState),
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  // --- Equalizer (Moved from Service) ---

  Future<void> initEqualizer() async {
    if (!Platform.isAndroid) return;
    try {
      final sessionId = _player.androidAudioSessionId;
      if (sessionId != null) {
        await _channel.invokeMethod('init', {'sessionId': sessionId});
        
        final box = Hive.box(AppConstants.settingsBox);
        
        // Restore persistent enabled state
        final bool enabled = box.get('eq_enabled', defaultValue: true);
        await _channel.invokeMethod('enable', {'enabled': enabled});
        
        _equalizerInitialized = true;
        _log.i('Equalizer initialized: session $sessionId');

        // Restore persistent band settings
        final bands = box.get('eq_bands', defaultValue: {});
        if (bands is Map) {
          bands.forEach((key, value) {
            setBandLevel(key as int, value as int);
          });
        }
      } else {
        _log.w('Equalizer init failed: No audio session ID');
      }
    } catch (e) {
      _log.e('Equalizer init error', error: e);
    }
  }

  Future<void> setEqualizerEnabled(bool enabled) async {
    if (!Platform.isAndroid || !_equalizerInitialized) return;
    try {
      await _channel.invokeMethod('enable', {'enabled': enabled});
      final box = Hive.box(AppConstants.settingsBox);
      await box.put('eq_enabled', enabled);
    } catch (e) {
      _log.e('Failed to toggle equalizer', error: e);
    }
  }

  Future<List<int>> getBandLevelRange() async {
    if (!Platform.isAndroid || !_equalizerInitialized) return [-1500, 1500];
    try {
      final range = await _channel.invokeMethod('getBandLevelRange');
      if (range is List) {
        return range.cast<int>();
      }
      return [-1500, 1500];
    } catch (e) {
      _log.e('Failed to get band range', error: e);
      return [-1500, 1500];
    }
  }

  Future<List<int>> getCenterBandFreqs() async {
    if (!Platform.isAndroid || !_equalizerInitialized) return [];
    try {
      final freqs = await _channel.invokeMethod('getCenterBandFreqs');
      if (freqs is List) {
        return freqs.cast<int>();
      }
      return [];
    } catch (e) {
      _log.e('Failed to get center frequencies', error: e);
      return [];
    }
  }

  Future<void> setBandLevel(int bandId, int level) async {
    if (!Platform.isAndroid || !_equalizerInitialized) return;
    try {
      await _channel.invokeMethod('setBandLevel', {'bandId': bandId, 'level': level});
      final box = Hive.box(AppConstants.settingsBox);
      final bands = Map<int, int>.from(box.get('eq_bands', defaultValue: <int, int>{}));
      bands[bandId] = level;
      await box.put('eq_bands', bands);
    } catch (e) {
      _log.e('Failed to set band level', error: e);
    }
  }

  Future<int> getBandLevel(int bandId) async {
    if (!Platform.isAndroid || !_equalizerInitialized) return 0;
    try {
      final level = await _channel.invokeMethod('getBandLevel', {'bandId': bandId});
      return level as int? ?? 0;
    } catch (e) {
      _log.e('Failed to get band level', error: e);
      return 0;
    }
  }
}
