import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tune_bridge/core/constants.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/core/services/youtube_service.dart';
import 'package:tune_bridge/core/models/track_model.dart';
import 'package:tune_bridge/features/search/bloc/search_event.dart';
import 'package:tune_bridge/features/search/bloc/search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final YouTubeService _youtubeService;
  final LocalLibraryService _library;
  late final Box _box;
  static const _historyKey = 'search_history';
  static const _maxHistory = 25;

  SearchBloc(this._youtubeService, this._library) : super(const SearchInitial([])) {
    _box = Hive.box(AppConstants.settingsBox);

    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchQueryCommitted>(_onQueryCommitted);
    on<SearchHistoryCleared>(_onHistoryCleared);
    on<SearchHistoryItemRemoved>(_onHistoryItemRemoved);

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
      final ranked = _personalizeResults(results);
      emit(SearchLoaded(ranked));
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

  Future<void> _onHistoryItemRemoved(
    SearchHistoryItemRemoved event,
    Emitter<SearchState> emit,
  ) async {
    final normalized = _normalize(event.query);
    final List<String> history = List<String>.from(_getHistory());
    history.removeWhere((h) => _normalize(h) == normalized);
    await _box.put(_historyKey, history);
    emit(SearchInitial(history));
  }

  /// Re-rank search results based on user preferences.
  List<TrackModel> _personalizeResults(List<TrackModel> results) {
    if (results.isEmpty) return results;

    // Build lightweight preference signals from local data
    final recentTracks = _library.getRecentTracks(limit: 30);
    final likedSongs = _library.getLikedSongs();

    if (recentTracks.isEmpty && likedSongs.isEmpty) return results;

    // Count artist frequency from user data
    final artistFreq = <String, int>{};
    for (final t in [...recentTracks, ...likedSongs]) {
      final key = t.artist.trim().toLowerCase();
      if (key.isEmpty || key == 'unknown') continue;
      artistFreq[key] = (artistFreq[key] ?? 0) + 1;
    }

    // Score and sort
    final scored = results.map((track) {
      var boost = 0.0;
      final artistKey = track.artist.trim().toLowerCase();

      // Boost results from preferred artists
      final freq = artistFreq[artistKey] ?? 0;
      if (freq > 0) boost += (freq.clamp(0, 10) * 0.5);

      return (track: track, boost: boost);
    }).toList();

    // Stable sort — only reorder if boost differs meaningfully
    scored.sort((a, b) => b.boost.compareTo(a.boost));

    return scored.map((e) => e.track).toList();
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
    final trimmed = cleaned.take(_maxHistory).toList(growable: false);

    _box.put(_historyKey, trimmed);
  }

  void _sanitizeAndPersistHistory() {
    final current = _getHistory();
    final cleaned = _dedupeExactNormalized(current).take(_maxHistory).toList(growable: false);
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
