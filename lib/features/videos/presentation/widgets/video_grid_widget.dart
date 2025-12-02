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
      for (var node in _focusNodes) {
        node.dispose();
      }
      _focusNodes = List.generate(widget.items.length, (_) => FocusNode());
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
    int newIndex = _focusedIndex;

    if (direction == -1 && _focusedIndex > 0) {
      // Left
      newIndex = _focusedIndex - 1;
    } else if (direction == 1 && _focusedIndex < widget.items.length - 1) {
      // Right
      newIndex = _focusedIndex + 1;
    } else if (direction == -_columnsCount && _focusedIndex >= _columnsCount) {
      // Up
      newIndex = _focusedIndex - _columnsCount;
    } else if (direction == _columnsCount && _focusedIndex + _columnsCount < widget.items.length) {
      // Down
      newIndex = _focusedIndex + _columnsCount;
    }

    if (newIndex != _focusedIndex) {
      setState(() => _focusedIndex = newIndex);
      _focusNodes[_focusedIndex].requestFocus();
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
            return Focus(
              focusNode: _focusNodes[index],
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
