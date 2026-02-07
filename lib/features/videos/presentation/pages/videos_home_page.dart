import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:streamapp/core/di/service_locator.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/data/services/recommendation_service.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_cubit.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_state.dart';
import 'package:streamapp/features/videos/presentation/managers/video_focus_manager.dart';
import 'package:streamapp/features/videos/presentation/widgets/catalog_hero_section.dart';
import 'package:streamapp/features/videos/presentation/widgets/videos_catalog_row.dart';
import 'package:streamapp/features/videos/presentation/pages/video_details_page.dart';

final Map<String, List<StreamSummaryModel>> mergedCatalogs = {};

class VideosHomePage extends StatefulWidget {
  final VoidCallback? onNavigateUp;

  const VideosHomePage({
    super.key,
    this.onNavigateUp,
  });

  @override
  State<VideosHomePage> createState() => VideosHomePageState();
}

class VideosHomePageState extends State<VideosHomePage> {
  // Method to request focus from parent
  void requestVideoFocus() {
    if (!mounted) {
      print('❌ [VideosHomePage] Widget is NOT mounted - aborting!');
      return;
    }

    // Request focus IMMEDIATELY - no postFrameCallback!
    final focusNode = _VideosHomeContentState._currentFocusNode;

    if (focusNode != null) {
      focusNode.requestFocus();

      // Schedule scroll for next frame (after layout)
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final recommendationService = sl<RecommendationService>();

        // Feed from Trending if exists (only top 3)
        final trendingVideos = mergedCatalogs['Trending']?.take(3).toList();
        if (trendingVideos != null && trendingVideos.isNotEmpty) {
          await recommendationService.feedFromCatalog(
              trendingVideos, 'Trending');
        }

        if (!mounted) return;

        final scrollMethod = _VideosHomeContentState._currentScrollToCatalog;

        if (scrollMethod != null) {
          scrollMethod(0);
        }
      });
    } else {
      print('❌ [VideosHomePage] focusNode is NULL!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider(
          create: (context) => VideosCubit(repository: sl())..loadCatalogs(),
        ),
        ChangeNotifierProvider(
          create: (context) => VideoFocusManager(),
        ),
      ],
      child: _VideosHomeContent(onNavigateUp: widget.onNavigateUp),
    );
  }
}

class _VideosHomeContent extends StatefulWidget {
  final VoidCallback? onNavigateUp;

  const _VideosHomeContent({this.onNavigateUp});

  @override
  State<_VideosHomeContent> createState() => _VideosHomeContentState();
}

class _VideosHomeContentState extends State<_VideosHomeContent> {
  final FocusNode _focusNode = FocusNode();
  final List<GlobalKey> _catalogKeys = [];
  final ScrollController _scrollController = ScrollController(); // 🆕 Added ScrollController

  // Static references for parent access
  static FocusNode? _currentFocusNode;
  static Function(int)? _currentScrollToCatalog;

  @override
  void initState() {
    super.initState();
    _currentFocusNode = _focusNode;
    _currentScrollToCatalog = _scrollToCatalog;
  }

  @override
  void dispose() {
    _currentFocusNode = null;
    _currentScrollToCatalog = null;
    _focusNode.dispose();
    _scrollController.dispose(); // 🆕 Dispose ScrollController
    super.dispose();
  }

  Map<String, List<StreamSummaryModel>> _mergeCatalogs(
      Map<String, List<PlaylistInfoModel>> catalogs) {
    for (var entry in catalogs.entries) {
      for (var playlist in entry.value) {
        final catalogName = playlist.name ?? 'Untitled';

        if (playlist.items != null && playlist.items!.items.isNotEmpty) {
          final streams = playlist.items!.items
              .where((summary) => summary.type == 'stream')
              .map((summary) => summary.data as StreamSummaryModel)
              .toList();

          if (streams.isNotEmpty) {
            if (mergedCatalogs.containsKey(catalogName)) {
              mergedCatalogs[catalogName]!.addAll(streams);
            } else {
              mergedCatalogs[catalogName] = streams;
            }
          }
        }
      }
    }

    return mergedCatalogs;
  }

