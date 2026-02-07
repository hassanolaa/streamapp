import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/presentation/widgets/video_card_widget.dart';

class VideoGridWidget extends StatefulWidget {
  final List<SummaryModel> items;
  final ScrollController scrollController;
  final FocusNode? gridFocusNode;
  final VoidCallback? onEscapePressed;

  const VideoGridWidget({
    super.key,
    required this.items,
    required this.scrollController,
    this.gridFocusNode,
    this.onEscapePressed,
  });

  @override
  State<VideoGridWidget> createState() => _VideoGridWidgetState();
}

class _VideoGridWidgetState extends State<VideoGridWidget> {
  int _focusedIndex = 0;
  late List<FocusNode> _focusNodes;
  late List<GlobalKey> _cardKeys;
  final int _columnsCount = 4;
  final FocusNode _internalGridFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeFocusNodes();

    (widget.gridFocusNode ?? _internalGridFocusNode).addListener(_onGridFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty && mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _initializeFocusNodes() {
    _focusNodes = List.generate(
      widget.items.length,
      (index) => FocusNode()
        ..addListener(() {
          if (_focusNodes[index].hasFocus && _focusedIndex != index) {
            setState(() {
              _focusedIndex = index;
            });
            print('🎯 Focus changed to index: $index');
          }
        }),
    );
    _cardKeys = List.generate(widget.items.length, (_) => GlobalKey());
  }

  void _onGridFocusChange() {
    final gridFocusNode = widget.gridFocusNode ?? _internalGridFocusNode;
    
    if (gridFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_focusedIndex >= 0 && _focusedIndex < _focusNodes.length && mounted) {
          _focusNodes[_focusedIndex].requestFocus();
          print('🎯 Grid focused, activating item at index: $_focusedIndex');
        }
      });
    }
  }

  @override
  void didUpdateWidget(VideoGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.items.length != oldWidget.items.length) {
      final oldFocused = _focusedIndex;

      for (var node in _focusNodes) {
        node.dispose();
      }

      _initializeFocusNodes();

      if (widget.items.isEmpty) {
        _focusedIndex = 0;
      } else {
        _focusedIndex = oldFocused.clamp(0, widget.items.length - 1);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_focusedIndex >= 0 && _focusedIndex < _focusNodes.length && mounted) {
          _focusNodes[_focusedIndex].requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    (widget.gridFocusNode ?? _internalGridFocusNode).removeListener(_onGridFocusChange);
    _internalGridFocusNode.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
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
    if (widget.items.isEmpty || _focusNodes.isEmpty) return;

    final int maxIndex = widget.items.length - 1;
    int newIndex = _focusedIndex;

    // Calculate current row and column
    final currentRow = _focusedIndex ~/ _columnsCount;
    final currentCol = _focusedIndex % _columnsCount;

    print('\n📍 Current position: index=$_focusedIndex, row=$currentRow, col=$currentCol, maxIndex=$maxIndex');

    if (direction == -1) {
      // Left: Move to previous item
      newIndex = _focusedIndex - 1;
      if (newIndex >= 0 && currentCol > 0) {
        print('⬅️ Navigate left: $newIndex (valid)');
      } else {
        print('🚫 Cannot go left: newIndex=$newIndex, currentCol=$currentCol');
        newIndex = _focusedIndex; // Stay in place
      }
    } else if (direction == 1) {
      // Right: Move to next item
      newIndex = _focusedIndex + 1;
      if (newIndex <= maxIndex && currentCol < _columnsCount - 1) {
        print('➡️ Navigate right: $newIndex (valid)');
      } else {
        print('🚫 Cannot go right: newIndex=$newIndex, maxIndex=$maxIndex, currentCol=$currentCol, columnsCount=$_columnsCount');
        newIndex = _focusedIndex; // Stay in place
      }
    } else if (direction == -_columnsCount) {
      // Up: Move to previous row
      newIndex = _focusedIndex - _columnsCount;
      if (newIndex >= 0) {
        print('⬆️ Navigate up: $newIndex (valid)');
      } else {
        print('🔼 At top row, cannot go up');
        newIndex = _focusedIndex; // Stay in place
      }
    } else if (direction == _columnsCount) {
      // Down: Move to next row
      newIndex = _focusedIndex + _columnsCount;
      if (newIndex <= maxIndex) {
        print('⬇️ Navigate down: $newIndex (valid)');
      } else {
        print('🚫 Cannot go down: newIndex=$newIndex, maxIndex=$maxIndex');
        newIndex = _focusedIndex; // Stay in place
      }
    }

    // Apply the navigation if index changed
    if (newIndex != _focusedIndex) {
      print('✅ Changing focus from $_focusedIndex to $newIndex');
      setState(() => _focusedIndex = newIndex);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_focusedIndex >= 0 && _focusedIndex < _focusNodes.length && mounted) {
          print('🎯 Requesting focus for node at index: $_focusedIndex');
          _focusNodes[_focusedIndex].requestFocus();
          _scrollToFocusedItem();
        }
      });
    } else {
      print('⚠️ Navigation blocked, staying at index: $_focusedIndex\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 Print grid layout on build
    print('📊 Grid has ${widget.items.length} items, $_columnsCount columns');
    
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const _NavigateLeftIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const _NavigateRightIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const _NavigateUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const _NavigateDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const _EscapeIntent(),
      },
      child: Actions(
        actions: {
          _NavigateLeftIntent: CallbackAction<_NavigateLeftIntent>(
            onInvoke: (_) {
              print('\n🎮 ⬅️ LEFT ARROW PRESSED');
              _navigate(-1);
              return null;
            },
          ),
          _NavigateRightIntent: CallbackAction<_NavigateRightIntent>(
            onInvoke: (_) {
              print('\n🎮 ➡️ RIGHT ARROW PRESSED');
              _navigate(1);
              return null;
            },
          ),
          _NavigateUpIntent: CallbackAction<_NavigateUpIntent>(
            onInvoke: (_) {
              print('\n🎮 ⬆️ UP ARROW PRESSED');
              // If at top row, go back to search field
              if (_focusedIndex < _columnsCount) {
                print('🔼 At top row, going back to search');
                if (widget.onEscapePressed != null) {
                  widget.onEscapePressed!();
                }
              } else {
                _navigate(-_columnsCount);
              }
              return null;
            },
          ),
          _NavigateDownIntent: CallbackAction<_NavigateDownIntent>(
            onInvoke: (_) {
              print('\n🎮 ⬇️ DOWN ARROW PRESSED');
              _navigate(_columnsCount);
              return null;
            },
          ),
          _EscapeIntent: CallbackAction<_EscapeIntent>(
            onInvoke: (_) {
              print('\n🎮 ESC PRESSED');
              if (widget.onEscapePressed != null) {
                widget.onEscapePressed!();
              }
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: widget.gridFocusNode ?? _internalGridFocusNode,
          skipTraversal: false,
          child: GridView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 60),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              childAspectRatio: 1.25,
            ),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final isFocused = _focusedIndex == index;

              if (index < _focusNodes.length) {
                return Container(
                  key: _cardKeys[index],
                  child: Focus(
                    focusNode: _focusNodes[index],
                    canRequestFocus: true,
                    skipTraversal: false,
                    onFocusChange: (hasFocus) {
                      if (hasFocus && _focusedIndex != index) {
                        setState(() {
                          _focusedIndex = index;
                        });
                        print('🎯 Focus changed via callback to index: $index');
                      }
                    },
                    child: GestureDetector(
                      onTap: () {
                        if (_focusedIndex != index) {
                          setState(() {
                            _focusedIndex = index;
                          });
                          _focusNodes[index].requestFocus();
                          print('👆 Tapped item at index: $index');
                        }
                      },
                      child: VideoCardWidget(
                        summary: widget.items[index],
                        isFocused: isFocused,
                      ),
                    ),
                  ),
                );
              }

              return VideoCardWidget(
                summary: widget.items[index],
                isFocused: false,
              );
            },
          ),
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

class _EscapeIntent extends Intent {
  const _EscapeIntent();
}
