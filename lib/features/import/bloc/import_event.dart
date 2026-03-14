import 'package:equatable/equatable.dart';

abstract class ImportEvent extends Equatable {
  const ImportEvent();

  @override
  List<Object?> get props => [];
}

/// User submitted a Spotify URL to import.
class ImportUrlSubmitted extends ImportEvent {
  final String url;
  /// If true, add tracks to liked songs instead of creating a playlist.
  final bool addToLiked;
  /// Optional folder name to group playlist under.
  final String? folderName;

  const ImportUrlSubmitted({
    required this.url,
    this.addToLiked = false,
    this.folderName,
  });

  @override
  List<Object?> get props => [url, addToLiked, folderName];
}

/// Reset import state.
class ImportReset extends ImportEvent {
  const ImportReset();
}
