import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/core/di/service_locator.dart';
import 'package:streamapp/features/videos/data/services/recommendation_service.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_cubit.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_state.dart';
import 'package:streamapp/features/videos/presentation/widgets/search_bar_widget.dart';
import 'package:streamapp/features/videos/presentation/widgets/video_grid_widget.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VideosCubit(repository: sl()),
      child: const _SearchPageContent(),
    );
  }
}

class _SearchPageContent extends StatefulWidget {
  const _SearchPageContent();

  @override
  State<_SearchPageContent> createState() => _SearchPageContentState();
}

class _SearchPageContentState extends State<_SearchPageContent> {
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final state = context.read<VideosCubit>().state;
      if (state is VideosSearchSuccess && state.hasMore) {
        context.read<VideosCubit>().loadMoreVideos();
      }
    }
  }

  // 🆕 Feed search results to recommendations
  Future<void> _feedSearchResults(List<dynamic> items) async {
    try {
      final recommendationService = sl<RecommendationService>();
      
      // Filter only stream items
      final streams = items
          .where((item) => item is SummaryModel && item.type == 'stream')
          .map((item) => (item as SummaryModel).data as StreamSummaryModel)
          .toList();

      if (streams.isNotEmpty) {
        await recommendationService.feedFromSearchResults(
          streams.take(8).toList(), // Top 8 results
        );
        print('✅ Fed ${streams.length} search results to recommendations');
      }
    } catch (e) {
      print('⚠️ Failed to feed search results: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const _BackIntent(),
      },
      child: Actions(
        actions: {
          _BackIntent: CallbackAction<_BackIntent>(
            onInvoke: (_) {
              Navigator.of(context).pop();
              return null;
            },
          ),
        },
        child: Scaffold(
          body: Column(
            children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 32),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: SearchBarWidget(focusNode: _searchFocusNode)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: BlocConsumer<VideosCubit, VideosState>(
                  listener: (context, state) {
                    // 🆕 Listen for search success and feed recommendations
                    if (state is VideosSearchSuccess) {
                      _feedSearchResults(state.allItems);
                    }
                  },
                  builder: (context, state) {
                    if (state is VideosInitial) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 80,
                              color: Theme.of(context).textTheme.bodyMedium!.color,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'search_prompt'.tr(),
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is VideosLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is VideosError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 80,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'error_occurred'.tr(),
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is VideosSearchSuccess || state is VideosLoadingMore) {
                      final items = state is VideosSearchSuccess
                          ? state.allItems
                          : (state as VideosLoadingMore).currentItems;
                      
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 60),
                            child: Row(
                              children: [
                                Text(
                                  'search_results'.tr(),
                                  style: Theme.of(context).textTheme.displayMedium,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${items.length} ${'items_found'.tr()}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: VideoGridWidget(
                              items: items,
                              scrollController: _scrollController,
                            ),
                          ),
                          if (state is VideosLoadingMore)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                        ],
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackIntent extends Intent {
  const _BackIntent();
}
