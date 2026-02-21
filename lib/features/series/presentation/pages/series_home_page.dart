import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:streamapp/core/di/service_locator.dart';
import 'package:streamapp/features/series/data/models/series_model.dart';
import 'package:streamapp/features/series/presentation/cubit/series_cubit.dart';
import 'package:streamapp/features/series/presentation/cubit/series_state.dart';
import 'package:streamapp/features/series/presentation/pages/series_details_page.dart';
import 'package:streamapp/features/series/presentation/widgets/series_catalog_row.dart';
import 'package:streamapp/features/series/presentation/widgets/series_hero_section.dart';
import 'package:streamapp/features/videos/presentation/managers/video_focus_manager.dart';

class SeriesHomePage extends StatefulWidget {
  final VoidCallback? onNavigateUp;

  const SeriesHomePage({super.key, this.onNavigateUp});

  @override
  State<SeriesHomePage> createState() => SeriesHomePageState();
}

class SeriesHomePageState extends State<SeriesHomePage> {
  void requestSeriesFocus() {
    if (!mounted) return;
    final focusNode = _SeriesHomeContentState._currentFocusNode;
    if (focusNode != null) {
      focusNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final scrollMethod = _SeriesHomeContentState._currentScrollToCatalog;
        if (scrollMethod != null) scrollMethod(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider(
          create: (_) => SeriesCubit(repository: sl())..loadCatalogs(),
        ),
        ChangeNotifierProvider(
          create: (_) => VideoFocusManager(),
        ),
      ],
      child: _SeriesHomeContent(onNavigateUp: widget.onNavigateUp),
    );
  }
}

class _SeriesHomeContent extends StatefulWidget {
  final VoidCallback? onNavigateUp;
  const _SeriesHomeContent({this.onNavigateUp});

  @override
  State<_SeriesHomeContent> createState() => _SeriesHomeContentState();
}

class _SeriesHomeContentState extends State<_SeriesHomeContent> {
  final FocusNode _focusNode = FocusNode();
  final List<GlobalKey> _catalogKeys = [];
  final ScrollController _scrollController = ScrollController();

  List<List<SeriesModel>> _catalogSeriesLists = [];

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
        final keyContext = key.currentContext;
        if (keyContext == null) return;
        Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.15,
        );
      } catch (e) {
        debugPrint('❌ [SeriesHomePage] Error scrolling to catalog $catalogIndex: $e');
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
        widget.onNavigateUp?.call();
        return KeyEventResult.handled;
      }
      focusManager.moveUp();
      _scrollToCatalog(focusManager.currentCatalogIndex);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
               event.logicalKey == LogicalKeyboardKey.select) {
      final catIdx = focusManager.currentCatalogIndex;
      final vidIdx = focusManager.currentVideoIndex;
      if (catIdx < _catalogSeriesLists.length) {
        final seriesList = _catalogSeriesLists[catIdx];
        if (vidIdx < seriesList.length) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SeriesDetailsPage(seriesId: seriesList[vidIdx].id),
            ),
          );
          return KeyEventResult.handled;
        }
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (_, event) => _handleKeyEvent(event),
      child: BlocBuilder<SeriesCubit, SeriesState>(
        builder: (context, state) {
          if (state is SeriesLoading) {
            return const Padding(
              padding: EdgeInsets.all(60.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is SeriesError) {
            return Padding(
              padding: const EdgeInsets.all(60.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Error loading series',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(state.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.read<SeriesCubit>().loadCatalogs(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is SeriesCatalogsLoaded) {
            return _buildCatalogsView(context, state.catalogs);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCatalogsView(
      BuildContext context, Map<String, List<SeriesModel>> catalogs) {
    if (catalogs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(60.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tv_outlined,
                  size: 80,
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.5)),
              const SizedBox(height: 24),
              Text('No series available',
                  style: Theme.of(context).textTheme.headlineMedium),
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
    }

    _catalogSeriesLists = catalogs.values.toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusManager = context.read<VideoFocusManager>();
      final catalogSizes = catalogs.values.map((v) => v.length).toList();
      focusManager.initialize(catalogSizes);
    });

    final heroSeries = catalogs.values.isNotEmpty
        ? catalogs.values.first.take(5).toList()
        : <SeriesModel>[];

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SeriesHeroSection(series: heroSeries),
          const SizedBox(height: 40),
          ...catalogs.entries.toList().asMap().entries.map((entry) {
            final catalogIndex = entry.key;
            final catalogEntry = entry.value;
            return Column(
              key: _catalogKeys[catalogIndex],
              children: [
                SeriesCatalogRow(
                  catalogName: catalogEntry.key,
                  series: catalogEntry.value,
                  catalogIndex: catalogIndex,
                ),
                const SizedBox(height: 32),
              ],
            );
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
