import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streamapp/features/movies/data/models/movie_model.dart';
import 'package:streamapp/features/movies/presentation/pages/movie_details_page.dart';
import 'package:streamapp/features/movies/presentation/widgets/movie_card_widget.dart';
import 'package:streamapp/features/videos/presentation/managers/video_focus_manager.dart';

class MoviesCatalogRow extends StatefulWidget {
  final String catalogName;
  final List<MovieModel> movies;
  final int catalogIndex;

  const MoviesCatalogRow({
    super.key,
    required this.catalogName,
    required this.movies,
    required this.catalogIndex,
  });

  @override
  State<MoviesCatalogRow> createState() => _MoviesCatalogRowState();
}

class _MoviesCatalogRowState extends State<MoviesCatalogRow> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    final double itemWidth = 216.0; // 200 width + 16 margin
    final double targetScroll = index * itemWidth - 100;

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) return const SizedBox.shrink();

    return Consumer<VideoFocusManager>(
      builder: (context, focusManager, child) {
        if (focusManager.isCatalogFocused(widget.catalogIndex)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToIndex(focusManager.currentVideoIndex);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Catalog Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Icon(
                    Icons.movie_rounded,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.catalogName,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Movie List
            SizedBox(
              height: 340,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.movies.length,
                  itemBuilder: (context, index) {
                    final movie = widget.movies[index];
                    final isFocused =
                        focusManager.isFocused(widget.catalogIndex, index);

                    return MovieCardWidget(
                      movie: movie,
                      isFocused: isFocused,
                      onTap: () {
                        focusManager.selectVideo(widget.catalogIndex, index);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MovieDetailsPage(movieId: movie.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
