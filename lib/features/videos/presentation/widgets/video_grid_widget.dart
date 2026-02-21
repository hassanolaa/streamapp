import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/presentation/pages/video_details_page.dart';
import 'package:streamapp/features/videos/presentation/pages/channel_details_page.dart';
import 'package:streamapp/features/videos/presentation/pages/playlist_details_page.dart';
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
  late List<GlobalKey> _cardKeys;
  final int _columnsCount = 4;

  @override
  void initState() {
    super.initState();
    _cardKeys = List.generate(widget.items.length, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(VideoGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.items.length != oldWidget.items.length) {
      _cardKeys = List.generate(widget.items.length, (_) => GlobalKey());
      _focusedIndex = _focusedIndex.clamp(0, math.max(0, widget.items.length - 1));
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
    if (widget.items.isEmpty) return;

    final int maxIndex = widget.items.length - 1;
    int newIndex = _focusedIndex;

    final currentCol = _focusedIndex % _columnsCount;

    if (direction == -1) {
      // Left
      if (currentCol > 0) {
        newIndex = _focusedIndex - 1;
      }
    } else if (direction == 1) {
      // Right
      if (currentCol < _columnsCount - 1 && _focusedIndex + 1 <= maxIndex) {
        newIndex = _focusedIndex + 1;
      }
    } else if (direction == -_columnsCount) {
      // Up
      newIndex = _focusedIndex - _columnsCount;
      if (newIndex < 0) {
        newIndex = _focusedIndex; // Stay in place
      }
    } else if (direction == _columnsCount) {
      // Down
      newIndex = _focusedIndex + _columnsCount;
      if (newIndex > maxIndex) {
        newIndex = _focusedIndex; // Stay in place
      }
    }

    if (newIndex != _focusedIndex) {
      setState(() => _focusedIndex = newIndex);
      _scrollToFocusedItem();
    }
  }

  void _activateItem() {
    if (_focusedIndex < 0 || _focusedIndex >= widget.items.length) return;

    final item = widget.items[_focusedIndex];
    final data = item.data;
    String? url;
    String itemType = item.type.toLowerCase();

    if (data is StreamSummaryModel) {
      url = data.url;
      itemType = 'stream';
    } else if (data is PlaylistSummaryModel) {
      url = data.url;
      itemType = 'playlist';
    } else if (data is ChannelSummaryModel) {
      url = data.url;
      itemType = 'channel';
    }

    if (url != null) {
      print('🎯 Activating item at index: $_focusedIndex, type: $itemType, url: $url');
      _handleNavigation(context, itemType, url);
    }
  }

  void _handleNavigation(BuildContext context, String itemType, String url) {
    switch (itemType) {
      case 'stream':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoDetailsPage(videoUrl: url),
          ),
        );
        break;
      case 'channel':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChannelDetailsPage(channelUrl: url),
          ),
        );
        break;
      case 'playlist':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistDetailsPage(playlistUrl: url),
          ),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoDetailsPage(videoUrl: url),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('📊 Grid has ${widget.items.length} items, $_columnsCount columns');

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
            // At top row, go back to search
            widget.onEscapePressed?.call();
          } else {
            _navigate(-_columnsCount);
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _navigate(_columnsCount);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.select) {
          _activateItem();
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
          crossAxisCount: 4,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          childAspectRatio: 1.25,
        ),
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final isFocused = _focusedIndex == index;

          return Container(
            key: _cardKeys[index],
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _focusedIndex = index;
                });
                // Also navigate on tap
                _activateItem();
              },
              child: VideoCardWidget(
                summary: widget.items[index],
                isFocused: isFocused,
              ),
            ),
          );
        },
      ),
    );
  }
}
