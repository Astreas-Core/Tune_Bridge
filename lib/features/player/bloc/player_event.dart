import 'package:equatable/equatable.dart';
import 'package:tune_bridge/core/models/track_model.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

/// Play a track, optionally setting the full queue context.
class PlayerPlayTrack extends PlayerEvent {
  final TrackModel track;
  final List<TrackModel> queue;
  final int queueIndex;

  const PlayerPlayTrack({
    required this.track,
    this.queue = const [],
    this.queueIndex = 0,
  });

  @override
  List<Object?> get props => [track, queue, queueIndex];
}

class PlayerPause extends PlayerEvent {
  const PlayerPause();
}

class PlayerResume extends PlayerEvent {
  const PlayerResume();
}

class PlayerSeek extends PlayerEvent {
  final Duration position;
  const PlayerSeek(this.position);

  @override
  List<Object?> get props => [position];
}

class PlayerNext extends PlayerEvent {
  const PlayerNext();
}

class PlayerPrevious extends PlayerEvent {
  const PlayerPrevious();
}

class PlayerToggleShuffle extends PlayerEvent {
  const PlayerToggleShuffle();
}

class PlayerToggleRepeat extends PlayerEvent {
  const PlayerToggleRepeat();
}

/// Internal: position update from audio stream.
class PlayerPositionUpdated extends PlayerEvent {
  final Duration position;
  const PlayerPositionUpdated(this.position);

  @override
  List<Object?> get props => [position];
}

/// Internal: duration resolved after loading.
class PlayerDurationUpdated extends PlayerEvent {
  final Duration duration;
  const PlayerDurationUpdated(this.duration);

  @override
  List<Object?> get props => [duration];
}

/// Internal: processing state update.
class PlayerProcessingStateChanged extends PlayerEvent {
  final bool isBuffering;
  final bool isPlaying;

  const PlayerProcessingStateChanged(this.isBuffering, this.isPlaying);

  @override
  List<Object?> get props => [isBuffering, isPlaying];
}

/// Internal: playback completed.
class PlayerCompleted extends PlayerEvent {
  const PlayerCompleted();
}
