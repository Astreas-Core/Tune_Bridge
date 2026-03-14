import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/features/library/bloc/playlists_event.dart';
import 'package:tune_bridge/features/library/bloc/playlists_state.dart';

class PlaylistsBloc extends Bloc<PlaylistsEvent, PlaylistsState> {
  final LocalLibraryService _library;

  PlaylistsBloc(
    this._library,
  ) : super(const PlaylistsInitial()) {
    on<PlaylistsRequested>(_onRequested);
    on<PlaylistsLoadMore>(_onLoadMore);
  }

  Future<void> _onRequested(
    PlaylistsRequested event,
    Emitter<PlaylistsState> emit,
  ) async {
    emit(const PlaylistsLoading());
    // 1. Load local
    final localPlaylists = _library.getPlaylists();
    if (localPlaylists.isEmpty) {
      emit(const PlaylistsLoaded(playlists: [], hasMore: false));
    } else {
      emit(PlaylistsLoaded(playlists: localPlaylists, hasMore: false));
    }
  }

  Future<void> _onLoadMore(
    PlaylistsLoadMore event,
    Emitter<PlaylistsState> emit,
  ) async {
    // No pagination for local list
  }
}
