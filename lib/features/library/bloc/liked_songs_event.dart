import 'package:equatable/equatable.dart';

abstract class LikedSongsEvent extends Equatable {
  const LikedSongsEvent();

  @override
  List<Object?> get props => [];
}

/// Load the first page of liked songs.
class LikedSongsRequested extends LikedSongsEvent {
  const LikedSongsRequested();
}

/// Load more liked songs (pagination).
class LikedSongsLoadMore extends LikedSongsEvent {
  const LikedSongsLoadMore();
}
