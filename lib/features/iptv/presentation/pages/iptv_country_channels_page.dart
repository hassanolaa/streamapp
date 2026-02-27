import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streamapp/features/iptv/data/models/iptv_country_model.dart';
import 'package:streamapp/features/iptv/data/models/iptv_enriched_channel.dart';
import 'package:streamapp/features/iptv/presentation/pages/iptv_player_page.dart';
import 'package:streamapp/features/iptv/presentation/widgets/iptv_channel_card.dart';

class IptvCountryChannelsPage extends StatefulWidget {
  final String countryCode;
  final List<IptvEnrichedChannel> channels;
  final IptvCountryModel? country;

  const IptvCountryChannelsPage({
    super.key,
    required this.countryCode,
    required this.channels,
    this.country,
  });

  @override
  State<IptvCountryChannelsPage> createState() =>
      _IptvCountryChannelsPageState();
}

class _IptvCountryChannelsPageState extends State<IptvCountryChannelsPage> {
  final FocusNode _gridFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  int _focusedIndex = 0;
  String _selectedCategory = 'all';
  bool _showOnlyWithStream = false;

  static const int _columns = 5;

  List<IptvEnrichedChannel> get _filteredChannels {
    var list = widget.channels;

    if (_showOnlyWithStream) {
      list = list.where((c) => c.streamUrl != null).toList();
    }

    if (_selectedCategory != 'all') {
      list = list
          .where((c) => c.categories.contains(_selectedCategory))
          .toList();
    }

    return list;
  }

  /// Collect unique categories from the country's channels.
  List<String> get _availableCategories {
    final cats = <String>{'all'};
    for (final ch in widget.channels) {
      cats.addAll(ch.categories);
    }
    return cats.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gridFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _gridFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _navigate(int direction) {
    final list = _filteredChannels;
    if (list.isEmpty) return;

    final maxIndex = list.length - 1;
    int newIndex = _focusedIndex;
    final col = _focusedIndex % _columns;

    if (direction == -1) {
      // left
      if (col > 0) newIndex--;
    } else if (direction == 1) {
      // right
      if (col < _columns - 1 && _focusedIndex + 1 <= maxIndex) newIndex++;
    } else if (direction == -_columns) {
      // up
      if (_focusedIndex >= _columns) newIndex -= _columns;
    } else if (direction == _columns) {
      // down
      if (_focusedIndex + _columns <= maxIndex) newIndex += _columns;
    }

    if (newIndex != _focusedIndex) {
      setState(() => _focusedIndex = newIndex.clamp(0, maxIndex));
      _scrollToFocused();
    }
  }

  void _scrollToFocused() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final row = _focusedIndex ~/ _columns;
      // Rough item height estimate: account for card aspect ratio + spacing
      final itemH = ((MediaQuery.of(context).size.width - 120) / _columns) *
              1.4 + // childAspectRatio inverse
          20; // crossAxis spacing
      final offset = row * itemH;
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openChannel(IptvEnrichedChannel channel) {
    if (channel.streamUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No stream available for ${channel.name}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IptvPlayerPage(channel: channel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flag = widget.country?.flag ?? '🌍';
    final name = widget.country?.name ?? widget.countryCode;
    final filtered = _filteredChannels;

    return Scaffold(
      body: Column(
        children: [
          // ── Top header bar ──────────────────────────────────────────
          _buildHeader(context, flag, name),

          // ── Filter row ──────────────────────────────────────────────
          _buildFilterRow(context),

          // ── Results count ───────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filtered.length} channel${filtered.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.55),
                      ),
                ),
                if (_showOnlyWithStream) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.green.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_rounded,
                            size: 11, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Streams only',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Grid ────────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _buildEmpty(context)
                : _buildGrid(context, filtered),
          ),
        ],
      ),
    );
  }

  // ---------- widgets ----------

  Widget _buildHeader(BuildContext context, String flag, String name) {
    return Container(
      padding:
          const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.18),
            Theme.of(context).colorScheme.secondary.withOpacity(0.08),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Back button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withOpacity(0.2),
                  ),
                ),
                child:
                    const Icon(Icons.arrow_back_rounded, size: 24),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Flag + title
          Text(flag, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${widget.channels.length} channels',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.55),
                      ),
                ),
              ],
            ),
          ),

          // Stream-only toggle
          _StreamToggleChip(
            value: _showOnlyWithStream,
            onChanged: (v) {
              setState(() {
                _showOnlyWithStream = v;
                _focusedIndex = 0;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    final cats = _availableCategories;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = cats[i];
          final selected = _selectedCategory == cat;
          return FilterChip(
            label: Text(cat == 'all' ? 'All' : cat.replaceAll('_', ' ')),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedCategory = cat;
                _focusedIndex = 0;
              });
              _gridFocusNode.requestFocus();
            },
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedColor: Theme.of(context).colorScheme.primaryContainer,
            checkmarkColor:
                Theme.of(context).colorScheme.onPrimaryContainer,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
              color: selected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            side: BorderSide(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withOpacity(0.3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(
      BuildContext context, List<IptvEnrichedChannel> channels) {
    return Focus(
      focusNode: _gridFocusNode,
      skipTraversal: true,
      onKeyEvent: (_, event) {
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
          if (_focusedIndex < _columns) {
            // already at top row → go back
            Navigator.of(context).pop();
          } else {
            _navigate(-_columns);
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _navigate(_columns);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.select) {
          if (_focusedIndex < channels.length) {
            _openChannel(channels[_focusedIndex]);
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.escape ||
            event.logicalKey == LogicalKeyboardKey.goBack) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: GridView.builder(
        controller: _scrollController,
        padding:
            const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _columns,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.78,
        ),
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];
          final isFocused =
              _gridFocusNode.hasFocus && _focusedIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() => _focusedIndex = index);
              _gridFocusNode.requestFocus();
              _openChannel(channel);
            },
            child: IptvChannelCard(
              channel: channel,
              isFocused: isFocused,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 72,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No channels match the selected filters',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() {
              _selectedCategory = 'all';
              _showOnlyWithStream = false;
              _focusedIndex = 0;
            }),
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stream toggle chip
// ---------------------------------------------------------------------------

class _StreamToggleChip extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _StreamToggleChip(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: value
              ? Colors.green.withOpacity(0.15)
              : Theme.of(context).colorScheme.surface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value
                ? Colors.green.withOpacity(0.5)
                : Theme.of(context)
                    .colorScheme
                    .outline
                    .withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              size: 15,
              color: value
                  ? Colors.green
                  : Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.5),
            ),
            const SizedBox(width: 6),
            Text(
              value ? 'Live streams' : 'All channels',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value
                    ? Colors.green
                    : Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
