import 'package:equatable/equatable.dart';
import 'package:tune_bridge/core/models/track_model.dart';

abstract class LikedSongsState extends Equatable {
  const LikedSongsState();

  @override
  List<Object?> get props => [];
}

class LikedSongsInitial extends LikedSongsState {
  const LikedSongsInitial();
}

class LikedSongsLoading extends LikedSongsState {
  const LikedSongsLoading();
}

class LikedSongsLoaded extends LikedSongsState {
  final List<TrackModel> tracks;
  final bool hasMore;

  const LikedSongsLoaded({required this.tracks, this.hasMore = true});

  @override
  List<Object?> get props => [tracks, hasMore];
}

class LikedSongsError extends LikedSongsState {
  final String message;

  const LikedSongsError(this.message);

  @override
  List<Object?> get props => [message];
}
