import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/features/home/presentation/pages/home_page.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_cubit.dart';

class SearchBarWidget extends StatefulWidget {
  final FocusNode focusNode;
  final VoidCallback? onSearchSubmitted;
  final VoidCallback? onEscapePressed;
  final TextEditingController? controller;

  const SearchBarWidget({
    super.key,
    required this.focusNode,
    this.onSearchSubmitted,
    this.onEscapePressed,
    this.controller,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  late FocusNode _textFieldFocusNode; // 🆕 Separate focus node for TextField
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _textFieldFocusNode = FocusNode(); // 🆕
    
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _textFieldFocusNode.dispose(); // 🆕
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.focusNode.hasFocus;
    });

    // 🆕 When SearchBar gets focus, automatically focus the TextField
    if (_isFocused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _textFieldFocusNode.requestFocus();
      });
    }
  }

  void _performSearch() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      context.read<VideosCubit>().searchVideos(query,provider: globalSearchProvidersSelector());

      if (widget.onSearchSubmitted != null) {
        widget.onSearchSubmitted!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: _isFocused
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              )
            : null,
      ),
      child: Focus(
        focusNode: widget.focusNode,
        // 🆕 Only handle Escape and Arrow keys here, let TextField handle text input
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            // Only intercept Escape and navigation keys
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              if (widget.onEscapePressed != null) {
                widget.onEscapePressed!();
              }
              return KeyEventResult.handled;
            }
            // Let arrow keys bubble up for navigation
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.arrowUp ||
                event.logicalKey == LogicalKeyboardKey.arrowDown) {
              return KeyEventResult.ignored; // Let parent handle
            }
          }
          return KeyEventResult.ignored; // Let TextField handle all other keys
        },
        child: TextField(
          controller: _controller,
          focusNode: _textFieldFocusNode, // 🆕 Use separate focus node
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'search_hint'.tr(),
            hintStyle: Theme.of(context).textTheme.bodyMedium,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Theme.of(context).textTheme.bodyMedium!.color,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (_) => _performSearch(),
        ),
      ),
    );
  }
}
