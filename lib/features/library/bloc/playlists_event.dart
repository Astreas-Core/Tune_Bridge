import 'package:equatable/equatable.dart';

abstract class PlaylistsEvent extends Equatable {
  const PlaylistsEvent();

  @override
  List<Object?> get props => [];
}

/// Load the user's playlists.
class PlaylistsRequested extends PlaylistsEvent {
  const PlaylistsRequested();
}

/// Load more playlists (pagination).
class PlaylistsLoadMore extends PlaylistsEvent {
  const PlaylistsLoadMore();
}
