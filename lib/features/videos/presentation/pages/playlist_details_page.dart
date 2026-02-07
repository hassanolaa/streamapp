import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/core/di/service_locator.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_cubit.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_state.dart';
import 'package:streamapp/features/videos/presentation/pages/channel_details_page.dart';
import 'package:streamapp/features/videos/presentation/widgets/video_card_widget.dart';

class PlaylistDetailsPage extends StatelessWidget {
  final String playlistUrl;

  const PlaylistDetailsPage({super.key, required this.playlistUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VideosCubit(repository: sl())..getPlaylistInfo(playlistUrl),
      child: const _PlaylistDetailsContent(),
    );
  }
}

class _PlaylistDetailsContent extends StatefulWidget {
  const _PlaylistDetailsContent();

  @override
  State<_PlaylistDetailsContent> createState() =>
      _PlaylistDetailsContentState();
}

class _PlaylistDetailsContentState extends State<_PlaylistDetailsContent> {
  // 🆕 Enhanced focus management
  int _focusedSection = 0; // 0=back, 1=uploader, 2=playAll, 3=videos
  int _focusedVideoIndex = 0;

  final FocusNode _backButtonFocusNode = FocusNode();
  final FocusNode _uploaderButtonFocusNode = FocusNode();
  final FocusNode _playAllButtonFocusNode = FocusNode();
  late List<FocusNode> _videoFocusNodes;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _videosScrollController = ScrollController();

  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // 🆕 Auto-focus back button
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _backButtonFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _backButtonFocusNode.dispose();
    _uploaderButtonFocusNode.dispose();
    _playAllButtonFocusNode.dispose();
    for (var node in _videoFocusNodes) {
      node.dispose();
    }
    _scrollController.dispose();
    _videosScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final state = context.read<VideosCubit>().state;
      if (state is VideosPlaylistInfoSuccess) {
        final playlist = state.playlistInfo;
        if (playlist.items?.nextPageToken != null) {
          // TODO: Load more playlist items
        }
      }
    }
  }

  // 🆕 Scroll videos to focused item
  void _scrollToVideo(int index) {
    if (!_videosScrollController.hasClients) return;

    final itemWidth = 296.0;
    final targetScroll = index * itemWidth - 100;

    _videosScrollController.animateTo(
      targetScroll.clamp(
        0.0,
        _videosScrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  // 🆕 Navigation handler
  KeyEventResult _handleNavigation(KeyEvent event, PlaylistInfoModel? playlist) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (playlist == null) return KeyEventResult.ignored;

    print('🎮 Key pressed: ${event.logicalKey} | Section: $_focusedSection');

    // Section 0: Back Button
    if (_focusedSection == 0) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        // Go to uploader button
        if (playlist.uploader != null) {
          setState(() => _focusedSection = 1);
          _uploaderButtonFocusNode.requestFocus();
        } else {
          setState(() => _focusedSection = 2);
          _playAllButtonFocusNode.requestFocus();
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // Go to uploader or play all
        if (playlist.uploader != null) {
          setState(() => _focusedSection = 1);
          _uploaderButtonFocusNode.requestFocus();
        } else {
          setState(() => _focusedSection = 2);
          _playAllButtonFocusNode.requestFocus();
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      }
    }
    // Section 1: Uploader Button
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
        setState(() => _focusedSection = 2);
        _playAllButtonFocusNode.requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        if (playlist.uploader?.url != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ChannelDetailsPage(channelUrl: playlist.uploader!.url!),
            ),
          );
        }
        return KeyEventResult.handled;
      }
    }
    // Section 2: Play All Button
    else if (_focusedSection == 2) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        // Go to uploader or back
        if (playlist.uploader != null) {
          setState(() => _focusedSection = 1);
          _uploaderButtonFocusNode.requestFocus();
        } else {
          setState(() => _focusedSection = 0);
          _backButtonFocusNode.requestFocus();
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // Go to videos
        final items = playlist.items?.items ?? [];
        if (items.isNotEmpty) {
          setState(() {
            _focusedSection = 3;
            _focusedVideoIndex = 0;
          });
          _videoFocusNodes[0].requestFocus();
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('▶️ Playing all videos'),
            duration: Duration(seconds: 2),
          ),
        );
        return KeyEventResult.handled;
      }
    }
    // Section 3: Videos
    else if (_focusedSection == 3) {
      final items = playlist.items?.items ?? [];
      final maxIndex = items.length - 1;

      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (_focusedVideoIndex > 0) {
          setState(() => _focusedVideoIndex--);
          _videoFocusNodes[_focusedVideoIndex].requestFocus();
          _scrollToVideo(_focusedVideoIndex);
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (_focusedVideoIndex < maxIndex) {
          setState(() => _focusedVideoIndex++);
          _videoFocusNodes[_focusedVideoIndex].requestFocus();
          _scrollToVideo(_focusedVideoIndex);
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        // Go back to play all
        setState(() => _focusedSection = 2);
        _playAllButtonFocusNode.requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        // Open video/playlist
        final item = items[_focusedVideoIndex];
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
  Widget build(BuildContext context) {
    return BlocBuilder<VideosCubit, VideosState>(
      builder: (context, state) {
        PlaylistInfoModel? playlist;

        if (state is VideosPlaylistInfoSuccess) {
          playlist = state.playlistInfo;

          // Initialize video focus nodes
          final items = playlist.items?.items ?? [];
          _videoFocusNodes = List.generate(items.length, (_) => FocusNode());
        }

        return Focus(
          onKeyEvent: (node, event) => _handleNavigation(event, playlist),
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

                    if (state is VideosPlaylistInfoSuccess) {
                      return _buildPlaylistDetails(
                          context, state.playlistInfo);
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

  Widget _buildPlaylistDetails(
      BuildContext context, PlaylistInfoModel playlist) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Playlist Banner
          _buildPlaylistBanner(context, playlist),

          const SizedBox(height: 40),

          // Playlist Items Section
          if (playlist.items?.items.isNotEmpty ?? false) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Text(
                'playlist_videos'.tr(),
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            const SizedBox(height: 24),
            _buildPlaylistItems(context, playlist),
            const SizedBox(height: 40),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
              child: Center(
                child: Text(
                  'no_videos_in_playlist'.tr(),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaylistBanner(
      BuildContext context, PlaylistInfoModel playlist) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth * 0.4;

    String? bannerUrl;
    if (playlist.banners.isNotEmpty) {
      bannerUrl = _getHighQualityThumbnail(playlist.banners);
    } else if (playlist.thumbnails.isNotEmpty) {
      bannerUrl = _getHighQualityThumbnail(playlist.thumbnails);
    }

    return SizedBox(
      height: bannerHeight,
      child: Stack(
        children: [
          // Background Image
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
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                  ),
          ),

          // Gradient Overlays
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
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

          // Playlist Info
          Positioned(
            left: 60,
            bottom: 40,
            right: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Playlist Type Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.playlist_play_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'playlist'.tr().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Playlist Title
                Text(
                  playlist.name ?? 'untitled_playlist'.tr(),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
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

                const SizedBox(height: 12),

                // 🆕 Uploader Info with Focus
                if (playlist.uploader != null)
                  Focus(
                    focusNode: _uploaderButtonFocusNode,
                    child: Builder(
                      builder: (context) {
                        final isFocused = _focusedSection == 1;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: isFocused
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                          child: InkWell(
                            onTap: () {
                              if (playlist.uploader?.url != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChannelDetailsPage(
                                      channelUrl: playlist.uploader!.url!,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (playlist
                                        .uploader!.thumbnails.isNotEmpty) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.network(
                                          _getHighQualityThumbnail(playlist
                                                  .uploader!.thumbnails) ??
                                              playlist.uploader!.thumbnails
                                                  .first.url,
                                          width: 32,
                                          height: 32,
                                          fit: BoxFit.cover,
                                          filterQuality: FilterQuality.high,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            width: 32,
                                            height: 32,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      playlist.uploader!.name ??
                                          'unknown_channel'.tr(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                Colors.white.withOpacity(0.5),
                                          ),
                                    ),
                                    if (playlist.uploader!.verified ??
                                        false) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.verified,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                // 🆕 Play All Button with Focus
                Focus(
                  focusNode: _playAllButtonFocusNode,
                  child: Builder(
                    builder: (context) {
                      final isFocused = _focusedSection == 2;
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
                                content: Text('▶️ Playing all videos'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 28),
                          label: Text(
                            'play_all'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFocused
                                ? Colors.white
                                : Colors.white.withOpacity(0.9),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
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

  Widget _buildPlaylistItems(BuildContext context, PlaylistInfoModel playlist) {
    final items = playlist.items?.items ?? [];

    return SizedBox(
      height: 220,
      child: ListView.builder(
        controller: _videosScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 60),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Focus(
              focusNode: _videoFocusNodes[index],
              child: SizedBox(
                width: 280,
                child: VideoCardWidget(
                  summary: items[index],
                  isFocused: _focusedSection == 3 && _focusedVideoIndex == index,
                  onTap: items[index].type.toLowerCase() == 'playlist' &&
                          items[index].data.url != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaylistDetailsPage(
                                  playlistUrl: items[index].data.url!),
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
}

class _BackIntent extends Intent {
  const _BackIntent();
}
