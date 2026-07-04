import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/core/di/service_locator.dart';
import 'package:streamapp/core/services/content_filter_service.dart';
import 'package:streamapp/features/series/data/models/series_model.dart';
import 'package:streamapp/features/series/data/repositories/series_repository_impl.dart';
import 'package:streamapp/features/series/presentation/cubit/series_cubit.dart';
import 'package:streamapp/features/series/presentation/cubit/series_state.dart';
import 'package:streamapp/features/series/presentation/pages/series_details_page.dart';
import 'package:streamapp/features/series/presentation/widgets/series_grid_widget.dart';

class SeriesSearchPage extends StatelessWidget {
  final String? initialQuery;
  const SeriesSearchPage({super.key, this.initialQuery});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SeriesCubit(repository: sl()),
      child: _SeriesSearchContent(initialQuery: initialQuery),
    );
  }
}

class _SeriesSearchContent extends StatefulWidget {
  final String? initialQuery;
  const _SeriesSearchContent({this.initialQuery});

  @override
  State<_SeriesSearchContent> createState() => _SeriesSearchContentState();
}

class _SeriesSearchContentState extends State<_SeriesSearchContent> {
  // ── Focus nodes ──
  final FocusNode _backButtonFocusNode   = FocusNode();
  final FocusNode _searchFocusNode       = FocusNode();
  final FocusNode _textFieldFocusNode    = FocusNode();
  final FocusNode _filterToggleFocusNode = FocusNode();
  final FocusNode _searchButtonFocusNode = FocusNode();
  final FocusNode _gridFocusNode         = FocusNode();

  final ScrollController      _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // 0=back  1=searchField  2=filterToggle  3=searchBtn
  int _topBarIndex = 1;

  // ── Filter / Sort state ──
  List<SeriesGenreModel> _genres           = [];
  SeriesGenreModel?      _selectedGenre    = null;
  String                 _selectedSort     = 'popularity.desc';
  int?                   _selectedYear     = null;
  double?                _selectedMinRating = null;
  bool                   _showFilters      = false;
  bool                   _isFilterMode     = false;

