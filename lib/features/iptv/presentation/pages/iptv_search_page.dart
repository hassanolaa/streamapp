import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/core/di/service_locator.dart';
import 'package:streamapp/core/services/content_filter_service.dart';
import 'package:streamapp/features/iptv/data/models/iptv_enriched_channel.dart';
import 'package:streamapp/features/iptv/presentation/cubit/iptv_cubit.dart';
import 'package:streamapp/features/iptv/presentation/cubit/iptv_state.dart';
import 'package:streamapp/features/iptv/presentation/pages/iptv_player_page.dart';
import 'package:streamapp/features/iptv/presentation/widgets/iptv_channel_card.dart';

class IptvSearchPage extends StatelessWidget {
  const IptvSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IptvCubit(repository: sl()),
      child: const _IptvSearchContent(),
    );
  }
}

class _IptvSearchContent extends StatefulWidget {
  const _IptvSearchContent();

  @override
  State<_IptvSearchContent> createState() => _IptvSearchContentState();
}

class _IptvSearchContentState extends State<_IptvSearchContent> {
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _backButtonFocusNode = FocusNode();
  final FocusNode _searchButtonFocusNode = FocusNode();
  final FocusNode _gridFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  int _topBarFocusedIndex = 1; // 0=back, 1=search field, 2=search button
  int _gridFocusedIndex = 0;
  static const int _gridColumns = 5;

