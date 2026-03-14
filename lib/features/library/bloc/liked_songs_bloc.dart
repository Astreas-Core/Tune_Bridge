import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/features/library/bloc/liked_songs_event.dart';
import 'package:tune_bridge/features/library/bloc/liked_songs_state.dart';

class LikedSongsBloc extends Bloc<LikedSongsEvent, LikedSongsState> {
  final LocalLibraryService _library;

  LikedSongsBloc(
    this._library,
  ) : super(const LikedSongsInitial()) {
    on<LikedSongsRequested>(_onRequested);
    on<LikedSongsLoadMore>(_onLoadMore);
  }

  Future<void> _onRequested(
    LikedSongsRequested event,
    Emitter<LikedSongsState> emit,
  ) async {
    emit(const LikedSongsLoading());

    // 1. Load local cache
    final localTracks = _library.getLikedSongs();
    if (localTracks.isEmpty) {
      emit(const LikedSongsLoaded(tracks: [], hasMore: false));
    } else {
      emit(LikedSongsLoaded(tracks: localTracks, hasMore: false));
    }
  }

  Future<void> _onLoadMore(
    LikedSongsLoadMore event,
    Emitter<LikedSongsState> emit,
  ) async {
    // No pagination for local list yet
  }
}
