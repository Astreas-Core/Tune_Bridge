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

