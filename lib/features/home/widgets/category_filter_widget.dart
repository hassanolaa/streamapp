import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// Made PUBLIC (no underscore) so GlobalKey can access it
class CategoryFilterWidgetState extends State<CategoryFilterWidget> {
  int _selectedIndex = 0;
  final List<FocusNode> _focusNodes = List.generate(9, (_) => FocusNode());
  final ScrollController _scrollController = ScrollController();
  
  final List<String> _categories = [
    'all',
    'videos',
    'movies',
    'series',
    'tv_shows',
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

  void _onCategorySelected(int index) {
    if (index < 0 || index > _categories.length) return;
    
    
    setState(() => _selectedIndex = index);
    
    if (index < _categories.length) {
      _scrollToIndex(index);
      _focusNodes[index].requestFocus();
      
      // Notify parent
      if (widget.onCategoryChanged != null) {
        widget.onCategoryChanged!(_categories[index]);
      }
    } else {
      // Search button focused
      _focusNodes[_categories.length].requestFocus();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    
    
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_selectedIndex > 0) {
        _onCategorySelected(_selectedIndex - 1);
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_selectedIndex < _categories.length) {
        _onCategorySelected(_selectedIndex + 1);
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      
      // Navigate down to video content (only when "videos" tab is selected)
      if (_selectedIndex == _categories.indexOf('videos')) {
        
        if (widget.onNavigateDown != null) {
          widget.onNavigateDown!();
          return KeyEventResult.handled;
        } else {
        }
      } else {
      }
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select) {
      if (_selectedIndex == _categories.length) {
        _onSearchPressed();
      } else {
        _onCategorySelected(_selectedIndex);
      }
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
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Focus(
                      focusNode: _focusNodes[index],
                      onKeyEvent: _handleKeyEvent,
                      child: _SimpleCategoryChip(
                        label: category.tr(),
                        isSelected: isSelected,
                        isFocused: _focusNodes[index].hasFocus,
                        onTap: () => _onCategorySelected(index),
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
              isFocused: _selectedIndex == _categories.length,
              onPressed: _onSearchPressed,
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchPage(),
      ),
    );
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
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isFocused
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Focus indicator (arrow)
            if (isFocused && !isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: theme.colorScheme.primary,
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
          color: isFocused
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceVariant.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: isFocused
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.search_rounded,
          color: isFocused
              ? Colors.white
              : theme.textTheme.bodyMedium?.color,
          size: 24,
        ),
      ),
    );
  }
}
