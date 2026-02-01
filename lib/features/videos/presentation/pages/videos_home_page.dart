import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:streamapp/core/di/service_locator.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_cubit.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_state.dart';
import 'package:streamapp/features/videos/presentation/managers/video_focus_manager.dart';
import 'package:streamapp/features/videos/presentation/widgets/catalog_hero_section.dart';
import 'package:streamapp/features/videos/presentation/widgets/videos_catalog_row.dart';
import 'package:streamapp/features/videos/presentation/pages/video_details_page.dart';

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        final scrollMethod = _VideosHomeContentState._currentScrollToCatalog;
        
        if (scrollMethod != null) {
          scrollMethod(0);
        } else {
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
    super.dispose();
  }

  Map<String, List<StreamSummaryModel>> _mergeCatalogs(
      Map<String, List<PlaylistInfoModel>> catalogs) {
    final Map<String, List<StreamSummaryModel>> mergedCatalogs = {};

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
      
      if (!mounted) {
        return;
      }
      
      if (catalogIndex < 0 || catalogIndex >= _catalogKeys.length) {
        return;
      }

      try {
        final key = _catalogKeys[catalogIndex];
        final BuildContext? keyContext = key.currentContext;
        
        if (keyContext == null) {
          return;
        }

        
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

      try {
        final scrollableState = Scrollable.of(context);
        if (scrollableState != null) {
          scrollableState.position.animateTo(
            0.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      } catch (e) {
        print('❌ [_VideosHomeContent] Error scrolling to top: $e');
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
      final state = context.read<VideosCubit>().state;
      if (state is VideosCatalogsLoaded) {
        final mergedCatalogs = _mergeCatalogs(state.catalogs);
        final catalogList = mergedCatalogs.entries.toList();
        
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

            if (mergedCatalogs.isEmpty) {
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
            final catalogCount = mergedCatalogs.length;
            if (_catalogKeys.length != catalogCount) {
              _catalogKeys.clear();
              for (int i = 0; i < catalogCount; i++) {
                _catalogKeys.add(GlobalKey());
              }
            }

            // Initialize focus manager
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final focusManager = context.read<VideoFocusManager>();
              final catalogSizes = mergedCatalogs.values.map((v) => v.length).toList();
              focusManager.initialize(catalogSizes);
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CatalogHeroSection(),
                const SizedBox(height: 40),

                ...mergedCatalogs.entries.toList().asMap().entries.map((entry) {
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
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
