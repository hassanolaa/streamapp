import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/core/di/service_locator.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_cubit.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_state.dart';
import 'package:streamapp/features/videos/presentation/pages/playlist_details_page.dart';
import 'package:streamapp/features/videos/presentation/widgets/video_card_widget.dart';

class ChannelDetailsPage extends StatelessWidget {
  final String channelUrl;

  const ChannelDetailsPage({super.key, required this.channelUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VideosCubit(repository: sl())..getChannelInfo(channelUrl),
      child: const _ChannelDetailsContent(),
    );
  }
}

class _ChannelDetailsContent extends StatefulWidget {
  const _ChannelDetailsContent();

  @override
  State<_ChannelDetailsContent> createState() => _ChannelDetailsContentState();
}

class _ChannelDetailsContentState extends State<_ChannelDetailsContent> {
  // 🆕 Enhanced focus management
  int _focusedSection = 0; // 0=back, 1=subscribe, 2=description, 3=tabs, 4=content
  int _selectedTabIndex = 0;
  int _focusedContentIndex = 0;
  bool _isDescriptionExpanded = false;

  final FocusNode _backButtonFocusNode = FocusNode();
  final FocusNode _subscribeButtonFocusNode = FocusNode();
  final FocusNode _descriptionButtonFocusNode = FocusNode();
  final List<FocusNode> _tabFocusNodes = [];
  late List<FocusNode> _contentFocusNodes;
  final ScrollController _contentScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // 🆕 Auto-focus back button
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _backButtonFocusNode.requestFocus();
    });
  }

  // 🆕 Scroll content to focused item
  void _scrollToContent(int index) {
    if (!_contentScrollController.hasClients) return;

    final itemWidth = 296.0;
    final targetScroll = index * itemWidth - 100;

    _contentScrollController.animateTo(
      targetScroll.clamp(
        0.0,
        _contentScrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  // 🆕 Navigation handler
  KeyEventResult _handleNavigation(KeyEvent event, ChannelInfoModel? channel) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (channel == null) return KeyEventResult.ignored;

    print('🎮 Key pressed: ${event.logicalKey} | Section: $_focusedSection');

    // Section 0: Back Button
    if (_focusedSection == 0) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        // Go to subscribe button
        setState(() => _focusedSection = 1);
        _subscribeButtonFocusNode.requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // Go to subscribe button
        setState(() => _focusedSection = 1);
        _subscribeButtonFocusNode.requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      }
    }
    // Section 1: Subscribe Button
    else if (_focusedSection == 1) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        setState(() => _focusedSection = 0);
        _backButtonFocusNode.requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() => _focusedSection = 0);
        _backButtonFocusNode.requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // Go to description or tabs
        if (channel.description != null) {
          setState(() => _focusedSection = 2);
          _descriptionButtonFocusNode.requestFocus();
        } else if (_tabFocusNodes.isNotEmpty) {
          setState(() => _focusedSection = 3);
          _tabFocusNodes[_selectedTabIndex].requestFocus();
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔔 Subscribed!'),
            duration: Duration(seconds: 2),
          ),
        );
        return KeyEventResult.handled;
      }
    }
    // Section 2: Description Button
    else if (_focusedSection == 2) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() => _focusedSection = 1);
        _subscribeButtonFocusNode.requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // Go to tabs
        if (_tabFocusNodes.isNotEmpty) {
          setState(() => _focusedSection = 3);
          _tabFocusNodes[_selectedTabIndex].requestFocus();
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        setState(() {
          _isDescriptionExpanded = !_isDescriptionExpanded;
        });
        return KeyEventResult.handled;
      }
    }
    // Section 3: Tabs
    else if (_focusedSection == 3) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (_selectedTabIndex > 0) {
          setState(() => _selectedTabIndex--);
          _tabFocusNodes[_selectedTabIndex].requestFocus();
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (_selectedTabIndex < _tabFocusNodes.length - 1) {
          setState(() => _selectedTabIndex++);
          _tabFocusNodes[_selectedTabIndex].requestFocus();
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        // Go back to description or subscribe
        if (channel.description != null) {
          setState(() => _focusedSection = 2);
          _descriptionButtonFocusNode.requestFocus();
        } else {
          setState(() => _focusedSection = 1);
          _subscribeButtonFocusNode.requestFocus();
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // Go to content
        final items = channel.tabs[_selectedTabIndex].items?.items ?? [];
        if (items.isNotEmpty) {
          setState(() {
            _focusedSection = 4;
            _focusedContentIndex = 0;
          });
          _contentFocusNodes[0].requestFocus();
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        // Tab already changes on focus, no additional action needed
        return KeyEventResult.handled;
      }
    }
    // Section 4: Content Items
    else if (_focusedSection == 4) {
      final items = channel.tabs[_selectedTabIndex].items?.items ?? [];
      final maxIndex = items.length - 1;

      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (_focusedContentIndex > 0) {
          setState(() => _focusedContentIndex--);
          _contentFocusNodes[_focusedContentIndex].requestFocus();
          _scrollToContent(_focusedContentIndex);
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (_focusedContentIndex < maxIndex) {
          setState(() => _focusedContentIndex++);
          _contentFocusNodes[_focusedContentIndex].requestFocus();
          _scrollToContent(_focusedContentIndex);
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        // Go back to tabs
        setState(() => _focusedSection = 3);
        _tabFocusNodes[_selectedTabIndex].requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        // Open item
        final item = items[_focusedContentIndex];
        if (item.type.toLowerCase() == 'playlist' && item.data.url != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaylistDetailsPage(playlistUrl: item.data.url!),
            ),
          );
        }
        return KeyEventResult.handled;
      }
    }

    // Global: Escape to go back
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _backButtonFocusNode.dispose();
    _subscribeButtonFocusNode.dispose();
    _descriptionButtonFocusNode.dispose();
    for (var node in _tabFocusNodes) {
      node.dispose();
    }
    for (var node in _contentFocusNodes) {
      node.dispose();
    }
    _contentScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideosCubit, VideosState>(
      builder: (context, state) {
        ChannelInfoModel? channel;

        if (state is VideosChannelInfoSuccess) {
          channel = state.channelInfo;

          // Initialize tab focus nodes
          if (_tabFocusNodes.isEmpty && channel.tabs.isNotEmpty) {
            _tabFocusNodes.addAll(
              List.generate(channel.tabs.length, (_) => FocusNode()),
            );
          }

          // Initialize content focus nodes
          final items = channel.tabs.isNotEmpty &&
                  channel.tabs[_selectedTabIndex].items?.items != null
              ? channel.tabs[_selectedTabIndex].items!.items!
              : [];
          _contentFocusNodes = List.generate(items.length, (_) => FocusNode());
        }

        return Focus(
          onKeyEvent: (node, event) => _handleNavigation(event, channel),
          child: Shortcuts(
            shortcuts: {
              LogicalKeySet(LogicalKeyboardKey.escape): const _BackIntent(),
            },
            child: Actions(
              actions: {
                _BackIntent: CallbackAction<_BackIntent>(
                  onInvoke: (_) {
                    Navigator.of(context).pop();
                    return null;
                  },
                ),
              },
              child: Scaffold(
                body: Builder(
                  builder: (context) {
                    if (state is VideosLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is VideosError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 80,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'error_occurred'.tr(),
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is VideosChannelInfoSuccess) {
                      return _buildChannelDetails(context, state.channelInfo);
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChannelDetails(BuildContext context, ChannelInfoModel channel) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel Banner
          _buildChannelBanner(context, channel),

          const SizedBox(height: 40),

          // Description Section
          if (channel.description != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'about'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          channel.description!.content,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: _isDescriptionExpanded ? null : 3,
                          overflow: _isDescriptionExpanded
                              ? null
                              : TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),

                        // 🆕 Focusable Description Button
                        Focus(
                          focusNode: _descriptionButtonFocusNode,
                          child: Builder(
                            builder: (context) {
                              final isFocused = _focusedSection == 2;
                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isDescriptionExpanded =
                                          !_isDescriptionExpanded;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: isFocused
                                          ? Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _isDescriptionExpanded
                                              ? 'see_less'.tr()
                                              : 'see_more'.tr(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(width: 4),
                                        AnimatedRotation(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          turns:
                                              _isDescriptionExpanded ? 0.5 : 0,
                                          child: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],

          // Tabs Section
          if (channel.tabs.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Text(
                'content'.tr(),
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            const SizedBox(height: 24),
            _buildTabs(context, channel),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildChannelBanner(BuildContext context, ChannelInfoModel channel) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth * 0.35;

    String? bannerUrl;
    if (channel.banners.isNotEmpty) {
      bannerUrl = _getHighQualityThumbnail(channel.banners);
    }

    String? avatarUrl;
    if (channel.avatars.isNotEmpty) {
      avatarUrl = _getHighQualityThumbnail(channel.avatars);
    }

    return SizedBox(
      height: bannerHeight,
      child: Stack(
        children: [
          // Background Banner
          Positioned.fill(
            child: bannerUrl != null
                ? Image.network(
                    bannerUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[850],
                    ),
                  )
                : Container(
                    color: Colors.grey[850],
                  ),
          ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.95),
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // 🆕 Back Button with Focus
          Positioned(
            left: 20,
            top: 40,
            child: Focus(
              focusNode: _backButtonFocusNode,
              child: Builder(
                builder: (context) {
                  final isFocused = _focusedSection == 0;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: isFocused
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          size: 32, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Channel Info
          Positioned(
            left: 60,
            bottom: 40,
            right: 60,
            child: Row(
              children: [
                // Channel Avatar
                if (avatarUrl != null)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[700],
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 24),

                // Channel Name and Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              channel.name ?? 'unknown_channel'.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    fontSize: 40,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                    ],
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (channel.verified ?? false) ...[
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 32,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatCount(channel.subscriberCount ?? 0)} ${'subscribers'.tr()} • ${_formatCount(channel.streamCount ?? 0)} ${'videos'.tr()}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ],
                  ),
                ),

                // 🆕 Subscribe Button with Focus
                Focus(
                  focusNode: _subscribeButtonFocusNode,
                  child: Builder(
                    builder: (context) {
                      final isFocused = _focusedSection == 1;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: isFocused
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                        ),
                        transform: Matrix4.identity()
                          ..scale(isFocused ? 1.05 : 1.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🔔 Subscribed!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.notifications_none_rounded,
                              size: 24),
                          label: Text(
                            'subscribe'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isFocused ? Colors.red : Colors.red.withOpacity(0.9),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: isFocused ? 8 : 0,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context, ChannelInfoModel channel) {
    if (channel.tabs.isEmpty) return const SizedBox.shrink();

    final selectedTab = channel.tabs[_selectedTabIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(channel.tabs.length, (index) {
              final tab = channel.tabs[index];
              final isFocused = _focusedSection == 3 && index == _selectedTabIndex;

              return Focus(
                focusNode: _tabFocusNodes[index],
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedTabIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: index == _selectedTabIndex
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: isFocused
                          ? Border.all(
                              color: Colors.white,
                              width: 3,
                            )
                          : null,
                    ),
                    child: Text(
                      tab.name ?? 'tab_${index + 1}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: index == _selectedTabIndex
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyMedium!.color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 24),

        // Tab Content
        _buildTabContent(context, selectedTab),
      ],
    );
  }

  Widget _buildTabContent(BuildContext context, dynamic tab) {
    final items = tab.items?.items ?? [];

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        child: Center(
          child: Text(
            'no_content_available'.tr(),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        controller: _contentScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 60),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isPlaylist = item.type.toLowerCase() == 'playlist';

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Focus(
              focusNode: _contentFocusNodes[index],
              child: SizedBox(
                width: 280,
                child: VideoCardWidget(
                  summary: item,
                  isFocused: _focusedSection == 4 && _focusedContentIndex == index,
                  onTap: isPlaylist
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaylistDetailsPage(
                                playlistUrl: item.data.url!,
                              ),
                            ),
                          );
                        }
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String? _getHighQualityThumbnail(List<dynamic> thumbnails) {
    if (thumbnails.isEmpty) return null;

    final sortedThumbnails = List.from(thumbnails)
      ..sort((a, b) {
        final aSize = a.width * a.height;
        final bSize = b.width * b.height;
        return bSize.compareTo(aSize);
      });

    return sortedThumbnails.first.url;
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _BackIntent extends Intent {
  const _BackIntent();
}

class _NavigateLeftIntent extends Intent {
  const _NavigateLeftIntent();
}

class _NavigateRightIntent extends Intent {
  const _NavigateRightIntent();
}
