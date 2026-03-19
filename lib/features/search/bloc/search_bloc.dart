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
  static const _historyKey = 'search_history';

  SearchBloc(this._youtubeService) : super(const SearchInitial([])) {
    // Open box if needed, or assume open. main() opens it.
    _box = Hive.box(AppConstants.settingsBox);

    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchQueryCommitted>(_onQueryCommitted);
    on<SearchHistoryCleared>(_onHistoryCleared);

    _sanitizeAndPersistHistory();

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
      emit(SearchLoaded(results));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onQueryCommitted(
    SearchQueryCommitted event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.length < 2) return;
    _addToHistory(query);
  }

  Future<void> _onHistoryCleared(
    SearchHistoryCleared event,
    Emitter<SearchState> emit,
  ) async {
    await _box.put(_historyKey, const <String>[]);
    emit(const SearchInitial([]));
  }

  List<String> _getHistory() {
    final dynamic raw = _box.get(_historyKey, defaultValue: []);
    if (raw is List) {
      return raw.cast<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  void _addToHistory(String query) {
    if (query.length < 2) return;
    final normalized = _normalize(query);
    if (normalized.isEmpty) return;

    final List<String> history = List<String>.from(_getHistory());
    history.removeWhere((h) => _normalize(h) == normalized);
    history.insert(0, query.trim());

    final cleaned = _dedupeExactNormalized(history);
    final trimmed = cleaned.take(12).toList(growable: false);

    _box.put(_historyKey, trimmed);
  }

  void _sanitizeAndPersistHistory() {
    final current = _getHistory();
    final cleaned = _dedupeExactNormalized(current).take(12).toList(growable: false);
    _box.put(_historyKey, cleaned);
  }

  List<String> _dedupeExactNormalized(List<String> input) {
    final seen = <String>{};
    final output = <String>[];
    for (final candidate in input) {
      final normalized = _normalize(candidate);
      if (normalized.length < 2) continue;
      if (seen.contains(normalized)) continue;
      seen.add(normalized);
      output.add(candidate.trim());
    }
    return output;
  }

  String _normalize(String query) {
    return query.trim().toLowerCase();
  }
}
