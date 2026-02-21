import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:streamapp/core/di/service_locator.dart';
import 'package:streamapp/features/podcasts/persentation/widgets/podcasts_catalog_row.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_cubit.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_state.dart';
import 'package:streamapp/features/videos/presentation/managers/video_focus_manager.dart';
import 'package:streamapp/features/videos/presentation/widgets/catalog_hero_section.dart';
import 'package:streamapp/features/videos/presentation/widgets/videos_catalog_row.dart';
import 'package:streamapp/features/videos/presentation/pages/video_details_page.dart';

class PodcastsHomePage extends StatefulWidget {
  final VoidCallback? onNavigateUp;

  const PodcastsHomePage({
    super.key,
    this.onNavigateUp,
  });

  @override
  State<PodcastsHomePage> createState() => PodcastsHomePageState();
}

class PodcastsHomePageState extends State<PodcastsHomePage> {
  void requestPodcastFocus() {
    if (!mounted) {
      print('❌ [PodcastsHomePage] Widget is NOT mounted - aborting!');
      return;
    }

    final focusNode = _PodcastsHomeContentState._currentFocusNode;

    if (focusNode != null) {
      focusNode.requestFocus();

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        final scrollMethod = _PodcastsHomeContentState._currentScrollToCatalog;
        if (scrollMethod != null) {
          scrollMethod(0);
        }
      });
    } else {
      print('❌ [PodcastsHomePage] focusNode is NULL!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider(
          create: (context) => VideosCubit(repository: sl())..loadPodcastCatalogs(),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (context) => VideoFocusManager(),
        ),
      ],
      child: _PodcastsHomeContent(onNavigateUp: widget.onNavigateUp),
    );
  }
}

class _PodcastsHomeContent extends StatefulWidget {
  final VoidCallback? onNavigateUp;

  const _PodcastsHomeContent({this.onNavigateUp});

  @override
  State<_PodcastsHomeContent> createState() => _PodcastsHomeContentState();
}

class _PodcastsHomeContentState extends State<_PodcastsHomeContent> {
  final FocusNode _focusNode = FocusNode();
  final List<GlobalKey> _catalogKeys = [];
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
    super.dispose();
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
        print('❌ [_PodcastsHomeContent] Error scrolling to catalog $catalogIndex: $e');
      }
    });
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

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

      if (currentIndex == 0) {
        _scrollToTop();
        _focusNode.unfocus();
        if (widget.onNavigateUp != null) {
          widget.onNavigateUp!();
        }
        return KeyEventResult.handled;
      }

      focusManager.moveUp();
      _scrollToCatalog(focusManager.currentCatalogIndex);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      final state = context.read<VideosCubit>().state;
      if (state is VideosPodcastCatalogsLoaded) {
        final catalogList = state.catalogs.entries.toList();

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
                      'Error loading podcasts',
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
                        context.read<VideosCubit>().loadPodcastCatalogs();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is VideosPodcastCatalogsLoaded) {
            return _buildCatalogsView(context, state.catalogs);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCatalogsView(
    BuildContext context,
    Map<String, List<PlaylistSummaryModel>> catalogs,
  ) {
    if (catalogs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(60.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.podcasts_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'No podcasts available',
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

    final catalogCount = catalogs.length;
    if (_catalogKeys.length != catalogCount) {
      _catalogKeys.clear();
      for (int i = 0; i < catalogCount; i++) {
        _catalogKeys.add(GlobalKey());
      }
      print('🔑 [PodcastsHomePage] Initialized $catalogCount catalog keys');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusManager = context.read<VideoFocusManager>();
      final catalogSizes = catalogs.values.map((v) => v.length).toList();
      focusManager.initialize(catalogSizes);
      print('🎮 [PodcastsHomePage] Focus manager initialized with ${catalogSizes.length} catalogs');
    });

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Podcast Hero Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.podcasts_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Podcasts',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Discover podcasts across different topics',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Podcast Catalogs
          ...catalogs.entries.toList().asMap().entries.map((entry) {
            final catalogIndex = entry.key;
            final catalogEntry = entry.value;

            return Column(
              key: _catalogKeys[catalogIndex],
              children: [
                PodcastsCatalogRow(
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
