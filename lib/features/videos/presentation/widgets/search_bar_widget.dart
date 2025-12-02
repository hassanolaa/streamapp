import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_cubit.dart';

class SearchBarWidget extends StatefulWidget {
  final FocusNode focusNode;

  const SearchBarWidget({super.key, required this.focusNode});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  String _selectedProvider = 'youtube';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      context.read<VideosCubit>().searchVideos(_selectedProvider, query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Provider Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: _selectedProvider,
            underline: const SizedBox.shrink(),
            dropdownColor: Theme.of(context).colorScheme.surface,
            style: Theme.of(context).textTheme.bodyLarge,
            items: ['youtube', 'peertube', 'soundcloud']
                .map((provider) => DropdownMenuItem(
                      value: provider,
                      child: Text(provider),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedProvider = value);
              }
            },
          ),
        ),

        const SizedBox(width: 16),

        // Search Input
        Expanded(
          child: Focus(
            focusNode: widget.focusNode,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                _performSearch();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: _controller,
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
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Search Button
        ElevatedButton.icon(
          onPressed: _performSearch,
          icon: const Icon(Icons.search_rounded),
          label: Text('search'.tr()),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
