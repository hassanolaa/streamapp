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
  final FocusNode _backButtonFocusNode = FocusNode();
  final FocusNode _filtersButtonFocusNode = FocusNode();
  final FocusNode _searchButtonFocusNode = FocusNode();
  final FocusNode _gridFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  int _topBarFocusedIndex = 1;

  List<String> _selectedFilters = [];
  String? _selectedSort;

  final List<String> _availableFilters = [
    'all',
    'videos',
    'channels',
    'playlists',
  ];

  final List<String> _availableSortOptions = [
    'relevance',
    'upload_date',
    'view_count',
    'rating',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _backButtonFocusNode.dispose();
    _filtersButtonFocusNode.dispose();
    _searchButtonFocusNode.dispose();
    _gridFocusNode.dispose();
    _scrollController.dispose();
    _searchController.dispose();
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

  Future<void> _feedSearchResults(List<dynamic> items) async {
    try {
      final recommendationService = sl<RecommendationService>();

      final streams = items
          .where((item) => item is SummaryModel && item.type == 'stream')
          .map((item) => (item as SummaryModel).data as StreamSummaryModel)
          .toList();

      if (streams.isNotEmpty) {
        await recommendationService.feedFromSearchResults(
          streams.take(8).toList(),
        );
        print('✅ Fed ${streams.length} search results to recommendations');
      }
    } catch (e) {
      print('⚠️ Failed to feed search results: $e');
    }
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    print('🔍 Performing search: "$query"');
    print('📋 Filters: $_selectedFilters');
    print('🔢 Sort: $_selectedSort');
    
    if (query.isNotEmpty) {
      context.read<VideosCubit>().searchVideos(
            query,
            filters: _selectedFilters.isNotEmpty ? _selectedFilters : null,
            sortCriteria: _selectedSort,
          );

      // Focus grid after search
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _gridFocusNode.requestFocus();
      });
    }
  }

  void _showFiltersDialog() {
  print('🎛️ Opening filters dialog');

  // Local state for dialog
  List<String> tempSelectedFilters = List.from(_selectedFilters);
  String? tempSelectedSort = _selectedSort;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder( // 🆕 StatefulBuilder
      builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Search Filters',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Filters Section
                  Row(
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Content Type',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      if (tempSelectedFilters.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              tempSelectedFilters.clear();
                            });
                          },
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          label: const Text('Clear'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableFilters.map((filter) {
                      final isSelected = tempSelectedFilters.contains(filter);
                      
                      return Focus(
                        child: Builder(
                          builder: (context) {
                            final isFocused = Focus.of(context).hasFocus;
                            
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: isFocused
                                    ? Border.all(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: FilterChip(
                                label: Text(
                                  filter.replaceAll('_', ' ').toUpperCase(),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setDialogState(() {
                                    if (selected) {
                                      tempSelectedFilters.add(filter);
                                    } else {
                                      tempSelectedFilters.remove(filter);
                                    }
                                  });
                                },
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                selectedColor:
                                    Theme.of(context).colorScheme.primaryContainer,
                                checkmarkColor:
                                    Theme.of(context).colorScheme.onPrimaryContainer,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).textTheme.bodyMedium?.color,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 32),

                  // Sort Section
                  Row(
                    children: [
                      Icon(
                        Icons.sort_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sort By',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      if (tempSelectedSort != null)
                        TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              tempSelectedSort = null;
                            });
                          },
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          label: const Text('Clear'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableSortOptions.map((sort) {
                      final isSelected = tempSelectedSort == sort;
                      
                      return Focus(
                        child: Builder(
                          builder: (context) {
                            final isFocused = Focus.of(context).hasFocus;
                            
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: isFocused
                                    ? Border.all(
                                        color: Theme.of(context).colorScheme.secondary,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: ChoiceChip(
                                label: Text(
                                  sort.replaceAll('_', ' ').toUpperCase(),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setDialogState(() {
                                    tempSelectedSort = selected ? sort : null;
                                  });
                                },
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                selectedColor:
                                    Theme.of(context).colorScheme.secondaryContainer,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onSecondaryContainer
                                      : Theme.of(context).textTheme.bodyMedium?.color,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Summary Section
                  if (tempSelectedFilters.isNotEmpty || tempSelectedSort != null) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Active Filters',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (tempSelectedFilters.isNotEmpty)
                            Text(
                              '• Content: ${tempSelectedFilters.map((f) => f.replaceAll('_', ' ')).join(', ')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (tempSelectedSort != null)
                            Text(
                              '• Sort: ${tempSelectedSort!.replaceAll('_', ' ')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            // Clear All Button
            TextButton.icon(
              onPressed: () {
                setDialogState(() {
                  tempSelectedFilters.clear();
                  tempSelectedSort = null;
                });
              },
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Clear All'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
            
            const Spacer(),
            
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            
            const SizedBox(width: 8),
            
            // Apply Button
            ElevatedButton.icon(
              onPressed: () {
                // Apply filters to main state
                setState(() {
                  _selectedFilters = tempSelectedFilters;
                  _selectedSort = tempSelectedSort;
                });
                
                Navigator.pop(dialogContext);
                _performSearch();
                
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(
                'Apply (${tempSelectedFilters.length + (tempSelectedSort != null ? 1 : 0)})',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

  KeyEventResult _handleTopBarNavigation(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // 🆕 Don't intercept when search field is focused (let it handle text input)
    if (_topBarFocusedIndex == 1) {
      // Only handle navigation keys, let search field handle everything else
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        setState(() => _topBarFocusedIndex = 0);
        _focusTopBarItem(0);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() => _topBarFocusedIndex = 2);
        _focusTopBarItem(2);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        final state = context.read<VideosCubit>().state;
        if (state is VideosSearchSuccess || state is VideosLoadingMore) {
          _gridFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored; // Let search field handle
    }

    // Handle navigation for other buttons
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_topBarFocusedIndex > 0) {
        setState(() => _topBarFocusedIndex--);
        _focusTopBarItem(_topBarFocusedIndex);
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_topBarFocusedIndex < 3) {
        setState(() => _topBarFocusedIndex++);
        _focusTopBarItem(_topBarFocusedIndex);
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final state = context.read<VideosCubit>().state;
      if (state is VideosSearchSuccess || state is VideosLoadingMore) {
        _gridFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      // 🆕 Activate focused button
      if (_topBarFocusedIndex == 0) {
        print('⬅️ Back button pressed');
        Navigator.of(context).pop();
      } else if (_topBarFocusedIndex == 2) {
        print('🎛️ Filters button pressed');
        _showFiltersDialog();
      } else if (_topBarFocusedIndex == 3) {
        print('🔍 Search button pressed');
        _performSearch();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _focusTopBarItem(int index) {
    switch (index) {
      case 0:
        _backButtonFocusNode.requestFocus();
        break;
      case 1:
        _searchFocusNode.requestFocus();
        break;
      case 2:
        _filtersButtonFocusNode.requestFocus();
        break;
      case 3:
        _searchButtonFocusNode.requestFocus();
        break;
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

              // Top Bar
              Focus(
                onKeyEvent: (node, event) => _handleTopBarNavigation(event),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Row(
                    children: [
                      // Back Button
                      Focus(
                        focusNode: _backButtonFocusNode,
                        onFocusChange: (hasFocus) {
                          if (hasFocus) setState(() => _topBarFocusedIndex = 0);
                        },
                        child: Builder(
                          builder: (context) {
                            final isFocused = Focus.of(context).hasFocus;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: isFocused
                                    ? Border.all(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, size: 32),
                                onPressed: () {
                                  print('⬅️ Back button clicked');
                                  Navigator.of(context).pop();
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.surface,
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Search Bar
                      Expanded(
                        child: SearchBarWidget(
                          focusNode: _searchFocusNode,
                          controller: _searchController,
                          onEscapePressed: () {
                            _backButtonFocusNode.requestFocus();
                            setState(() => _topBarFocusedIndex = 0);
                          },
                          onSearchSubmitted: () {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _gridFocusNode.requestFocus();
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Filters Button
                      Focus(
                        focusNode: _filtersButtonFocusNode,
                        onFocusChange: (hasFocus) {
                          if (hasFocus) setState(() => _topBarFocusedIndex = 2);
                        },
                        child: Builder(
                          builder: (context) {
                            final isFocused = Focus.of(context).hasFocus;
                            final hasFilters = _selectedFilters.isNotEmpty ||
                                _selectedSort != null;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: isFocused
                                    ? Border.all(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: IconButton(
                                onPressed: () {
                                  print('🎛️ Filters button clicked');
                                  _showFiltersDialog();
                                },
                                icon: Badge(
                                  isLabelVisible: hasFilters,
                                  label: Text(
                                    '${_selectedFilters.length + (_selectedSort != null ? 1 : 0)}',
                                  ),
                                  child: const Icon(Icons.tune_rounded),
                                ),
                                tooltip: 'Filters',
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.surface,
                                  foregroundColor: hasFilters
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                  padding: const EdgeInsets.all(20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Search Button
                      Focus(
                        focusNode: _searchButtonFocusNode,
                        onFocusChange: (hasFocus) {
                          if (hasFocus) setState(() => _topBarFocusedIndex = 3);
                        },
                        child: Builder(
                          builder: (context) {
                            final isFocused = Focus.of(context).hasFocus;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: isFocused
                                    ? Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  print('🔍 Search button clicked');
                                  _performSearch();
                                },
                                icon: const Icon(Icons.search_rounded),
                                label: Text('search'.tr()),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 20,
                                  ),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Results Grid
              Expanded(
                child: BlocConsumer<VideosCubit, VideosState>(
                  listener: (context, state) {
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
                              gridFocusNode: _gridFocusNode,
                              onEscapePressed: () {
                                _searchFocusNode.requestFocus();
                                setState(() => _topBarFocusedIndex = 1);
                              },
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
