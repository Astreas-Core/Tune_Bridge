import 'package:equatable/equatable.dart';
import 'package:tune_bridge/core/models/track_model.dart';

abstract class ImportState extends Equatable {
  const ImportState();

  @override
  List<Object?> get props => [];
}

class ImportInitial extends ImportState {
  const ImportInitial();
}

class ImportLoading extends ImportState {
  final String message;
  const ImportLoading({this.message = 'Fetching from Spotify...'});

  @override
  List<Object?> get props => [message];
}

class ImportSuccess extends ImportState {
  final String name;
  final List<TrackModel> tracks;
  final bool addedToLiked;

  const ImportSuccess({
    required this.name,
    required this.tracks,
    this.addedToLiked = false,
  });

  @override
  List<Object?> get props => [name, tracks, addedToLiked];
}

class ImportError extends ImportState {
  final String message;
  const ImportError(this.message);

  @override
  List<Object?> get props => [message];
}