  // Local filter state
  String? _selectedCategory;
  final List<String> _categories = [
    'general',
    'news',
    'sports',
    'entertainment',
    'kids',
    'music',
    'documentary',
    'education',
    'science',
    'weather',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _backButtonFocusNode.dispose();
    _searchButtonFocusNode.dispose();
    _gridFocusNode.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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

    context.read<IptvCubit>().searchChannels(query);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gridFocusNode.requestFocus();
      setState(() => _topBarFocusedIndex = 1);
    });
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
        _searchButtonFocusNode.requestFocus();
        break;
    }
  }

  KeyEventResult _handleTopBarNavigation(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Grid has focus – only intercept Escape
    if (_gridFocusNode.hasFocus) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _searchFocusNode.requestFocus();
        setState(() => _topBarFocusedIndex = 1);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (_topBarFocusedIndex == 1) {
      // Search field is focused – allow text input but handle nav keys
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        setState(() => _topBarFocusedIndex = 0);
        _focusTopBarItem(0);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() => _topBarFocusedIndex = 2);
        _focusTopBarItem(2);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        final state = context.read<IptvCubit>().state;
        if (state is IptvSearchSuccess) {
          _gridFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_topBarFocusedIndex > 0) {
        setState(() => _topBarFocusedIndex--);
        _focusTopBarItem(_topBarFocusedIndex);
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_topBarFocusedIndex < 2) {
        setState(() => _topBarFocusedIndex++);
        _focusTopBarItem(_topBarFocusedIndex);
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final state = context.read<IptvCubit>().state;
      if (state is IptvSearchSuccess) {
        _gridFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select) {
      if (_topBarFocusedIndex == 0) {
        Navigator.of(context).pop();
      } else if (_topBarFocusedIndex == 2) {
        _performSearch();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const _EscapeIntent(),
      },
      child: Actions(
        actions: {
          _EscapeIntent: CallbackAction<_EscapeIntent>(
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

              // Top bar
              Focus(
                onKeyEvent: (_, event) => _handleTopBarNavigation(event),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Row(
                    children: [
                      // Back button
                      _focusableIconButton(
                        focusNode: _backButtonFocusNode,
                        isFocused: _topBarFocusedIndex == 0,
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).pop(),
                        onFocusChange: (f) {
                          if (f) setState(() => _topBarFocusedIndex = 0);
                        },
                      ),

                      const SizedBox(width: 16),

                      // Search bar
                      Expanded(
                        child: _IptvSearchBar(
                          focusNode: _searchFocusNode,
                          controller: _searchController,
                          isFocused: _topBarFocusedIndex == 1,
                          onFocusChange: (f) {
                            if (f) setState(() => _topBarFocusedIndex = 1);
                          },
                          onSubmitted: _performSearch,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Search button
                      Focus(
                        focusNode: _searchButtonFocusNode,
                        onFocusChange: (f) {
                          if (f) setState(() => _topBarFocusedIndex = 2);
                        },
                        child: Builder(builder: (ctx) {
                          final focused =
                              Focus.of(ctx).hasFocus || _topBarFocusedIndex == 2;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: focused
                                  ? Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    )
                                  : null,
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _performSearch,
                              icon: const Icon(Icons.search_rounded),
                              label: const Text('Search'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 20),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Category chips filter
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return FilterChip(
                      label: Text(cat.replaceAll('_', ' ').toUpperCase()),
                      selected: isSelected,
                      onSelected: (sel) {
                        setState(() {
                          _selectedCategory = sel ? cat : null;
                        });
                        // Re-trigger search if we have a query
                        if (_searchController.text.trim().isNotEmpty) {
                          _performSearch();
                        }
                      },
                      backgroundColor:
                          Theme.of(context).colorScheme.surface,
                      selectedColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      checkmarkColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.3),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Results area
              Expanded(
                child: BlocBuilder<IptvCubit, IptvState>(
                  builder: (context, state) {
                    if (state is IptvInitial) {
                      return _buildEmptyPrompt(context);
                    }

                    if (state is IptvLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is IptvError) {
                      return _buildErrorState(context, state.message);
                    }

                    if (state is IptvSearchSuccess) {
                      var results = state.results;

                      // Filter by category if selected
                      if (_selectedCategory != null) {
                        results = results
                            .where((ch) => ch.categories
                                .contains(_selectedCategory))
                            .toList();
                      }

                      if (results.isEmpty) {
                        return _buildNoResults(context, state.query);
                      }

                      return _buildResultsGrid(context, results);
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

  Widget _focusableIconButton({
    required FocusNode focusNode,
    required bool isFocused,
    required IconData icon,
    required VoidCallback onTap,
    required ValueChanged<bool> onFocusChange,
  }) {
    return Focus(
      focusNode: focusNode,
      onFocusChange: onFocusChange,
      child: Builder(builder: (ctx) {
        final focused = Focus.of(ctx).hasFocus || isFocused;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: focused
                ? Border.all(
                    color: Theme.of(ctx).colorScheme.primary, width: 3)
                : null,
          ),
          child: IconButton(
            icon: Icon(icon, size: 32),
            onPressed: onTap,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.surface,
              padding: const EdgeInsets.all(12),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.live_tv_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
          const SizedBox(height: 20),
          Text(
            'Search IPTV Channels',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Search by channel name, country, or category',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context, String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.error.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or category filter.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildResultsGrid(
      BuildContext context, List<IptvEnrichedChannel> channels) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Row(
            children: [
              Text(
                'Search Results',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Text(
                '${channels.length} channels',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Grid
        Expanded(
          child: Focus(
            focusNode: _gridFocusNode,
            skipTraversal: true,
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                return KeyEventResult.ignored;
              }

              final maxIndex = channels.length - 1;
              int newIndex = _gridFocusedIndex;

              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                if (_gridFocusedIndex % _gridColumns > 0) {
                  newIndex = _gridFocusedIndex - 1;
                }
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                if (_gridFocusedIndex % _gridColumns < _gridColumns - 1 &&
                    _gridFocusedIndex + 1 <= maxIndex) {
                  newIndex = _gridFocusedIndex + 1;
                }
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                if (_gridFocusedIndex < _gridColumns) {
                  _searchFocusNode.requestFocus();
                  setState(() => _topBarFocusedIndex = 1);
                  return KeyEventResult.handled;
                }
                newIndex = _gridFocusedIndex - _gridColumns;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                newIndex = (_gridFocusedIndex + _gridColumns).clamp(0, maxIndex);
              } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.select) {
                if (_gridFocusedIndex < channels.length) {
                  final ch = channels[_gridFocusedIndex];
                  if (ch.streamUrl != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IptvPlayerPage(channel: ch),
                      ),
                    );
                  }
                }
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                _searchFocusNode.requestFocus();
                setState(() => _topBarFocusedIndex = 1);
                return KeyEventResult.handled;
              } else {
                return KeyEventResult.ignored;
              }

              if (newIndex != _gridFocusedIndex && newIndex >= 0) {
                setState(() => _gridFocusedIndex = newIndex);
                _scrollToGridItem(newIndex);
              }
              return KeyEventResult.handled;
            },
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 60),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridColumns,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                final isFocused =
                    _gridFocusNode.hasFocus && _gridFocusedIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() => _gridFocusedIndex = index);
                    if (channel.streamUrl != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IptvPlayerPage(channel: channel),
                        ),
                      );
                    }
                  },
                  child: IptvChannelCard(
                    channel: channel,
                    isFocused: isFocused,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _scrollToGridItem(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        final itemHeight = (MediaQuery.of(context).size.width - 120) /
            _gridColumns; // rough estimate
        final row = index ~/ _gridColumns;
        final offset = row * (itemHeight + 16);
        _scrollController.animateTo(
          offset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }
}

// ---------------------------------------------------------------------------
// Simple search bar for IPTV
// ---------------------------------------------------------------------------

class _IptvSearchBar extends StatefulWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final bool isFocused;
  final ValueChanged<bool> onFocusChange;
  final VoidCallback onSubmitted;

  const _IptvSearchBar({
    required this.focusNode,
    required this.controller,
    required this.isFocused,
    required this.onFocusChange,
    required this.onSubmitted,
  });

  @override
  State<_IptvSearchBar> createState() => _IptvSearchBarState();
}

class _IptvSearchBarState extends State<_IptvSearchBar> {
  final FocusNode _textFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _textFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _textFocusNode.requestFocus());
    }
    widget.onFocusChange(widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: widget.isFocused
            ? Border.all(
                color: Theme.of(context).colorScheme.primary, width: 3)
            : null,
      ),
      child: Focus(
        focusNode: widget.focusNode,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              return KeyEventResult.ignored;
            }
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: widget.controller,
          focusNode: _textFocusNode,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Search channels by name, country, category...',
            hintStyle: Theme.of(context).textTheme.bodyMedium,
            prefixIcon: Icon(
              Icons.live_tv_rounded,
              color:
                  Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (_) => widget.onSubmitted(),
        ),
      ),
    );
  }
}

class _EscapeIntent extends Intent {
  const _EscapeIntent();
}
