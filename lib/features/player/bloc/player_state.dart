import 'package:equatable/equatable.dart';
import 'package:tune_bridge/core/models/track_model.dart';

class PlayerState extends Equatable {
  final TrackModel? currentTrack;
  final List<TrackModel> queue;
  final int queueIndex;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final bool shuffleEnabled;
  final bool repeatEnabled;
  final String? error;

  const PlayerState({
    this.currentTrack,
    this.queue = const [],
    this.queueIndex = 0,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.shuffleEnabled = false,
    this.repeatEnabled = false,
    this.error,
  });

  bool get hasTrack => currentTrack != null;
  bool get hasNext => queueIndex < queue.length - 1;
  bool get hasPrevious => queueIndex > 0;

  PlayerState copyWith({
    TrackModel? currentTrack,
    List<TrackModel>? queue,
    int? queueIndex,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    bool? shuffleEnabled,
    bool? repeatEnabled,
    String? error,
    bool clearError = false,
  }) {
    return PlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatEnabled: repeatEnabled ?? this.repeatEnabled,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        currentTrack,
        queue,
        queueIndex,
        isPlaying,
        isLoading,
        position,
        duration,
        shuffleEnabled,
        repeatEnabled,
        error,
      ];
}
