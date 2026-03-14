import 'package:equatable/equatable.dart';

abstract class PlaylistDetailEvent extends Equatable {
  const PlaylistDetailEvent();

  @override
  List<Object?> get props => [];
}

class PlaylistDetailRequested extends PlaylistDetailEvent {
  final String playlistId;
  const PlaylistDetailRequested(this.playlistId);

  @override
  List<Object?> get props => [playlistId];
}

class PlaylistDetailLoadMore extends PlaylistDetailEvent {
  final String playlistId;
  const PlaylistDetailLoadMore(this.playlistId);

  @override
  List<Object?> get props => [playlistId];
}