  static const _sortOptions = <String, String>{
    'popularity.desc':        'Most Popular',
    'vote_average.desc':      'Highest Rated',
    'first_air_date.desc':    'Newest First',
    'first_air_date.asc':     'Oldest First',
    'original_name.asc':      'Title A–Z',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
    _loadGenres();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textFieldFocusNode.requestFocus();
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        _performSearch();
      }
    });
  }

  @override
  void dispose() {
    _backButtonFocusNode.dispose();
    _searchFocusNode.dispose();
    _textFieldFocusNode.dispose();
    _filterToggleFocusNode.dispose();
    _searchButtonFocusNode.dispose();
    _gridFocusNode.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Load genres ──
  Future<void> _loadGenres() async {
    try {
      final genres = await sl<SeriesRepository>().getGenres();
      if (mounted) setState(() => _genres = genres);
    } catch (_) {}
  }

  // ── Infinite scroll ──
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent * 0.8) return;
    final cubit = context.read<SeriesCubit>();
    final state = cubit.state;
    if (state is SeriesSearchSuccess && state.hasMore) {
      _isFilterMode
          ? cubit.loadMoreDiscoverResults()
          : cubit.loadMoreSearchResults();
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final filterService = sl<ContentFilterService>();
    final isBlocked = await filterService.isHarmful(query);
    if (!mounted) return;

    if (isBlocked) {
      filterService.showBlockedDialog(context);
      return;
    }

    setState(() => _isFilterMode = false);
    context.read<SeriesCubit>().searchSeries(query);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _gridFocusNode.requestFocus());
  }

  void _applyFilters() {
    setState(() => _isFilterMode = true);
    context.read<SeriesCubit>().discoverSeries(
      sortBy:    _selectedSort,
      genreId:   _selectedGenre?.id,
      year:      _selectedYear,
      minRating: _selectedMinRating,
    );
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _gridFocusNode.requestFocus());
  }

  void _clearFilters() {
    setState(() {
      _selectedGenre     = null;
      _selectedSort      = 'popularity.desc';
      _selectedYear      = null;
      _selectedMinRating = null;
    });
  }

  // ── Focus helpers ──
  void _focusTopBarItem(int index) {
    setState(() => _topBarIndex = index);
    switch (index) {
      case 0: _backButtonFocusNode.requestFocus();   break;
      case 1: _textFieldFocusNode.requestFocus();    break;
      case 2: _filterToggleFocusNode.requestFocus(); break;
      case 3: _searchButtonFocusNode.requestFocus(); break;
    }
  }

  void _returnToTopBar() => _focusTopBarItem(1);

  // ── Keyboard handler ──
  KeyEventResult _handleTopBar(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (_gridFocusNode.hasFocus) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _returnToTopBar();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (_topBarIndex == 1) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _focusTopBarItem(0); return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _focusTopBarItem(2); return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        final s = context.read<SeriesCubit>().state;
        if (s is SeriesSearchSuccess || s is SeriesLoadingMore) {
          _gridFocusNode.requestFocus(); return KeyEventResult.handled;
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _focusTopBarItem(0); return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_topBarIndex > 0) { _focusTopBarItem(_topBarIndex - 1); return KeyEventResult.handled; }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_topBarIndex < 3) { _focusTopBarItem(_topBarIndex + 1); return KeyEventResult.handled; }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final s = context.read<SeriesCubit>().state;
      if (s is SeriesSearchSuccess || s is SeriesLoadingMore) {
        _gridFocusNode.requestFocus(); return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop(); return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
               event.logicalKey == LogicalKeyboardKey.space) {
      switch (_topBarIndex) {
        case 0: Navigator.of(context).pop(); break;
        case 2: setState(() => _showFilters = !_showFilters); break;
        case 3: _performSearch(); break;
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const _BackIntent(),
      },
      child: Actions(
        actions: {
          _BackIntent: CallbackAction<_BackIntent>(
            onInvoke: (_) { Navigator.of(context).pop(); return null; },
          ),
        },
        child: Scaffold(
          body: Column(
            children: [
              const SizedBox(height: 40),

              // ── Top Bar ──
              Focus(
                onKeyEvent: (_, event) => _handleTopBar(event),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Row(children: [

                    // Back
                    _TopBarButton(
                      focusNode: _backButtonFocusNode,
                      isFocused: _topBarIndex == 0,
                      onFocusChange: (f) { if (f) setState(() => _topBarIndex = 0); },
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, size: 32),
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Search field
                    Expanded(
                      child: _TopBarButton(
                        focusNode: _searchFocusNode,
                        isFocused: _topBarIndex == 1,
                        onFocusChange: (f) {
                          if (f) {
                            setState(() => _topBarIndex = 1);
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => _textFieldFocusNode.requestFocus(),
                            );
                          }
                        },
                        child: TextField(
                          controller: _searchController,
                          focusNode: _textFieldFocusNode,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Search series...',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: Theme.of(context).textTheme.bodyMedium!.color,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                          onSubmitted: (_) => _performSearch(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Filter toggle
                    _TopBarButton(
                      focusNode: _filterToggleFocusNode,
                      isFocused: _topBarIndex == 2,
                      onFocusChange: (f) { if (f) setState(() => _topBarIndex = 2); },
                      child: IconButton(
                        onPressed: () => setState(() => _showFilters = !_showFilters),
                        icon: Icon(
                          _showFilters
                              ? Icons.filter_list_off_rounded
                              : Icons.filter_list_rounded,
                          size: 28,
                        ),
                        tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
                        style: IconButton.styleFrom(
                          backgroundColor: _showFilters
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surface,
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Search button
                    _TopBarButton(
                      focusNode: _searchButtonFocusNode,
                      isFocused: _topBarIndex == 3,
                      onFocusChange: (f) { if (f) setState(() => _topBarIndex = 3); },
                      child: ElevatedButton.icon(
                        onPressed: _performSearch,
                        icon: const Icon(Icons.search_rounded),
                        label: Text('search'.tr()),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 18),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),

              // ── Filter Panel ──
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 280),
                crossFadeState: _showFilters
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild:  _buildFilterPanel(context),
                secondChild: const SizedBox(height: 0),
              ),

              const SizedBox(height: 16),

              // ── Results ──
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Results area ──
  Widget _buildResults() {
    return BlocBuilder<SeriesCubit, SeriesState>(
      builder: (context, state) {
        if (state is SeriesInitial)  return _buildEmptyPrompt();
        if (state is SeriesLoading)  return const Center(child: CircularProgressIndicator());
        if (state is SeriesError)    return _buildError(state.message);

        if (state is SeriesSearchSuccess || state is SeriesLoadingMore) {
          final series = state is SeriesSearchSuccess
              ? state.series
              : (state as SeriesLoadingMore).currentSeries;

          if (series.isEmpty) return _buildNoResults();

          final total = state is SeriesSearchSuccess
              ? state.totalResults
              : series.length;

          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Row(children: [
                Text(
                  'search_results'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Text('$total series',
                    style: Theme.of(context).textTheme.bodyMedium),
                if (_isFilterMode) ...[
                  const Spacer(),
                  _buildActiveChips(),
                ],
              ]),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: SeriesGridWidget(
                series: series,
                scrollController: _scrollController,
                gridFocusNode: _gridFocusNode,
                onEscapePressed: _returnToTopBar,
                onSeriesTap: (s) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeriesDetailsPage(seriesId: s.id),
                  ),
                ),
              ),
            ),

            if (state is SeriesLoadingMore)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
          ]);
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ── Filter panel ──
  Widget _buildFilterPanel(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(50, (i) => currentYear - i);

    return Container(
      margin: const EdgeInsets.fromLTRB(60, 16, 60, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters & Sort',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _dropdown<String>(context,
                  label: 'Sort By',
                  value: _selectedSort,
                  items: _sortOptions.entries
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedSort = v ?? 'popularity.desc'),
                  width: 210),

              _dropdown<SeriesGenreModel?>(context,
                  label: 'Genre',
                  value: _selectedGenre,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Genres')),
                    ..._genres.map((g) =>
                        DropdownMenuItem(value: g, child: Text(g.name))),
                  ],
                  onChanged: (v) => setState(() => _selectedGenre = v),
                  width: 190),

              _dropdown<int?>(context,
                  label: 'Year',
                  value: _selectedYear,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Any Year')),
                    ...years.map((y) =>
                        DropdownMenuItem(value: y, child: Text(y.toString()))),
                  ],
                  onChanged: (v) => setState(() => _selectedYear = v),
                  width: 140),

              _dropdown<double?>(context,
                  label: 'Min Rating',
                  value: _selectedMinRating,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any')),
                    ...List.generate(9, (i) => (i + 1).toDouble())
                        .reversed
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        size: 14, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text('${r.toInt()}+'),
                                  ]),
                            )),
                  ],
                  onChanged: (v) => setState(() => _selectedMinRating = v),
                  width: 130),

              ElevatedButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Apply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),

              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>(
    BuildContext context, {
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    double width = 160,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withOpacity(0.6)),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.3))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.3))),
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            style: Theme.of(context).textTheme.bodyMedium,
            dropdownColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChips() {
    return Wrap(spacing: 8, children: [
      if (_selectedGenre != null)
        Chip(
          label: Text(_selectedGenre!.name),
          deleteIcon: const Icon(Icons.close_rounded, size: 16),
          onDeleted: () {
            setState(() => _selectedGenre = null);
            _applyFilters();
          },
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          side: BorderSide.none,
        ),
      if (_selectedYear != null)
        Chip(
          label: Text(_selectedYear.toString()),
          deleteIcon: const Icon(Icons.close_rounded, size: 16),
          onDeleted: () {
            setState(() => _selectedYear = null);
            _applyFilters();
          },
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          side: BorderSide.none,
        ),
      if (_selectedMinRating != null)
        Chip(
          label: Text('★ ${_selectedMinRating!.toInt()}+'),
          deleteIcon: const Icon(Icons.close_rounded, size: 16),
          onDeleted: () {
            setState(() => _selectedMinRating = null);
            _applyFilters();
          },
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          side: BorderSide.none,
        ),
    ]);
  }

  // ── Empty states ──
  Widget _buildEmptyPrompt() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.tv_rounded,
            size: 80,
            color: Theme.of(context).textTheme.bodyMedium!.color),
        const SizedBox(height: 16),
        Text('Search for series or use filters',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Use the search bar above or tap the filter icon to browse by genre, year, and more',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.tv_off_rounded,
            size: 80,
            color: Theme.of(context).textTheme.bodyMedium!.color),
        const SizedBox(height: 16),
        Text('No series found',
            style: Theme.of(context).textTheme.titleLarge),
      ]),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline_rounded,
            size: 80, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 16),
        Text('error_occurred'.tr(),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── Reusable focused top-bar wrapper ──
class _TopBarButton extends StatelessWidget {
  final FocusNode focusNode;
  final bool isFocused;
  final ValueChanged<bool> onFocusChange;
  final Widget child;

  const _TopBarButton({
    required this.focusNode,
    required this.isFocused,
    required this.onFocusChange,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onFocusChange: onFocusChange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isFocused
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 3)
              : null,
        ),
        child: child,
      ),
    );
  }
}

class _BackIntent extends Intent {
  const _BackIntent();
}