  void _scrollToCatalog(int catalogIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (catalogIndex < 0 || catalogIndex >= _catalogKeys.length) return;

      try {
        final key = _catalogKeys[catalogIndex];
        final BuildContext? keyContext = key.currentContext;

        if (keyContext == null) return;

        Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.15,
        );
      } catch (e) {
        print('❌ [_VideosHomeContent] Error scrolling to catalog $catalogIndex: $e');
      }
    });
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // 🆕 Use ScrollController to scroll to top
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final focusManager = context.read<VideoFocusManager>();

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      focusManager.moveRight();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      focusManager.moveLeft();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      focusManager.moveDown();
      _scrollToCatalog(focusManager.currentCatalogIndex);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final currentIndex = focusManager.currentCatalogIndex;

      // If already at first catalog, escape to category filter
      if (currentIndex == 0) {
        _scrollToTop();
        _focusNode.unfocus();
        // Notify parent to focus category filter
        if (widget.onNavigateUp != null) {
          widget.onNavigateUp!();
        }
        return KeyEventResult.handled;
      }

      // Otherwise move up normally
      focusManager.moveUp();
      _scrollToCatalog(focusManager.currentCatalogIndex);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      // Get the final catalogs (including recommendations)
      final state = context.read<VideosCubit>().state;
      if (state is VideosCatalogsLoaded) {
        final mergedCatalogs = _mergeCatalogs(state.catalogs);

        // Get recommendations and build final catalog list
        final recommendationService = sl<RecommendationService>();
        final recommendations = recommendationService.getRecommendations();

        final Map<String, List<StreamSummaryModel>> finalCatalogs;
        if (recommendations.isNotEmpty) {
          final recommendedVideos =
              recommendations.map((r) => r.toStreamSummary()).toList();
          finalCatalogs = {
            'Recommended for You': recommendedVideos,
            ...mergedCatalogs,
          };
        } else {
          finalCatalogs = mergedCatalogs;
        }

        final catalogList = finalCatalogs.entries.toList();

        if (focusManager.currentCatalogIndex < catalogList.length) {
          final videos = catalogList[focusManager.currentCatalogIndex].value;
          if (focusManager.currentVideoIndex < videos.length) {
            final video = videos[focusManager.currentVideoIndex];
            if (video.url != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoDetailsPage(
                    videoUrl: video.url!,
                  ),
                ),
              );
            }
          }
        }
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) => _handleKeyEvent(event),
      child: BlocBuilder<VideosCubit, VideosState>(
        builder: (context, state) {
          if (state is VideosLoading) {
            return const Padding(
              padding: EdgeInsets.all(60.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state is VideosError) {
            return Padding(
              padding: const EdgeInsets.all(60.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading catalogs',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<VideosCubit>().loadCatalogs();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is VideosCatalogsLoaded) {
            final mergedCatalogs = _mergeCatalogs(state.catalogs);

            // Get recommendations and ADD to mergedCatalogs at the START
            final recommendationService = sl<RecommendationService>();
            final recommendations = recommendationService.getRecommendations();

            print('📊 [VideosHomePage] Recommendations count: ${recommendations.length}');

            final Map<String, List<StreamSummaryModel>> finalCatalogs;

            if (recommendations.isNotEmpty) {
              // Convert recommendations to StreamSummaryModel list
              final recommendedVideos =
                  recommendations.map((r) => r.toStreamSummary()).toList();

              // Create NEW map with recommendations FIRST
              finalCatalogs = {
                'Recommended for You': recommendedVideos,
                ...mergedCatalogs,
              };

              print('📊 [VideosHomePage] Final catalogs count: ${finalCatalogs.length}');
              print('📊 [VideosHomePage] Recommendations: ${recommendedVideos.length} videos');
            } else {
              // No recommendations, use regular catalogs
              finalCatalogs = mergedCatalogs;
              print('📊 [VideosHomePage] No recommendations, using ${finalCatalogs.length} catalogs');
            }

            // Use finalCatalogs for building UI
            return _buildCatalogsView(context, finalCatalogs);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // 🆕 Wrap content in SingleChildScrollView
  Widget _buildCatalogsView(
    BuildContext context,
    Map<String, List<StreamSummaryModel>> catalogs,
  ) {
    if (catalogs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(60.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'No videos available',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Check back later for new content',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color
                          ?.withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Initialize catalog keys
    final catalogCount = catalogs.length;
    if (_catalogKeys.length != catalogCount) {
      _catalogKeys.clear();
      for (int i = 0; i < catalogCount; i++) {
        _catalogKeys.add(GlobalKey());
      }
      print('🔑 [VideosHomePage] Initialized $catalogCount catalog keys');
    }

    // Initialize focus manager
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusManager = context.read<VideoFocusManager>();
      final catalogSizes = catalogs.values.map((v) => v.length).toList();
      focusManager.initialize(catalogSizes);
      print('🎮 [VideosHomePage] Focus manager initialized with ${catalogSizes.length} catalogs');
    });

    // 🔥 Wrap Column in SingleChildScrollView
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CatalogHeroSection(),
          const SizedBox(height: 40),

          // ALL CATALOGS (INCLUDING RECOMMENDATIONS IF EXISTS)
          ...catalogs.entries.toList().asMap().entries.map((entry) {
            final catalogIndex = entry.key;
            final catalogEntry = entry.value;

            return Column(
              key: _catalogKeys[catalogIndex],
              children: [
                VideosCatalogRow(
                  catalogName: catalogEntry.key,
                  videos: catalogEntry.value,
                  catalogIndex: catalogIndex,
                ),
                const SizedBox(height: 32),
              ],
            );
          }).toList(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
