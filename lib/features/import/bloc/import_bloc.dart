import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:tune_bridge/core/models/playlist_model.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/core/services/spotify_public_service.dart';
import 'package:tune_bridge/features/import/bloc/import_event.dart';
import 'package:tune_bridge/features/import/bloc/import_state.dart';

class ImportBloc extends Bloc<ImportEvent, ImportState> {
  final SpotifyPublicService _spotifyPublic;
  final LocalLibraryService _localLibrary;
  final Logger _log = Logger();

  ImportBloc(this._spotifyPublic, this._localLibrary)
      : super(const ImportInitial()) {
    on<ImportUrlSubmitted>(_onUrlSubmitted);
    on<ImportReset>(_onReset);
  }

  Future<void> _onUrlSubmitted(
    ImportUrlSubmitted event,
    Emitter<ImportState> emit,
  ) async {
    final parsed = SpotifyPublicService.parseSpotifyUrl(event.url);
    if (parsed == null) {
      emit(const ImportError(
        'Invalid URL. Paste a Spotify track, playlist, or album link.',
      ));
      return;
    }

    emit(ImportLoading(
      message: 'Fetching ${parsed.type} from Spotify...',
    ));

    try {
      final result = await _spotifyPublic.importFromUrl(event.url);

      if (event.addToLiked) {
        await _localLibrary.addLikedSongs(result.tracks);
        emit(ImportSuccess(
          name: result.name,
          tracks: result.tracks,
          addedToLiked: true,
        ));
      } else {
        // Save as a local playlist
        final playlist = PlaylistModel(
          id: '${parsed.type}_${parsed.id}',
          name: result.name,
          imageUrl: result.tracks.isNotEmpty
              ? result.tracks.first.albumArtUrl
              : null,
          trackCount: result.tracks.length,
          ownerName: 'Imported',
          folderName: event.folderName,
        );
        await _localLibrary.savePlaylist(playlist, result.tracks);
        emit(ImportSuccess(
          name: result.name,
          tracks: result.tracks,
        ));
      }
    } catch (e, st) {
      _log.e('Import error: $e\n$st');
      emit(ImportError('Import failed: $e'));
    }
  }

  void _onReset(ImportReset event, Emitter<ImportState> emit) {
    emit(const ImportInitial());
  }
}
