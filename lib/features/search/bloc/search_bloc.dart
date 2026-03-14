import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tune_bridge/core/constants.dart';
import 'package:tune_bridge/core/services/youtube_service.dart';
import 'package:tune_bridge/features/search/bloc/search_event.dart';
import 'package:tune_bridge/features/search/bloc/search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final YouTubeService _youtubeService;
  late final Box _box;

  SearchBloc(this._youtubeService) : super(const SearchInitial(const [])) {
    // Open box if needed, or assume open. main() opens it.
    _box = Hive.box(AppConstants.settingsBox);
    
    on<SearchQueryChanged>(_onQueryChanged);
    
    // Initial load
    add(const SearchQueryChanged(''));
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    
    if (query.isEmpty) {
      final history = _getHistory();
      emit(SearchInitial(history));
      return;
    }

    emit(const SearchLoading());

    try {
      final results = await _youtubeService.search(query);
      if (results.isNotEmpty) {
        _addToHistory(query);
      }
      emit(SearchLoaded(results));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  List<String> _getHistory() {
    final dynamic raw = _box.get('search_history', defaultValue: []);
    if (raw is List) {
      return raw.cast<String>().toList();
    }
    return [];
  }

  void _addToHistory(String query) {
    if (query.length < 2) return;
    final List<String> history = List<String>.from(_getHistory());
    history.remove(query); // Remove existing to move to top
    history.insert(0, query); // Add to top
    if (history.length > 10) {
      history.removeLast(); // Keep max 10
    }
    _box.put('search_history', history);
  }
}
