import 'package:equatable/equatable.dart';
import 'package:tune_bridge/core/models/playlist_model.dart';

abstract class PlaylistsState extends Equatable {
  const PlaylistsState();

  @override
  List<Object?> get props => [];
}

class PlaylistsInitial extends PlaylistsState {
  const PlaylistsInitial();
}

class PlaylistsLoading extends PlaylistsState {
  const PlaylistsLoading();
}

class PlaylistsLoaded extends PlaylistsState {
  final List<PlaylistModel> playlists;
  final bool hasMore;

  const PlaylistsLoaded({required this.playlists, this.hasMore = true});

  @override
  List<Object?> get props => [playlists, hasMore];
}

class PlaylistsError extends PlaylistsState {
  final String message;

  const PlaylistsError(this.message);

  @override
  List<Object?> get props => [message];
}
