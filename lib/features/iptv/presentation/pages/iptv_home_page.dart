import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/core/di/service_locator.dart';
import 'package:streamapp/features/iptv/data/models/iptv_country_model.dart';
import 'package:streamapp/features/iptv/presentation/cubit/iptv_cubit.dart';
import 'package:streamapp/features/iptv/presentation/cubit/iptv_state.dart';
import 'package:streamapp/features/iptv/presentation/pages/iptv_country_channels_page.dart';
import 'package:streamapp/features/iptv/presentation/widgets/iptv_country_card.dart';

class IptvHomePage extends StatefulWidget {
  final VoidCallback? onNavigateUp;

  const IptvHomePage({super.key, this.onNavigateUp});

  @override
  State<IptvHomePage> createState() => IptvHomePageState();
}

class IptvHomePageState extends State<IptvHomePage> {
  void requestFocus() {
    if (!mounted) return;
    _IptvHomeContentState._currentFocusNode?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IptvCubit(repository: sl())..loadCatalogs(),
      child: _IptvHomeContent(onNavigateUp: widget.onNavigateUp),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal stateful page content
// ─────────────────────────────────────────────────────────────────────────────

class _IptvHomeContent extends StatefulWidget {
  final VoidCallback? onNavigateUp;
  const _IptvHomeContent({this.onNavigateUp});

  @override
  State<_IptvHomeContent> createState() => _IptvHomeContentState();
}

class _IptvHomeContentState extends State<_IptvHomeContent> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Accessible from parent via static ref (mirrors VideosHomePage pattern)
  static FocusNode? _currentFocusNode;

  static const int _columns = 5;
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentFocusNode = _focusNode;
  }

  @override
  void dispose() {
    _currentFocusNode = null;
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Keyboard navigation ──────────────────────────────────────────────────

  KeyEventResult _handleKeyEvent(
      KeyEvent event, int totalItems, IptvCatalogsLoaded state) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final maxIndex = totalItems - 1;
    int newIndex = _focusedIndex;
    final col = _focusedIndex % _columns;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (col > 0) newIndex--;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (col < _columns - 1 && newIndex + 1 <= maxIndex) newIndex++;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (newIndex + _columns <= maxIndex) newIndex += _columns;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_focusedIndex < _columns) {
        // First row → escape up to category bar
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
        _focusNode.unfocus();
        widget.onNavigateUp?.call();
        return KeyEventResult.handled;
      }
      newIndex -= _columns;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select) {
      _openCountry(state, _focusedIndex);
      return KeyEventResult.handled;
    } else {
      return KeyEventResult.ignored;
    }

    if (newIndex != _focusedIndex && newIndex >= 0 && newIndex <= maxIndex) {
      setState(() => _focusedIndex = newIndex);
      _scrollToFocused();
    }
    return KeyEventResult.handled;
  }

  void _scrollToFocused() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final row = _focusedIndex ~/ _columns;
      const cardH = 200.0 + 16; // card height + spacing
      final offset = row * cardH;
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openCountry(IptvCatalogsLoaded state, int index) {
    final entries = state.channelsByCountry.entries.toList();
    if (index >= entries.length) return;
    final entry = entries[index];
    final country = _findCountry(state.countries, entry.key);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IptvCountryChannelsPage(
          countryCode: entry.key,
          channels: entry.value,
          country: country,
        ),
      ),
    );
  }

  IptvCountryModel? _findCountry(
      List<IptvCountryModel> countries, String code) {
    try {
      return countries.firstWhere(
        (c) => c.code.toUpperCase() == code.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IptvCubit, IptvState>(
      builder: (context, state) {
        if (state is IptvLoading) {
          return const _IptvLoadingView();
        }

        if (state is IptvError) {
          return _IptvErrorView(
            message: state.message,
            onRetry: () => context.read<IptvCubit>().loadCatalogs(),
          );
        }

        if (state is IptvCatalogsLoaded) {
          return _buildCountryGrid(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCountryGrid(BuildContext context, IptvCatalogsLoaded state) {
    final entries = state.channelsByCountry.entries.toList();
    final totalChannels =
        state.channelsByCountry.values.fold(0, (acc, l) => acc + l.length);

    if (entries.isEmpty) {
      return const Center(child: Text('No IPTV channels available.'));
    }

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (_, event) =>
          _handleKeyEvent(event, entries.length, state),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Hero header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _IptvHeroHeader(
              totalChannels: totalChannels,
              totalCountries: entries.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Country grid ─────────────────────────────────────────────
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = entries[index];
                  final country =
                      _findCountry(state.countries, entry.key);

                  return GestureDetector(
                    onTap: () {
                      setState(() => _focusedIndex = index);
                      _focusNode.requestFocus();
                      _openCountry(state, index);
                    },
                    child: IptvCountryCard(
                      countryCode: entry.key,
                      channels: entry.value,
                      country: country,
                      isFocused:
                          _focusNode.hasFocus && _focusedIndex == index,
                      onTap: () {
                        setState(() => _focusedIndex = index);
                        _focusNode.requestFocus();
                        _openCountry(state, index);
                      },
                    ),
                  );
                },
                childCount: entries.length,
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _columns,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.82,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _IptvHeroHeader extends StatelessWidget {
  final int totalChannels;
  final int totalCountries;
  const _IptvHeroHeader(
      {required this.totalChannels, required this.totalCountries});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 36, 40, 28),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Icon badge ────────────────────────────────────────────
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.live_tv_rounded,
                color: Colors.white, size: 38),
          ),

          const SizedBox(width: 22),

          // ── Text ──────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IPTV Live TV',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Browse $totalChannels channels across $totalCountries countries',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.color
                            ?.withOpacity(0.55),
                      ),
                ),
              ],
            ),
          ),

          // ── Stat chips ────────────────────────────────────────────
          Wrap(
            spacing: 10,
            children: [
              _StatChip(
                icon: Icons.public_rounded,
                label: '$totalCountries Countries',
                color: Theme.of(context).colorScheme.primary,
              ),
              _StatChip(
                icon: Icons.stream_rounded,
                label: 'Free',
                color: Colors.green,
              ),
              _StatChip(
                icon: Icons.hd_rounded,
                label: 'HD+',
                color: Colors.deepOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color),
          ),
        ],
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────

class _IptvLoadingView extends StatelessWidget {
  const _IptvLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.live_tv_rounded,
                color: Colors.white, size: 44),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading IPTV Channels…',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          // const SizedBox(height: 10),
          // Text(
          //   'Fetching channels from iptv-org',
          //   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          //         color: Theme.of(context)
          //             .textTheme
          //             .bodyMedium
          //             ?.color
          //             ?.withOpacity(0.55),
          //       ),
          // ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────

class _IptvErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _IptvErrorView(
      {required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.signal_wifi_off_rounded,
              size: 72,
              color:
                  Theme.of(context).colorScheme.error.withOpacity(0.7)),
          const SizedBox(height: 20),
          Text(
            'Failed to load IPTV channels',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
