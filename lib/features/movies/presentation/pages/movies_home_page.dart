import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:streamapp/core/di/service_locator.dart';
import 'package:streamapp/features/movies/data/models/movie_model.dart';
import 'package:streamapp/features/movies/presentation/cubit/movies_cubit.dart';
import 'package:streamapp/features/movies/presentation/cubit/movies_state.dart';
import 'package:streamapp/features/movies/presentation/pages/movie_details_page.dart';
import 'package:streamapp/features/movies/presentation/widgets/movies_catalog_row.dart';
import 'package:streamapp/features/movies/presentation/widgets/movies_hero_section.dart';
import 'package:streamapp/features/videos/presentation/managers/video_focus_manager.dart';

class MoviesHomePage extends StatefulWidget {
  final VoidCallback? onNavigateUp;

  const MoviesHomePage({super.key, this.onNavigateUp});

  @override
  State<MoviesHomePage> createState() => MoviesHomePageState();
}

class MoviesHomePageState extends State<MoviesHomePage> {
  void requestMovieFocus() {
    if (!mounted) return;

    final focusNode = _MoviesHomeContentState._currentFocusNode;
    if (focusNode != null) {
      focusNode.requestFocus();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final scrollMethod = _MoviesHomeContentState._currentScrollToCatalog;
        if (scrollMethod != null) {
          scrollMethod(0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              MoviesCubit(repository: sl())..loadCatalogs(),
        ),
        ChangeNotifierProvider(
          create: (context) => VideoFocusManager(),
        ),
      ],
      child: _MoviesHomeContent(onNavigateUp: widget.onNavigateUp),
    );
  }
}

class _MoviesHomeContent extends StatefulWidget {
  final VoidCallback? onNavigateUp;

  const _MoviesHomeContent({this.onNavigateUp});

  @override
  State<_MoviesHomeContent> createState() => _MoviesHomeContentState();
}

class _MoviesHomeContentState extends State<_MoviesHomeContent> {
  final FocusNode _focusNode = FocusNode();
  final List<GlobalKey> _catalogKeys = [];
  final ScrollController _scrollController = ScrollController();

  // Cache catalogs list for Enter-key lookup
  List<List<MovieModel>> _catalogMovieLists = [];

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
        print('❌ [MoviesHomePage] Error scrolling to catalog $catalogIndex: $e');
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
               event.logicalKey == LogicalKeyboardKey.select) {
      // Navigate to MovieDetailsPage for the currently focused movie
      final catIdx = focusManager.currentCatalogIndex;
      final vidIdx = focusManager.currentVideoIndex;
      if (catIdx < _catalogMovieLists.length) {
        final movies = _catalogMovieLists[catIdx];
        if (vidIdx < movies.length) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MovieDetailsPage(movieId: movies[vidIdx].id),
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
      onKeyEvent: (node, event) => _handleKeyEvent(event),
      child: BlocBuilder<MoviesCubit, MoviesState>(
        builder: (context, state) {
          if (state is MoviesLoading) {
            return const Padding(
              padding: EdgeInsets.all(60.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is MoviesError) {
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
                      'Error loading movies',
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
                        context.read<MoviesCubit>().loadCatalogs();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is MoviesCatalogsLoaded) {
            return _buildCatalogsView(context, state.catalogs);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCatalogsView(
    BuildContext context,
    Map<String, List<MovieModel>> catalogs,
  ) {
    if (catalogs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(60.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.movie_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'No movies available',
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
    }

    // Cache the movie lists for Enter-key navigation
    _catalogMovieLists = catalogs.values.toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusManager = context.read<VideoFocusManager>();
      final catalogSizes = catalogs.values.map((v) => v.length).toList();
      focusManager.initialize(catalogSizes);
    });

    // Get hero movies from the first catalog (Trending)
    final heroMovies = catalogs.values.isNotEmpty
        ? catalogs.values.first.take(5).toList()
        : <MovieModel>[];

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MoviesHeroSection(movies: heroMovies),
          const SizedBox(height: 40),

          ...catalogs.entries.toList().asMap().entries.map((entry) {
            final catalogIndex = entry.key;
            final catalogEntry = entry.value;

            return Column(
              key: _catalogKeys[catalogIndex],
              children: [
                MoviesCatalogRow(
                  catalogName: catalogEntry.key,
                  movies: catalogEntry.value,
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
