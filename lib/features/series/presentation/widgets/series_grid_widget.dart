import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streamapp/features/series/data/models/series_model.dart';
import 'package:streamapp/features/series/presentation/widgets/series_card_widget.dart';

class SeriesGridWidget extends StatefulWidget {
  final List<SeriesModel> series;
  final ScrollController scrollController;
  final FocusNode? gridFocusNode;
  final VoidCallback? onEscapePressed;
  final void Function(SeriesModel series)? onSeriesTap;

  const SeriesGridWidget({
    super.key,
    required this.series,
    required this.scrollController,
    this.gridFocusNode,
    this.onEscapePressed,
    this.onSeriesTap,
  });

  @override
  State<SeriesGridWidget> createState() => _SeriesGridWidgetState();
}

class _SeriesGridWidgetState extends State<SeriesGridWidget> {
  int _focusedIndex = 0;
  late List<GlobalKey> _cardKeys;
  final int _columnsCount = 5;

  @override
  void initState() {
    super.initState();
    _cardKeys = List.generate(widget.series.length, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(SeriesGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.series.length != oldWidget.series.length) {
      _cardKeys = List.generate(widget.series.length, (_) => GlobalKey());
      _focusedIndex =
          _focusedIndex.clamp(0, math.max(0, widget.series.length - 1));
    }
  }

  void _scrollToFocusedItem() {
    if (_focusedIndex < 0 || _focusedIndex >= _cardKeys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final key = _cardKeys[_focusedIndex];
        final ctx = key.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: 0.2,
          );
        }
      } catch (_) {}
    });
  }

  void _navigate(int direction) {
    if (widget.series.isEmpty) return;
    final int maxIndex = widget.series.length - 1;
    int newIndex = _focusedIndex;
    final currentCol = _focusedIndex % _columnsCount;

    if (direction == -1) {
      if (currentCol > 0) newIndex = _focusedIndex - 1;
    } else if (direction == 1) {
      if (currentCol < _columnsCount - 1 && _focusedIndex + 1 <= maxIndex) {
        newIndex = _focusedIndex + 1;
      }
    } else if (direction == -_columnsCount) {
      newIndex = math.max(0, _focusedIndex - _columnsCount);
    } else if (direction == _columnsCount) {
      newIndex = math.min(maxIndex, _focusedIndex + _columnsCount);
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
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.select) {
          if (_focusedIndex < widget.series.length) {
            widget.onSeriesTap?.call(widget.series[_focusedIndex]);
          }
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
        itemCount: widget.series.length,
        itemBuilder: (context, index) {
          final isFocused = _focusedIndex == index;
          return GestureDetector(
            key: _cardKeys[index],
            onTap: () {
              setState(() => _focusedIndex = index);
              widget.onSeriesTap?.call(widget.series[index]);
            },
            child: SeriesCardWidget(
              series: widget.series[index],
              isFocused: isFocused,
              onTap: () {
                setState(() => _focusedIndex = index);
                widget.onSeriesTap?.call(widget.series[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
