import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streamapp/features/videos/presentation/pages/search_page.dart';

class CategoryFilterWidget extends StatefulWidget {
  const CategoryFilterWidget({super.key});

  @override
  State<CategoryFilterWidget> createState() => _CategoryFilterWidgetState();
}

class _CategoryFilterWidgetState extends State<CategoryFilterWidget> {
  int _selectedIndex = 0;
  final List<FocusNode> _focusNodes = List.generate(9, (_) => FocusNode()); // 8 categories + 1 search
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
  void dispose() {
    _scrollController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _scrollToIndex(int index) {
    final itemWidth = 120.0;
    final offset = index * itemWidth;
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const _NavigateLeftIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const _NavigateRightIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
      },
      child: Actions(
        actions: {
          _NavigateLeftIntent: CallbackAction<_NavigateLeftIntent>(
            onInvoke: (_) {
              if (_selectedIndex > 0) {
                setState(() => _selectedIndex--);
                _focusNodes[_selectedIndex].requestFocus();
                if (_selectedIndex < _categories.length) {
                  _scrollToIndex(_selectedIndex);
                }
              }
              return null;
            },
          ),
          _NavigateRightIntent: CallbackAction<_NavigateRightIntent>(
            onInvoke: (_) {
              if (_selectedIndex < _categories.length) { // Can navigate to search icon
                setState(() => _selectedIndex++);
                _focusNodes[_selectedIndex].requestFocus();
                if (_selectedIndex < _categories.length) {
                  _scrollToIndex(_selectedIndex);
                }
              }
              return null;
            },
          ),
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Row(
            children: [
              // Category List
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Focus(
                          focusNode: _focusNodes[index],
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                              setState(() => _selectedIndex = index);
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: _CategoryChip(
                            label: category.tr(),
                            isSelected: isSelected,
                            onTap: () => setState(() => _selectedIndex = index),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Search Icon Button
              Focus(
                focusNode: _focusNodes[_categories.length],
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                    _onSearchPressed();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: _SearchButton(
                  isFocused: _selectedIndex == _categories.length,
                  onPressed: _onSearchPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSearchPressed() {
    // TODO: Implement search functionality
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('search_pressed'.tr())),
    // );
    Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPage(),));
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium!.color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  final bool isFocused;
  final VoidCallback onPressed;

  const _SearchButton({
    required this.isFocused,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isFocused
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFocused ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.search_rounded,
          color: isFocused ? Colors.white : Theme.of(context).textTheme.bodyMedium!.color,
          size: 24,
        ),
      ),
    );
  }
}

class _NavigateLeftIntent extends Intent {
  const _NavigateLeftIntent();
}

class _NavigateRightIntent extends Intent {
  const _NavigateRightIntent();
}
