import 'package:equatable/equatable.dart';
import 'package:tune_bridge/core/models/track_model.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  final List<String> history;
  const SearchInitial([this.history = const []]);

  @override
  List<Object?> get props => [history];
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchLoaded extends SearchState {
  final List<TrackModel> results;

  const SearchLoaded(this.results);

  @override
  List<Object?> get props => [results];
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}
