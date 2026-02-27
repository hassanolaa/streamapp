import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streamapp/features/home/presentation/pages/home_page.dart';
import 'package:streamapp/features/iptv/presentation/pages/iptv_search_page.dart';
import 'package:streamapp/features/movies/presentation/pages/movies_search_page.dart';
import 'package:streamapp/features/series/presentation/pages/series_search_page.dart';
import 'package:streamapp/features/videos/presentation/pages/search_page.dart';

class CategoryFilterWidget extends StatefulWidget {
  final Function(String)? onCategoryChanged;
  final VoidCallback? onNavigateDown;

  const CategoryFilterWidget({
    super.key,
    this.onCategoryChanged,
    this.onNavigateDown,
  });

  @override
  State<CategoryFilterWidget> createState() => CategoryFilterWidgetState();
}

class CategoryFilterWidgetState extends State<CategoryFilterWidget> {
  int _selectedIndex = 0; // Currently selected (active) category
  int _focusedIndex = 0; // Currently focused (previewed) item
  final List<FocusNode> _focusNodes = List.generate(9, (_) => FocusNode());
  final ScrollController _scrollController = ScrollController();

  final List<String> _categories = [
    'all',
    'videos',
    'movies',
    'series',
    'podcasts',
    'iptv',
    'live_channels',
  ];

  @override
  void initState() {
    super.initState();
    // Auto focus first item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // PUBLIC method to refocus on "Videos" tab (called from parent)
  void requestFocusOnVideos() {
    final videosIndex = _categories.indexOf('videos');
    if (videosIndex != -1) {
      setState(() {
        _selectedIndex = videosIndex;
        _focusedIndex = videosIndex;
      });
      _scrollToIndex(videosIndex);
      _focusNodes[videosIndex].requestFocus();
    }
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;

    final itemWidth = 140.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = (index * itemWidth) - (screenWidth / 2) + 70;

    _scrollController.animateTo(
      offset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // 🆕 Move focus (preview) without selecting
  void _moveFocus(int index) {
    if (index < 0 || index > _categories.length) return;

    setState(() => _focusedIndex = index);

    if (index < _categories.length) {
      _scrollToIndex(index);
      _focusNodes[index].requestFocus();
    } else {
      // Search button focused
      _focusNodes[_categories.length].requestFocus();
    }

    print('👁️ Preview focus on: ${index < _categories.length ? _categories[index] : "search"}');
  }

  // 🆕 Actually select the focused item
  void _selectFocusedItem() {
    if (_focusedIndex == _categories.length) {
      // Search button selected
      _onSearchPressed();
      return;
    }

    if (_focusedIndex < _categories.length) {
      setState(() => _selectedIndex = _focusedIndex);

      // Notify parent
      if (widget.onCategoryChanged != null) {
        widget.onCategoryChanged!(_categories[_selectedIndex]);
      }

      print('✅ Selected: ${_categories[_selectedIndex]}');
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_focusedIndex > 0) {
        _moveFocus(_focusedIndex - 1);
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_focusedIndex < _categories.length) {
        _moveFocus(_focusedIndex + 1);
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      // Navigate down to video content (only when currently selected category is "videos")
      if (_selectedIndex == _categories.indexOf('videos')) {
        if (widget.onNavigateDown != null) {
          widget.onNavigateDown!();
          return KeyEventResult.handled;
        }
      }
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select) {
      _selectFocusedItem();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Row(
        children: [
          // Categories
          Expanded(
            child: SizedBox(
              height: 56,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedIndex == index;
                  final isFocused = _focusedIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Focus(
                      focusNode: _focusNodes[index],
                      onKeyEvent: _handleKeyEvent,
                      child: _SimpleCategoryChip(
                        label: category.tr(),
                        isSelected: isSelected,
                        isFocused: isFocused,
                        onTap: () {
                          // On click, both focus and select
                          setState(() {
                            _focusedIndex = index;
                            _selectedIndex = index;
                          });
                          _scrollToIndex(index);
                          _focusNodes[index].requestFocus();

                          if (widget.onCategoryChanged != null) {
                            widget.onCategoryChanged!(_categories[index]);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Search Button
          Focus(
            focusNode: _focusNodes[_categories.length],
            onKeyEvent: _handleKeyEvent,
            child: _SimpleSearchButton(
              isFocused: _focusedIndex == _categories.length,
              onPressed: _onSearchPressed,
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchPressed() {
    if (globalselectedCategory == "movies") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MoviesSearchPage(),
        ),
      );
    } else if (globalselectedCategory == "series") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SeriesSearchPage(),
        ),
      );
    } else if (globalselectedCategory == "iptv") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const IptvSearchPage(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SearchPage(),
        ),
      );
    }
  }
}

class _SimpleCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isFocused;
  final VoidCallback onTap;

  const _SimpleCategoryChip({
    required this.label,
    required this.isSelected,
    required this.isFocused,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          // 🆕 Selected = filled with primary color
          // Focused (preview) = outlined
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            // 🆕 Show border when focused but not selected
            color: isFocused && !isSelected
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🆕 Arrow indicator when focused but not selected
            if (isFocused && !isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: theme.colorScheme.primary,
                ),
              ),

            // Checkmark when selected AND focused
            if (isSelected && isFocused)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),

            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleSearchButton extends StatelessWidget {
  final bool isFocused;
  final VoidCallback onPressed;

  const _SimpleSearchButton({
    required this.isFocused,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(28),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: isFocused ? theme.colorScheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: Icon(
          Icons.search_rounded,
          color: isFocused
              ? theme.colorScheme.primary
              : theme.textTheme.bodyMedium?.color,
          size: 24,
        ),
      ),
    );
  }
}
