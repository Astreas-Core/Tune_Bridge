import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/youtube_service.dart';
import 'package:tune_bridge/features/player/bloc/player_bloc.dart';
import 'package:tune_bridge/features/player/bloc/player_event.dart';
import 'package:tune_bridge/features/search/bloc/search_bloc.dart';
import 'package:tune_bridge/features/search/bloc/search_event.dart';
import 'package:tune_bridge/features/search/bloc/search_state.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';
import 'package:tune_bridge/ui/widgets/song_tile.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchBloc(getIt<YouTubeService>()),
      child: const _SearchContent(),
    );
  }
}

class _SearchContent extends StatefulWidget {
  const _SearchContent();

  @override
  State<_SearchContent> createState() => _SearchContentState();
}

class _SearchContentState extends State<_SearchContent> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (mounted) setState(() {});
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 260), () {
      if (mounted) {
        context.read<SearchBloc>().add(SearchQueryChanged(query.trim()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: GlassColors.textPrimary),
                  ),
                  Expanded(
                    child: GlassPanel(
                      borderRadius: BorderRadius.circular(16),
                      blur: 8,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        onChanged: _onSearchChanged,
                        style: GoogleFonts.splineSans(
                          color: GlassColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search songs, artists, albums',
                          hintStyle: GoogleFonts.splineSans(
                            color: GlassColors.textSecondary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search_rounded, color: GlassColors.textSecondary),
                          suffixIcon: _controller.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: GlassColors.textSecondary),
                                  onPressed: () {
                                    setState(() {
                                      _controller.clear();
                                    });
                                    context.read<SearchBloc>().add(const SearchQueryChanged(''));
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return const Center(
              child: CircularProgressIndicator(color: GlassColors.accent),
            );
          }
          if (state is SearchError) {
            return _MessageView(text: state.message);
          }
          if (state is SearchLoaded) {
            if (state.results.isEmpty) {
              return const _MessageView(text: 'No results found');
            }
            return ListView.builder(
              key: const ValueKey('search-loaded'),
              padding: const EdgeInsets.only(top: 6, bottom: 120),
              itemCount: state.results.length,
              itemBuilder: (context, index) {
                final track = state.results[index];
                return SongTile(
                  title: track.title,
                  artist: track.artist,
                  albumArtUrl: track.albumArtUrl,
                  heroTag: 'art-${track.id}',
                  onTap: () {
                    context.read<PlayerBloc>().add(PlayerPlayTrack(
                      track: track,
                      queue: state.results,
                      queueIndex: index,
                    ));
                    Navigator.pushNamed(context, AppRoutes.nowPlaying);
                  },
                );
              },
            );
          }
          if (state is SearchInitial) {
            if (state.history.isNotEmpty) {
              return ListView.builder(
                key: const ValueKey('search-history'),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: state.history.length,
                itemBuilder: (context, index) {
                  final historyItem = state.history[index];
                  return ListTile(
                    leading: const Icon(Icons.history_rounded, color: GlassColors.textSecondary),
                    title: Text(
                      historyItem,
                      style: GoogleFonts.splineSans(
                        color: GlassColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.north_west_rounded, size: 16, color: GlassColors.textSecondary),
                    onTap: () {
                      _controller.text = historyItem;
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: historyItem.length),
                      );
                      context.read<SearchBloc>().add(SearchQueryChanged(historyItem));
                    },
                  );
                },
              );
            }
          }
          return const _MessageView(text: 'Type to search music');
        },
      )),
          ],
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final String text;

  const _MessageView({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 220),
        child: Text(
          text,
          style: GoogleFonts.splineSans(
            color: GlassColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
