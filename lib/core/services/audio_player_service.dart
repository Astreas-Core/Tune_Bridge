import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:tune_bridge/core/services/audio_handler.dart';

/// Wraps our AudioHandler for block usage.
class AudioPlayerService {
  final Logger _log = Logger();
  final TuneBridgeAudioHandler _handler;

  AudioPlayerService(this._handler);

  AudioPlayer get player => _handler.player;

  Stream<PlayerState> get playerStateStream => _handler.player.playerStateStream;
  Stream<Duration> get positionStream => _handler.player.positionStream;
  Stream<Duration> get bufferedPositionStream =>
      _handler.player.bufferedPositionStream;
  Duration? get duration => _handler.player.duration;
  bool get isPlaying => _handler.player.playing;

  Stream<void> get skipNextStream => _handler.skipNextStream;
  Stream<void> get skipPreviousStream => _handler.skipPreviousStream;
  int get crossfadeSeconds => _handler.crossfadeDuration.inSeconds;

  Future<void> setCrossfadeSeconds(int seconds) async {
    await _handler.setCrossfadeDuration(Duration(seconds: seconds.clamp(1, 12)));
  }

  /// Play a YouTube audio stream URL or local file path with metadata.
  Future<void> play(String url, {
    String? title,
    String? artist,
    String? album,
    String? artUri,
    int? durationMs,
  }) async {
    try {
      final uri = Uri.parse(url);
      final extras = <String, dynamic>{
        if (title != null) 'title': title,
        if (artist != null) 'artist': artist,
        if (album != null) 'album': album,
        if (artUri != null) 'artUri': artUri,
        if (durationMs != null) 'duration': durationMs,
      };

      await _handler.playFromUri(uri, extras);
      _log.i('Playback started via AudioHandler: $title');
    } catch (e, st) {
      if (e.toString().contains('interrupted')) {
        _log.w('Load interrupted (track switched), ignoring');
        return;
      }
      _log.e('Play failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> pause() async => _handler.pause();
  Future<void> resume() async => _handler.play();
  Future<void> stop() async => _handler.stop();
  Future<void> seek(Duration position) async => _handler.seek(position);
  Future<void> setVolume(double volume) async => _handler.player.setVolume(volume);

  Future<void> smoothStopForTransition() async {
    if (!_handler.player.playing) {
      await _handler.stop();
      return;
    }

    final duration = _handler.crossfadeDuration;
    final totalMs = duration.inMilliseconds;
    if (totalMs <= 0) {
      await _handler.stop();
      return;
    }

    // Shorten fade-out so transition remains responsive.
    final fadeMs = (totalMs ~/ 2).clamp(120, 1200);
    const steps = 8;
    final stepDelay = Duration(milliseconds: (fadeMs ~/ steps).clamp(15, 200));

    for (var i = steps - 1; i >= 0; i--) {
      final t = i / steps;
      await _handler.player.setVolume(t);
      await Future<void>.delayed(stepDelay);
    }

    await _handler.stop();
  }

  Future<void> smoothFadeInAfterStart() async {
    final duration = _handler.crossfadeDuration;
    final totalMs = duration.inMilliseconds;
    if (totalMs <= 0) {
      await _handler.player.setVolume(1.0);
      return;
    }

    final fadeMs = (totalMs ~/ 2).clamp(120, 1200);
    const steps = 8;
    final stepDelay = Duration(milliseconds: (fadeMs ~/ steps).clamp(15, 200));

    await _handler.player.setVolume(0.0);
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      await _handler.player.setVolume(t);
      await Future<void>.delayed(stepDelay);
    }
    await _handler.player.setVolume(1.0);
  }

  Future<void> dispose() async {
    await _handler.stop();
  }

  // --- Equalizer (Delegated to Handler) ---

  Future<void> initEqualizer() async => _handler.initEqualizer();

  Future<void> setEqualizerEnabled(bool enabled) async =>
      _handler.setEqualizerEnabled(enabled);

  Future<List<int>> getBandLevelRange() async => _handler.getBandLevelRange();

  Future<List<int>> getCenterBandFreqs() async => _handler.getCenterBandFreqs();

  Future<void> setBandLevel(int bandId, int level) async =>
      _handler.setBandLevel(bandId, level);

  Future<int> getBandLevel(int bandId) async => _handler.getBandLevel(bandId);
}

