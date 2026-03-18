import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:tune_bridge/core/models/track_model.dart';
import 'package:tune_bridge/core/services/audio_player_service.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/core/services/youtube_service.dart';
import 'package:tune_bridge/features/player/bloc/player_event.dart';
import 'package:tune_bridge/features/player/bloc/player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioPlayerService _audioService;
  final YouTubeService _youtubeService;
  final LocalLibraryService _libraryService;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<ja.PlayerState>? _playerStateSub;
  StreamSubscription<void>? _skipNextSub;
  StreamSubscription<void>? _skipPrevSub;

  /// Shuffled index order when shuffle is on.
  List<int>? _shuffledIndices;

  PlayerBloc(this._audioService, this._youtubeService, this._libraryService)
      : super(const PlayerState()) {
    on<PlayerPlayTrack>(_onPlayTrack);
    on<PlayerPause>(_onPause);
    on<PlayerResume>(_onResume);
    on<PlayerSeek>(_onSeek);
    on<PlayerNext>(_onNext);
    on<PlayerPrevious>(_onPrevious);
    on<PlayerToggleShuffle>(_onToggleShuffle);
    on<PlayerToggleRepeat>(_onToggleRepeat);
    on<PlayerPositionUpdated>(_onPositionUpdated);
    on<PlayerDurationUpdated>(_onDurationUpdated);
    on<PlayerProcessingStateChanged>(_onProcessingStateChanged);
    on<PlayerCompleted>(_onCompleted);

    _listenToStreams();
  }

  void _listenToStreams() {
    _positionSub = _audioService.positionStream.listen((pos) {
      add(PlayerPositionUpdated(pos));
    });

    _durationSub = _audioService.player.durationStream.listen((dur) {
      if (dur != null) add(PlayerDurationUpdated(dur));
    });
    
    _skipNextSub = _audioService.skipNextStream.listen((_) {
      add(const PlayerNext());
    });
    
    _skipPrevSub = _audioService.skipPreviousStream.listen((_) {
      add(const PlayerPrevious());
    });

    _playerStateSub =
        _audioService.player.playerStateStream.listen((playerState) {
      final isBuffering =
          playerState.processingState == ja.ProcessingState.loading ||
              playerState.processingState == ja.ProcessingState.buffering;
      add(PlayerProcessingStateChanged(isBuffering, playerState.playing));

      if (playerState.processingState == ja.ProcessingState.completed) {
        add(const PlayerCompleted());
      }
    });
  }

  Future<void> _onPlayTrack(
    PlayerPlayTrack event,
    Emitter<PlayerState> emit,
  ) async {
    // Check if same track is selected
    if (state.currentTrack?.id == event.track.id) {
       if (!state.isPlaying) {
         await _audioService.resume();
         emit(state.copyWith(isPlaying: true));
       }
       // If already playing, do nothing (prevent restart)
       return;
    }

    // Stop previous track immediately
    await _audioService.player.stop();

    final queue =
        event.queue.isNotEmpty ? event.queue : [event.track];
    final index = event.queue.isNotEmpty ? event.queueIndex : 0;

    emit(state.copyWith(
      currentTrack: event.track,
      queue: queue,
      queueIndex: index,
      isLoading: true,
      isPlaying: false,
      position: Duration.zero,
      duration: Duration.zero,
      clearError: true,
    ));

    if (state.shuffleEnabled) {
      _generateShuffledIndices(queue.length, index);
    }

    await _loadAndPlay(event.track, emit);
  }

  Future<void> _loadAndPlay(
    TrackModel track,
    Emitter<PlayerState> emit,
  ) async {
    try {
      var resolvedTrack = track;

      // If the selected track doesn't carry localPath, try resolving an offline copy by ID.
      if ((resolvedTrack.localPath == null || resolvedTrack.localPath!.isEmpty) &&
          _libraryService.isOffline(resolvedTrack.id)) {
        final offlineVersion = _libraryService.getOfflineSongById(resolvedTrack.id);
        if (offlineVersion != null) {
          resolvedTrack = offlineVersion;
        }
      }

      // 1. Try playing from offline storage
      if (resolvedTrack.localPath != null && resolvedTrack.localPath!.isNotEmpty) {
        final file = File(resolvedTrack.localPath!);
        if (file.existsSync()) {
          try {
            await _audioService.play(
              Uri.file(resolvedTrack.localPath!).toString(),
              title: resolvedTrack.title,
              artist: resolvedTrack.artist,
              album: resolvedTrack.albumName,
              artUri: resolvedTrack.albumArtUrl,
              durationMs: resolvedTrack.durationMs,
            );
            await _audioService.initEqualizer();
            await _libraryService.addRecentTrack(resolvedTrack);
            emit(state.copyWith(isLoading: false, isPlaying: true));
            return;
          } catch (e) {
            // Fallback to online if local fails
          }
        }
      }

      String? videoId = resolvedTrack.youtubeVideoId;
      if (videoId == null) {
        videoId = await _youtubeService.searchVideo(
          title: resolvedTrack.title,
          artist: resolvedTrack.artist,
        );
        if (videoId == null) {
          emit(state.copyWith(
            isLoading: false,
            error: 'Could not find "${resolvedTrack.title}" on YouTube',
          ));
          return;
        }
      }

      // Check if track changed during search
      if (state.currentTrack?.id != resolvedTrack.id) return;

      // Try to get stream URL and play, retry once on failure
      for (var attempt = 0; attempt < 2; attempt++) {
        String? streamUrl;
        try {
           streamUrl = await _youtubeService.getStreamUrl(videoId);
        } catch (_) {}
        
        if (streamUrl == null) {
          if (attempt == 0) continue;
          emit(state.copyWith(
            isLoading: false,
            error: 'Could not get audio stream',
          ));
          return;
        }

        if (state.currentTrack?.id != resolvedTrack.id) return;

        try {
          await _audioService.play(
            streamUrl,
            title: resolvedTrack.title,
            artist: resolvedTrack.artist,
            album: resolvedTrack.albumName,
            artUri: resolvedTrack.albumArtUrl,
            durationMs: resolvedTrack.durationMs,
          );
          // Initialize equalizer once audio source is set
          await _audioService.initEqualizer();
            await _libraryService.addRecentTrack(resolvedTrack);
          emit(state.copyWith(
              isPlaying: true, isLoading: false)); 
          return; // success!
        } catch (e) {
          if (e.toString().contains('interrupted')) return;
          if (attempt == 0) {
            // First failure — retry with fresh stream URL
            continue;
          }
          rethrow;
        }
      }
    } catch (e) {
      if (e.toString().contains('interrupted')) return;
      emit(state.copyWith(
        isLoading: false,
        error: 'Playback error: $e',
      ));
    }
  }

  Future<void> _onPause(PlayerPause event, Emitter<PlayerState> emit) async {
    await _audioService.pause();
    emit(state.copyWith(isPlaying: false));
  }

  Future<void> _onResume(PlayerResume event, Emitter<PlayerState> emit) async {
    await _audioService.resume();
    emit(state.copyWith(isPlaying: true));
  }

  Future<void> _onSeek(PlayerSeek event, Emitter<PlayerState> emit) async {
    await _audioService.seek(event.position);
    emit(state.copyWith(position: event.position));
  }

  Future<void> _onNext(PlayerNext event, Emitter<PlayerState> emit) async {
    if (state.queue.isEmpty) {
      return;
    }

    int nextIndex;
    if (state.shuffleEnabled && _shuffledIndices != null) {
      final currentShufflePos =
          _shuffledIndices!.indexOf(state.queueIndex);
      if (currentShufflePos < _shuffledIndices!.length - 1) {
        nextIndex = _shuffledIndices![currentShufflePos + 1];
      } else if (state.repeatEnabled) {
        nextIndex = _shuffledIndices![0];
      } else {
        return;
      }
    } else {
      if (state.queueIndex < state.queue.length - 1) {
        nextIndex = state.queueIndex + 1;
      } else if (state.repeatEnabled) {
        nextIndex = 0;
      } else {
        return;
      }
    }

    final nextTrack = state.queue[nextIndex];
    emit(state.copyWith(
      currentTrack: nextTrack,
      queueIndex: nextIndex,
      isLoading: true,
      position: Duration.zero,
      duration: Duration.zero,
    ));
    await _loadAndPlay(nextTrack, emit);
  }

  Future<void> _onPrevious(
    PlayerPrevious event,
    Emitter<PlayerState> emit,
  ) async {
    // If more than 3 seconds in, restart current track
    if (state.position.inSeconds > 3) {
      await _audioService.seek(Duration.zero);
      emit(state.copyWith(position: Duration.zero));
      return;
    }

    if (state.queue.isEmpty) return;

    int prevIndex;
    if (state.shuffleEnabled && _shuffledIndices != null) {
      final currentShufflePos =
          _shuffledIndices!.indexOf(state.queueIndex);
      if (currentShufflePos > 0) {
        prevIndex = _shuffledIndices![currentShufflePos - 1];
      } else if (state.repeatEnabled) {
        prevIndex = _shuffledIndices!.last;
      } else {
        return;
      }
    } else {
      if (state.queueIndex > 0) {
        prevIndex = state.queueIndex - 1;
      } else if (state.repeatEnabled) {
        prevIndex = state.queue.length - 1;
      } else {
        return;
      }
    }

    final prevTrack = state.queue[prevIndex];
    emit(state.copyWith(
      currentTrack: prevTrack,
      queueIndex: prevIndex,
      isLoading: true,
      position: Duration.zero,
      duration: Duration.zero,
    ));
    await _loadAndPlay(prevTrack, emit);
  }

  void _onToggleShuffle(
    PlayerToggleShuffle event,
    Emitter<PlayerState> emit,
  ) {
    final newShuffle = !state.shuffleEnabled;
    if (newShuffle) {
      _generateShuffledIndices(state.queue.length, state.queueIndex);
    } else {
      _shuffledIndices = null;
    }
    emit(state.copyWith(shuffleEnabled: newShuffle));
  }

  void _onToggleRepeat(
    PlayerToggleRepeat event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(repeatEnabled: !state.repeatEnabled));
  }

  void _onPositionUpdated(
    PlayerPositionUpdated event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(position: event.position));
  }

  void _onDurationUpdated(
    PlayerDurationUpdated event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(duration: event.duration));
  }

  void _onProcessingStateChanged(
    PlayerProcessingStateChanged event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(
      isLoading: event.isBuffering,
      isPlaying: event.isPlaying,
    ));
  }

  Future<void> _onCompleted(
    PlayerCompleted event,
    Emitter<PlayerState> emit,
  ) async {
    // Auto-advance to next track
    add(const PlayerNext());
  }

  void _generateShuffledIndices(int length, int currentIndex) {
    final indices = List.generate(length, (i) => i);
    indices.remove(currentIndex);
    indices.shuffle(Random());
    _shuffledIndices = [currentIndex, ...indices];
  }

  @override
  Future<void> close() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    return super.close();
  }
}
