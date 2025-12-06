import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/presentation/widgets/video_card_widget.dart';

class VideoGridWidget extends StatefulWidget {
  final List<SummaryModel> items;
  final ScrollController scrollController;

  const VideoGridWidget({
    super.key,
    required this.items,
    required this.scrollController,
  });

  @override
  State<VideoGridWidget> createState() => _VideoGridWidgetState();
}

class _VideoGridWidgetState extends State<VideoGridWidget> {
  int _focusedIndex = 0;
  late List<FocusNode> _focusNodes;
  final int _columnsCount = 4;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.items.length, (_) => FocusNode());
  }

   @override
  void didUpdateWidget(VideoGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.items.length != oldWidget.items.length) {
      // preserve old focused index but clamp it to new range
      final oldFocused = _focusedIndex;
      for (var node in _focusNodes) {
        node.dispose();
      }

      _focusNodes = List.generate(widget.items.length, (_) => FocusNode());

      // clamp focused index to new range (if there are items)
      if (widget.items.isEmpty) {
        _focusedIndex = 0;
      } else {
        _focusedIndex = oldFocused.clamp(0, widget.items.length - 1);
      }

      // request focus on the new index if appropriate
      if (_focusNodes.isNotEmpty) {
        // use addPostFrameCallback to avoid interfering with the current build cycle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_focusedIndex >= 0 && _focusedIndex < _focusNodes.length) {
            _focusNodes[_focusedIndex].requestFocus();
          }
        });
      }
    }
  }


  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

 void _navigate(int direction) {
  if (widget.items.isEmpty || _focusNodes.isEmpty) return;

  final int maxItemIndex = widget.items.length - 1;
  final int maxFocusIndex = _focusNodes.length - 1;
  // use the smaller max to avoid race
  final int maxIndex = math.min(maxItemIndex, maxFocusIndex);

  int newIndex = _focusedIndex;

  if (direction == -1 && _focusedIndex > 0) {
    newIndex = _focusedIndex - 1;
  } else if (direction == 1 && _focusedIndex < maxIndex) {
    newIndex = _focusedIndex + 1;
  } else if (direction == -_columnsCount && _focusedIndex >= _columnsCount) {
    newIndex = _focusedIndex - _columnsCount;
  } else if (direction == _columnsCount && _focusedIndex + _columnsCount <= maxIndex) {
    newIndex = _focusedIndex + _columnsCount;
  }

  if (newIndex != _focusedIndex) {
    // clamp against the computed maxIndex
    newIndex = newIndex.clamp(0, maxIndex) as int;
    setState(() => _focusedIndex = newIndex);

    // guard again before requesting focus
    if (_focusedIndex >= 0 && _focusedIndex <= maxFocusIndex) {
      _focusNodes[_focusedIndex].requestFocus();
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const _NavigateLeftIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const _NavigateRightIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const _NavigateUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const _NavigateDownIntent(),
      },
      child: Actions(
        actions: {
          _NavigateLeftIntent: CallbackAction<_NavigateLeftIntent>(
            onInvoke: (_) {
              _navigate(-1);
              return null;
            },
          ),
          _NavigateRightIntent: CallbackAction<_NavigateRightIntent>(
            onInvoke: (_) {
              _navigate(1);
              return null;
            },
          ),
          _NavigateUpIntent: CallbackAction<_NavigateUpIntent>(
            onInvoke: (_) {
              _navigate(-_columnsCount);
              return null;
            },
          ),
          _NavigateDownIntent: CallbackAction<_NavigateDownIntent>(
            onInvoke: (_) {
              _navigate(_columnsCount);
              return null;
            },
          ),
        },
        child: GridView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 60),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: 0.7,
          ),
          itemCount: widget.items.length,
         itemBuilder: (context, index) {
  // safe access - if index is out of range of _focusNodes, use a local temporary Focus widget
  if (index < _focusNodes.length) {
    return Focus(
      focusNode: _focusNodes[index],
      child: VideoCardWidget(
        summary: widget.items[index],
        isFocused: _focusedIndex == index,
      ),
    );
  }

  // Fallback: render without a focus node until didUpdateWidget recreates them.
  return Focus(
    child: VideoCardWidget(
      summary: widget.items[index],
      isFocused: _focusedIndex == index,
    ),
  );
},
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

class _NavigateUpIntent extends Intent {
  const _NavigateUpIntent();
}

class _NavigateDownIntent extends Intent {
  const _NavigateDownIntent();
}
