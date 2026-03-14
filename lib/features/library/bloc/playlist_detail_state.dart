import 'package:equatable/equatable.dart';
import 'package:tune_bridge/core/models/track_model.dart';

abstract class PlaylistDetailState extends Equatable {
  const PlaylistDetailState();

  @override
  List<Object?> get props => [];
}

class PlaylistDetailInitial extends PlaylistDetailState {
  const PlaylistDetailInitial();
}

class PlaylistDetailLoading extends PlaylistDetailState {
  const PlaylistDetailLoading();
}

class PlaylistDetailLoaded extends PlaylistDetailState {
  final List<TrackModel> tracks;
  final bool hasMore;

  const PlaylistDetailLoaded({required this.tracks, this.hasMore = true});

  @override
  List<Object?> get props => [tracks, hasMore];
}

class PlaylistDetailError extends PlaylistDetailState {
  final String message;

  const PlaylistDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
