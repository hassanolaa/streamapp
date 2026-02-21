import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streamapp/features/movies/data/models/movie_model.dart';
import 'package:streamapp/features/movies/presentation/widgets/movie_card_widget.dart';

class MovieGridWidget extends StatefulWidget {
  final List<MovieModel> movies;
  final ScrollController scrollController;
  final FocusNode? gridFocusNode;
  final VoidCallback? onEscapePressed;
  final void Function(MovieModel movie)? onMovieTap;

  const MovieGridWidget({
    super.key,
    required this.movies,
    required this.scrollController,
    this.gridFocusNode,
    this.onEscapePressed,
    this.onMovieTap,
  });

  @override
  State<MovieGridWidget> createState() => _MovieGridWidgetState();
}

class _MovieGridWidgetState extends State<MovieGridWidget> {
  int _focusedIndex = 0;
  late List<GlobalKey> _cardKeys;
  final int _columnsCount = 5;

  @override
  void initState() {
    super.initState();
    _cardKeys = List.generate(widget.movies.length, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(MovieGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.movies.length != oldWidget.movies.length) {
      _cardKeys = List.generate(widget.movies.length, (_) => GlobalKey());
      _focusedIndex =
          _focusedIndex.clamp(0, math.max(0, widget.movies.length - 1));
    }
  }

  void _scrollToFocusedItem() {
    if (_focusedIndex < 0 || _focusedIndex >= _cardKeys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final key = _cardKeys[_focusedIndex];
        final context = key.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: 0.2,
          );
        }
      } catch (e) {
        print('❌ Error scrolling to item: $e');
      }
    });
  }

  void _navigate(int direction) {
    if (widget.movies.isEmpty) return;
    final int maxIndex = widget.movies.length - 1;
    int newIndex = _focusedIndex;
    final currentCol = _focusedIndex % _columnsCount;

    if (direction == -1) {
      if (currentCol > 0) newIndex = _focusedIndex - 1;
    } else if (direction == 1) {
      if (currentCol < _columnsCount - 1 && _focusedIndex + 1 <= maxIndex) {
        newIndex = _focusedIndex + 1;
      }
    } else if (direction == -_columnsCount) {
      newIndex = _focusedIndex - _columnsCount;
      if (newIndex < 0) newIndex = _focusedIndex;
    } else if (direction == _columnsCount) {
      newIndex = _focusedIndex + _columnsCount;
      if (newIndex > maxIndex) newIndex = _focusedIndex;
    }

    if (newIndex != _focusedIndex) {
      setState(() => _focusedIndex = newIndex);
      _scrollToFocusedItem();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.gridFocusNode,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _navigate(-1);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _navigate(1);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          if (_focusedIndex < _columnsCount) {
            widget.onEscapePressed?.call();
          } else {
            _navigate(-_columnsCount);
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _navigate(_columnsCount);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onEscapePressed?.call();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: GridView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 60),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 24,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: widget.movies.length,
        itemBuilder: (context, index) {
          final isFocused = _focusedIndex == index;
          return Container(
            key: _cardKeys[index],
            child: GestureDetector(
              onTap: () {
                setState(() => _focusedIndex = index);
              },
              child: MovieCardWidget(
                movie: widget.movies[index],
                isFocused: isFocused,
                onTap: () {
                  setState(() => _focusedIndex = index);
                  widget.onMovieTap?.call(widget.movies[index]);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
