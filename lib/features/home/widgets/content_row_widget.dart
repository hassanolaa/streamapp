import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streamapp/features/home/widgets/content_card_widget.dart';

class ContentRowWidget extends StatefulWidget {
  final String title;

  const ContentRowWidget({super.key, required this.title});

  @override
  State<ContentRowWidget> createState() => _ContentRowWidgetState();
}

class _ContentRowWidgetState extends State<ContentRowWidget> {
  final ScrollController _scrollController = ScrollController();
  int _focusedIndex = 0;
  final List<FocusNode> _focusNodes = List.generate(10, (_) => FocusNode());

  @override
  void dispose() {
    _scrollController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _scrollToIndex(int index) {
    final itemWidth = 240.0;
    final offset = index * (itemWidth + 16);
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
      },
      child: Actions(
        actions: {
          _NavigateLeftIntent: CallbackAction<_NavigateLeftIntent>(
            onInvoke: (_) {
              if (_focusedIndex > 0) {
                setState(() => _focusedIndex--);
                _focusNodes[_focusedIndex].requestFocus();
                _scrollToIndex(_focusedIndex);
              }
              return null;
            },
          ),
          _NavigateRightIntent: CallbackAction<_NavigateRightIntent>(
            onInvoke: (_) {
              if (_focusedIndex < 9) {
                setState(() => _focusedIndex++);
                _focusNodes[_focusedIndex].requestFocus();
                _scrollToIndex(_focusedIndex);
              }
              return null;
            },
          ),
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 60),
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Focus(
                      focusNode: _focusNodes[index],
                      child: ContentCardWidget(
                        imageUrl: 'https://picsum.photos/240/180?random=$index',
                        isFocused: _focusedIndex == index,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
