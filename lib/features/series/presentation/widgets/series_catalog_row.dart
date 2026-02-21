import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streamapp/features/series/data/models/series_model.dart';
import 'package:streamapp/features/series/presentation/pages/series_details_page.dart';
import 'package:streamapp/features/series/presentation/widgets/series_card_widget.dart';
import 'package:streamapp/features/videos/presentation/managers/video_focus_manager.dart';

class SeriesCatalogRow extends StatefulWidget {
  final String catalogName;
  final List<SeriesModel> series;
  final int catalogIndex;

  const SeriesCatalogRow({
    super.key,
    required this.catalogName,
    required this.series,
    required this.catalogIndex,
  });

  @override
  State<SeriesCatalogRow> createState() => _SeriesCatalogRowState();
}

class _SeriesCatalogRowState extends State<SeriesCatalogRow> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    const double itemWidth = 216.0;
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
    if (widget.series.isEmpty) return const SizedBox.shrink();

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
                    Icons.tv_rounded,
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

            // Series List
            SizedBox(
              height: 340,
              child: ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.series.length,
                  itemBuilder: (context, index) {
                    final s = widget.series[index];
                    final isFocused =
                        focusManager.isFocused(widget.catalogIndex, index);

                    return SeriesCardWidget(
                      series: s,
                      isFocused: isFocused,
                      onTap: () {
                        focusManager.selectVideo(widget.catalogIndex, index);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SeriesDetailsPage(seriesId: s.id),
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
