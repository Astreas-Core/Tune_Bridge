import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/features/library/bloc/playlist_detail_event.dart';
import 'package:tune_bridge/features/library/bloc/playlist_detail_state.dart';

class PlaylistDetailBloc
    extends Bloc<PlaylistDetailEvent, PlaylistDetailState> {
  final LocalLibraryService _library;

  PlaylistDetailBloc(
    this._library,
  ) : super(const PlaylistDetailInitial()) {
    on<PlaylistDetailRequested>(_onRequested);
    on<PlaylistDetailLoadMore>(_onLoadMore);
  }

  Future<void> _onRequested(
    PlaylistDetailRequested event,
    Emitter<PlaylistDetailState> emit,
  ) async {
    emit(const PlaylistDetailLoading());
    try {
      // 1. Local
      final localTracks = await _library.getPlaylistTracks(event.playlistId);
      if (localTracks.isEmpty) {
        // Just empty list if no tracks found
        emit(const PlaylistDetailLoaded(tracks: [], hasMore: false));
      } else {
        emit(PlaylistDetailLoaded(tracks: localTracks, hasMore: false));
      }
    } catch (e) {
      emit(PlaylistDetailError('Failed to load playlist: $e'));
    }
  }

  Future<void> _onLoadMore(
    PlaylistDetailLoadMore event,
    Emitter<PlaylistDetailState> emit,
  ) async {
    // No pagination
  }
}
