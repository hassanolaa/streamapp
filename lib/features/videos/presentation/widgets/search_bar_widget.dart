import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_cubit.dart';

class SearchBarWidget extends StatefulWidget {
  final FocusNode focusNode;

  const SearchBarWidget({super.key, required this.focusNode});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  List<String> _selectedFilters = [];
  String? _selectedSort;
  bool _showAdvancedOptions = false;

  // Available filters (from YouTube API)
  final List<String> _availableFilters = [
    'all',
    'videos',
    'channels',
    'playlists',
    'music_songs',
    'music_videos',
    'music_albums',
    'music_playlists',
  ];

  // Available sort options (from YouTube API)
  final List<String> _availableSortOptions = [
    'relevance',
    'upload_date',
    'view_count',
    'rating',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      // Search with filters and sort
      context.read<VideosCubit>().searchVideos(
            query,
            filters: _selectedFilters.isNotEmpty ? _selectedFilters : null,
            sortCriteria: _selectedSort,
          );
    }
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main search row
        Row(
          children: [
            // Search Input
            Expanded(
              child: Focus(
                focusNode: widget.focusNode,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter) {
                    _performSearch();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: _controller,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'search_hint'.tr(),
                    hintStyle: Theme.of(context).textTheme.bodyMedium,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Theme.of(context).textTheme.bodyMedium!.color,
                    ),
                    suffixIcon: _selectedFilters.isNotEmpty || _selectedSort != null
                        ? Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.filter_list_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_selectedFilters.length + (_selectedSort != null ? 1 : 0)}',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Advanced Options Toggle
            IconButton(
              onPressed: () {
                setState(() {
                  _showAdvancedOptions = !_showAdvancedOptions;
                });
              },
              icon: Icon(
                _showAdvancedOptions ? Icons.expand_less : Icons.tune_rounded,
              ),
              tooltip: 'Advanced Options',
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: _showAdvancedOptions
                    ? Theme.of(context).colorScheme.primary
                    : null,
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Search Button
            ElevatedButton.icon(
              onPressed: _performSearch,
              icon: const Icon(Icons.search_rounded),
              label: Text('search'.tr()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),

        // Advanced Options Panel
        if (_showAdvancedOptions) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Filters',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    if (_selectedFilters.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedFilters.clear();
                          });
                        },
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableFilters.map((filter) {
                    final isSelected = _selectedFilters.contains(filter);
                    return FilterChip(
                      label: Text(filter.replaceAll('_', ' ').toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) => _toggleFilter(filter),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      selectedColor: Theme.of(context).colorScheme.primaryContainer,
                      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : null,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),

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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    if (_selectedSort != null)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedSort = null;
                          });
                        },
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSortOptions.map((sort) {
                    final isSelected = _selectedSort == sort;
                    return ChoiceChip(
                      label: Text(sort.replaceAll('_', ' ').toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedSort = selected ? sort : null;
                        });
                      },
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      selectedColor: Theme.of(context).colorScheme.secondaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
