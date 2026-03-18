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

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchBloc(getIt<YouTubeService>()),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    if (mounted) setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        context.read<SearchBloc>().add(SearchQueryChanged(query.trim()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF00FF41)),
                  ),
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _controller,
                        onChanged: _onChanged,
                        onSubmitted: (value) {
                          context.read<SearchBloc>().add(SearchQueryCommitted(value));
                        },
                        textInputAction: TextInputAction.search,
                        style: GoogleFonts.inter(
                          color: GlassColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00E639)),
                          hintText: 'Artists, songs, or playlists',
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFFB9CCB2),
                            fontWeight: FontWeight.w500,
                          ),
                          suffixIcon: _controller.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _controller.clear();
                                    _onChanged('');
                                  },
                                  icon: const Icon(Icons.close_rounded, color: Color(0xFFB9CCB2)),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  if (state is SearchLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00FF41)),
                    );
                  }

                  if (state is SearchError) {
                    return _Message(text: state.message);
                  }

                  if (state is SearchLoaded) {
                    if (state.results.isEmpty) {
                      return const _Message(text: 'No results found');
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                      children: [
                        Text(
                          'Top Result',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFB9CCB2),
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _TopResultCard(track: state.results.first),
                        const SizedBox(height: 16),
                        ...List.generate(state.results.length, (index) {
                          final track = state.results[index];
                          return _SearchRow(
                            title: track.title,
                            subtitle: track.artist,
                            artUrl: track.albumArtUrl,
                            onTap: () {
                              context.read<PlayerBloc>().add(
                                    PlayerPlayTrack(
                                      track: track,
                                      queue: state.results,
                                      queueIndex: index,
                                    ),
                                  );
                              Navigator.pushNamed(context, AppRoutes.nowPlaying);
                            },
                          );
                        }),
                      ],
                    );
                  }

                  if (state is SearchInitial && state.history.isNotEmpty) {
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 140),
                      itemCount: state.history.length,
                      itemBuilder: (context, index) {
                        final item = state.history[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history_rounded, color: Color(0xFFB9CCB2)),
                          title: Text(
                            item,
                            style: GoogleFonts.inter(
                              color: GlassColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            _controller.text = item;
                            _controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: item.length),
                            );
                            _onChanged(item);
                          },
                        );
                      },
                    );
                  }

                  return const _Message(text: 'Type something to start searching');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopResultCard extends StatelessWidget {
  final dynamic track;

  const _TopResultCard({required this.track});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 82,
              height: 82,
              child: track.albumArtUrl == null
                  ? Container(
                      color: const Color(0xFF2A2A2A),
                      child: const Icon(Icons.music_note_rounded, color: GlassColors.textSecondary),
                    )
                  : Image.network(track.albumArtUrl!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFEBFFE2),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '${track.artist} • Top Song',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB9CCB2),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? artUrl;
  final VoidCallback onTap;

  const _SearchRow({
    required this.title,
    required this.subtitle,
    required this.artUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: artUrl == null
                    ? Container(
                        color: const Color(0xFF2A2A2A),
                        child: const Icon(Icons.music_note_rounded, color: GlassColors.textSecondary),
                      )
                    : Image.network(artUrl!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: GlassColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB9CCB2),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '3:42',
              style: GoogleFonts.inter(
                color: const Color(0xFFB9CCB2),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.more_vert_rounded, color: GlassColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;

  const _Message({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: const Color(0xFFB9CCB2),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
