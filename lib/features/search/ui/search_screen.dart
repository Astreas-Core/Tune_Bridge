import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/neumorphic.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/youtube_service.dart';
import 'package:tune_bridge/features/player/bloc/player_bloc.dart';
import 'package:tune_bridge/features/player/bloc/player_event.dart';
import 'package:tune_bridge/features/search/bloc/search_bloc.dart';
import 'package:tune_bridge/features/search/bloc/search_event.dart';
import 'package:tune_bridge/features/search/bloc/search_state.dart';
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
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<SearchBloc>().add(SearchQueryChanged(query));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neumorphic.background,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Neumorphic.background,
        elevation: 0,
        iconTheme: IconThemeData(color: Neumorphic.textDark),
        title: Container(
          height: 48,
          margin: const EdgeInsets.only(right: 16),
          decoration: Neumorphic.inset(
            radius: 12,
            blurRadius: 6,
            offset: const Offset(3, 3),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true, 
            onChanged: _onSearchChanged,
            style: GoogleFonts.splineSans(
              color: Neumorphic.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: 'Search songs, artists...',
              hintStyle: GoogleFonts.splineSans(
                color: Neumorphic.textMedium,
                fontSize: 15,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Neumorphic.textMedium),
              contentPadding: EdgeInsets.zero,
              suffixIcon: IconButton(
                icon: Icon(Icons.clear, color: Neumorphic.textLight),
                onPressed: () {
                  _controller.clear();
                  context.read<SearchBloc>().add(const SearchQueryChanged(''));
                },
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return Center(child: CircularProgressIndicator(color: Neumorphic.accent));
          }
          if (state is SearchError) {
            return Center(child: Text(state.message, style: TextStyle(color: Neumorphic.error)));
          }
          if (state is SearchLoaded) {
            if (state.results.isEmpty) {
              return Center(child: Text('No results found', style: TextStyle(color: Neumorphic.textMedium)));
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 10, bottom: 100),
              itemCount: state.results.length,
              itemBuilder: (context, index) {
                final track = state.results[index];
                return SongTile(
                  title: track.title,
                  artist: track.artist,
                  albumArtUrl: track.albumArtUrl,
                  onTap: () {
                    context.read<PlayerBloc>().add(PlayerPlayTrack(
                      track: track,
                      queue: [track], 
                    ));
                    Navigator.pushNamed(context, AppRoutes.nowPlaying);
                  },
                );
              },
            );
          }
          // SearchInitial
          if (state is SearchInitial) {
             if (state.history.isNotEmpty) {
               return Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Text(
                      'Recent Searches',
                      style: GoogleFonts.splineSans(
                        color: Neumorphic.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                     ),
                   ),
                   Expanded(
                     child: ListView.builder(
                       itemCount: state.history.length,
                       itemBuilder: (context, index) {
                         final historyItem = state.history[index];
                         return ListTile(
                           leading: Icon(Icons.history, color: Neumorphic.textLight),
                           title: Text(
                             historyItem,
                             style: GoogleFonts.splineSans(
                               color: Neumorphic.textDark,
                               fontSize: 16,
                             ),
                           ),
                           onTap: () {
                              _controller.text = historyItem;
                              _controller.selection = TextSelection.fromPosition(TextPosition(offset: historyItem.length));
                              context.read<SearchBloc>().add(SearchQueryChanged(historyItem));
                           },
                         );
                       },
                     ),
                   ),
                 ],
               );
             }
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: Neumorphic.raised(
                    radius: 50,
                    blurRadius: 10,
                    offset: const Offset(5, 5),
                  ),
                  child: Icon(Icons.search_rounded,
                      size: 40, color: Neumorphic.textLight.withOpacity(0.5)),
                ),
                const SizedBox(height: 24),
                Text(
                  'Type to search music',
                  style: GoogleFonts.splineSans(
                    color: Neumorphic.textMedium,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
