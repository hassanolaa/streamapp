import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/core/di/service_locator.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/data/services/recommendation_service.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_cubit.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_state.dart';
import 'package:streamapp/features/videos/presentation/pages/channel_details_page.dart';
import 'package:streamapp/features/videos/presentation/widgets/video_card_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoDetailsPage extends StatelessWidget {
  final String videoUrl;

  const VideoDetailsPage({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VideosCubit(repository: sl())..getStreamInfo(videoUrl),
      child: _VideoDetailsContent(videoUrl: videoUrl),
    );
  }
}

class _VideoDetailsContent extends StatefulWidget {
  final String videoUrl;

  const _VideoDetailsContent({required this.videoUrl});

  @override
  State<_VideoDetailsContent> createState() => _VideoDetailsContentState();
}

class _VideoDetailsContentState extends State<_VideoDetailsContent> {
  // 🆕 Enhanced focus management
  int _focusedSection = 0; // 0=back, 1=channel, 2=buttons, 3=description, 4=recommendations
  int _focusedButtonIndex = 0; // 0=Play, 1=Favorites
  int _focusedRecommendationIndex = 0;

  final FocusNode _backButtonFocusNode = FocusNode();
  final FocusNode _channelButtonFocusNode = FocusNode();
  final List<FocusNode> _buttonFocusNodes = List.generate(2, (_) => FocusNode());
  final FocusNode _descriptionButtonFocusNode = FocusNode();
  late List<FocusNode> _recommendationFocusNodes;
  final ScrollController _recommendationsScrollController = ScrollController();

  bool _isDescriptionExpanded = false;

  // Watch tracking variables
  StreamInfoModel? _streamInfo;
  int _watchedSeconds = 0;
  Timer? _watchTimer;
  bool _isPlaying = false;
  DateTime? _pageOpenedAt;

  @override
  void initState() {
    super.initState();
    _pageOpenedAt = DateTime.now();
    _startWatchTimer();

    // 🆕 Auto-focus back button
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _backButtonFocusNode.requestFocus();
    });
  }

  void _startWatchTimer() {
    _watchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPlaying && mounted) {
        setState(() => _watchedSeconds++);
      }
    });
    print('⏱️ Watch timer started');
  }

  void _onVideoPlay() {
    setState(() => _isPlaying = true);
    print('▶️ Video playing - tracking watch time');
  }

  void _onVideoPause() {
    setState(() => _isPlaying = false);
    print('⏸️ Video paused at ${_watchedSeconds}s');
  }

  Future<void> _saveWatchHistory() async {
    if (_streamInfo == null) {
      print('⚠️ Stream info not loaded, skipping watch history');
      return;
    }

    final timeOnPage = DateTime.now().difference(_pageOpenedAt!).inSeconds;

    if (_watchedSeconds < 10 && timeOnPage < 30) {
      print('⚠️ Not saving: watched ${_watchedSeconds}s, on page ${timeOnPage}s');
      return;
    }

    try {
      final recommendationService = sl<RecommendationService>();

      print('💾 Saving watch history: ${_streamInfo!.name}');
      print('   Watched: ${_watchedSeconds}s / ${_streamInfo!.duration ?? 0}s');

      await recommendationService.addToWatchHistory(
        widget.videoUrl,
        _streamInfo!.name,
        _watchedSeconds,
        _streamInfo!.duration ?? 0,
        uploaderName: _streamInfo!.uploader?.name,
        uploaderUrl: _streamInfo!.uploader?.url,
        tags: _streamInfo!.tags,
      );

      await recommendationService.feedFromStreamInfo(_streamInfo!);

      print('✅ Watch history saved + ${_streamInfo!.recommendations.length} recommendations fed');
    } catch (e) {
      print('❌ Failed to save watch history: $e');
    }
  }

  void _scrollToRecommendation(int index) {
    if (!_recommendationsScrollController.hasClients) return;

    final itemWidth = 296.0;
    final targetScroll = index * itemWidth - 100;

    _recommendationsScrollController.animateTo(
      targetScroll.clamp(
        0.0,
        _recommendationsScrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  // 🆕 Fixed navigation handler
  // 🆕 Fixed navigation handler
KeyEventResult _handleNavigation(KeyEvent event) {
  if (event is! KeyDownEvent) return KeyEventResult.ignored;

  print('🎮 Key pressed: ${event.logicalKey} | Section: $_focusedSection');

  // Section 0: Back Button
  if (_focusedSection == 0) {
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      // Go to channel button
      setState(() => _focusedSection = 1);
      _channelButtonFocusNode.requestFocus();
      print('→ Moving to Channel Button');
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      // 🆕 Go to Channel Button (not Play button)
      setState(() => _focusedSection = 1);
      _channelButtonFocusNode.requestFocus();
      print('↓ Moving to Channel Button');
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      // Go back
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
  }
  // Section 1: Channel Button
  else if (_focusedSection == 1) {
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      // Go to back button
      setState(() => _focusedSection = 0);
      _backButtonFocusNode.requestFocus();
      print('← Moving to Back Button');
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      // 🆕 Go to back button
      setState(() => _focusedSection = 0);
      _backButtonFocusNode.requestFocus();
      print('↑ Moving to Back Button');
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      // Go to Play button
      setState(() {
        _focusedSection = 2;
        _focusedButtonIndex = 0;
      });
      _buttonFocusNodes[0].requestFocus();
      print('↓ Moving to Play Button');
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      // Open channel page
      if (_streamInfo?.uploader?.url != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChannelDetailsPage(
              channelUrl: _streamInfo!.uploader!.url!,
            ),
          ),
        );
      }
      return KeyEventResult.handled;
    }
  }
  // Section 2: Action Buttons (Play/Favorites)
  else if (_focusedSection == 2) {
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_focusedButtonIndex > 0) {
        setState(() => _focusedButtonIndex--);
        _buttonFocusNodes[_focusedButtonIndex].requestFocus();
        print('← Moving to Play Button');
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_focusedButtonIndex < 1) {
        setState(() => _focusedButtonIndex++);
        _buttonFocusNodes[_focusedButtonIndex].requestFocus();
        print('→ Moving to Favorites Button');
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      // 🆕 Go to channel button
      setState(() => _focusedSection = 1);
      _channelButtonFocusNode.requestFocus();
      print('↑ Moving to Channel Button');
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      // Go to description button or recommendations
      if (_streamInfo?.description != null) {
        setState(() => _focusedSection = 3);
        _descriptionButtonFocusNode.requestFocus();
        print('↓ Moving to Description Button');
      } else if (_streamInfo?.recommendations.isNotEmpty ?? false) {
        setState(() {
          _focusedSection = 4;
          _focusedRecommendationIndex = 0;
        });
        _recommendationFocusNodes[0].requestFocus();
        print('↓ Moving to Recommendations');
      }
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      // Activate the focused button
      if (_focusedButtonIndex == 0) {
        // Play button
        _onVideoPlay();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('▶️ Video playing (watch time tracking started)'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (_focusedButtonIndex == 1) {
        // Favorites button
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❤️ Added to favorites'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return KeyEventResult.handled;
    }
  }
  // Section 3: Description Button (See More/Less)
  else if (_focusedSection == 3) {
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      // Go back to buttons
      setState(() => _focusedSection = 2);
      _buttonFocusNodes[_focusedButtonIndex].requestFocus();
      print('↑ Moving to Action Buttons');
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      // Go to recommendations
      if (_streamInfo?.recommendations.isNotEmpty ?? false) {
        setState(() {
          _focusedSection = 4;
          _focusedRecommendationIndex = 0;
        });
        _recommendationFocusNodes[0].requestFocus();
        print('↓ Moving to Recommendations');
      }
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      // Toggle description
      setState(() {
        _isDescriptionExpanded = !_isDescriptionExpanded;
      });
      print('Toggle description: ${_isDescriptionExpanded ? "Expanded" : "Collapsed"}');
      return KeyEventResult.handled;
    }
  }
  // Section 4: Recommendations
  else if (_focusedSection == 4) {
    final maxIndex = (_streamInfo?.recommendations.length ?? 0) - 1;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_focusedRecommendationIndex > 0) {
        setState(() => _focusedRecommendationIndex--);
        _recommendationFocusNodes[_focusedRecommendationIndex].requestFocus();
        _scrollToRecommendation(_focusedRecommendationIndex);
        print('← Moving to recommendation $_focusedRecommendationIndex');
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_focusedRecommendationIndex < maxIndex) {
        setState(() => _focusedRecommendationIndex++);
        _recommendationFocusNodes[_focusedRecommendationIndex].requestFocus();
        _scrollToRecommendation(_focusedRecommendationIndex);
        print('→ Moving to recommendation $_focusedRecommendationIndex');
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      // Go back to description or buttons
      if (_streamInfo?.description != null) {
        setState(() => _focusedSection = 3);
        _descriptionButtonFocusNode.requestFocus();
        print('↑ Moving to Description Button');
      } else {
        setState(() => _focusedSection = 2);
        _buttonFocusNodes[_focusedButtonIndex].requestFocus();
        print('↑ Moving to Action Buttons');
      }
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      // Open recommendation
      SummaryModel rec =
          _streamInfo!.recommendations[_focusedRecommendationIndex];
      if (rec.data != null && rec.data!.url != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoDetailsPage(videoUrl: rec.data!.url!),
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
    _watchTimer?.cancel();
    _saveWatchHistory();

    _backButtonFocusNode.dispose();
    _channelButtonFocusNode.dispose();
    _descriptionButtonFocusNode.dispose();
    for (var node in _buttonFocusNodes) {
      node.dispose();
    }
    for (var node in _recommendationFocusNodes) {
      node.dispose();
    }
    _recommendationsScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) => _handleNavigation(event),
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
            body: BlocBuilder<VideosCubit, VideosState>(
              builder: (context, state) {
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

                if (state is VideosStreamInfoSuccess) {
                  _streamInfo = state.streamInfo;

                  _recommendationFocusNodes = List.generate(
                    state.streamInfo.recommendations.length,
                    (_) => FocusNode(),
                  );
                  return _buildVideoDetails(context, state.streamInfo);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoDetails(BuildContext context, StreamInfoModel info) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Banner with Video Info
          _buildHeroBanner(context, info),

          const SizedBox(height: 40),

          // Watch Time Display (Debug)
          if (_watchedSeconds > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Watched: ${_formatDuration(_watchedSeconds)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Video Metadata Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                if (info.ageLimit != null && info.ageLimit! > 0)
                  _buildInfoChip(
                    context,
                    Icons.warning_amber_rounded,
                    'age_limit'.tr(),
                    '${info.ageLimit}+',
                    Colors.orange,
                  ),
                if (info.language != null)
                  _buildInfoChip(
                    context,
                    Icons.language_rounded,
                    'language'.tr(),
                    info.language!.toUpperCase(),
                    Theme.of(context).colorScheme.primary,
                  ),
                if (info.category != null)
                  _buildInfoChip(
                    context,
                    Icons.category_rounded,
                    'category'.tr(),
                    info.category!,
                    Theme.of(context).colorScheme.secondary,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Description Section
          if (info.description != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'description'.tr(),
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
                        _buildDescription(
                          context,
                          info.description!,
                          maxLines: _isDescriptionExpanded ? null : 3,
                        ),
                        const SizedBox(height: 12),
                        
                        // 🆕 Focusable See More/Less button
                        Focus(
                          focusNode: _descriptionButtonFocusNode,
                          child: Builder(
                            builder: (context) {
                              final isFocused = _focusedSection == 3;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: isFocused
                                      ? Border.all(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isDescriptionExpanded = !_isDescriptionExpanded;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
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
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          _isDescriptionExpanded
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons.keyboard_arrow_down_rounded,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 20,
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

          // Similar Videos Section
          if (info.recommendations.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Text(
                'similar_videos'.tr(),
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            const SizedBox(height: 24),
            _buildRecommendations(context, info),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, StreamInfoModel info) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth * 0.5;

    final thumbnailUrl = _getHighQualityThumbnail(info.thumbnails);

    return SizedBox(
      height: bannerHeight,
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: thumbnailUrl != null
                ? Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[850],
                    ),
                  )
                : Container(color: Colors.grey[850]),
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
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3),
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),

          // 🆕 Back Button (Top Left)
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

          // Content Overlay
          Positioned(
            left: 60,
            bottom: 60,
            right: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Video Title
                Text(
                  info.name ?? 'untitled'.tr(),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 48,
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

                // 🆕 Focusable Channel Button
                Focus(
                  focusNode: _channelButtonFocusNode,
                  child: Builder(
                    builder: (context) {
                      final isFocused = _focusedSection == 1;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: isFocused
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                        ),
                        child: InkWell(
                          onTap: () {
                            if (info.uploader?.url != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChannelDetailsPage(
                                    channelUrl: info.uploader!.url!,
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
                                  if (info.uploader?.thumbnails.isNotEmpty ??
                                      false) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        _getHighQualityThumbnail(
                                                info.uploader!.thumbnails) ??
                                            info.uploader!.thumbnails.first.url,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        filterQuality: FilterQuality.high,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 40,
                                          height: 40,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  Text(
                                    info.uploader?.name ?? 'unknown_channel'.tr(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                          decorationColor:
                                              Colors.white.withOpacity(0.5),
                                        ),
                                  ),
                                  if (info.uploader?.verified ?? false) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 16,
                                  ),
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

                // Video Stats
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    if (info.type != null)
                      _buildStatChip(
                        context,
                        Icons.videocam_rounded,
                        info.type!,
                      ),
                    _buildStatChip(
                      context,
                      Icons.schedule_rounded,
                      _formatDuration(info.duration ?? 0),
                    ),
                    _buildStatChip(
                      context,
                      Icons.visibility_rounded,
                      '${_formatViews(info.viewCount ?? 0)} views',
                    ),
                    _buildStatChip(
                      context,
                      Icons.thumb_up_rounded,
                      _formatCount(info.likeCount ?? 0),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Focus(
                      focusNode: _buttonFocusNodes[0],
                      child: _PrimaryButton(
                        icon: Icons.play_arrow_rounded,
                        label: 'play'.tr(),
                        isFocused:
                            _focusedSection == 2 && _focusedButtonIndex == 0,
                        onPressed: () {
                          _onVideoPlay();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  '▶️ Video playing (watch time tracking started)'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Focus(
                      focusNode: _buttonFocusNodes[1],
                      child: _SecondaryButton(
                        icon: Icons.favorite_border_rounded,
                        label: 'add_to_favorites'.tr(),
                        isFocused:
                            _focusedSection == 2 && _focusedButtonIndex == 1,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('❤️ Added to favorites'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildStatChip(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .color
                          ?.withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(
    BuildContext context,
    dynamic description, {
    int? maxLines,
  }) {
    final String content = description.content ?? '';

    String cleanedContent = content
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\n\n+'), '\n\n')
        .trim();

    final urlRegex = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );

    final matches = urlRegex.allMatches(cleanedContent);

    if (matches.isEmpty) {
      return Text(
        cleanedContent,
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
      );
    }

    final spans = <TextSpan>[];
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: cleanedContent.substring(lastMatchEnd, match.start),
          style: Theme.of(context).textTheme.bodyMedium,
        ));
      }

      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < cleanedContent.length) {
      spans.add(TextSpan(
        text: cleanedContent.substring(lastMatchEnd),
        style: Theme.of(context).textTheme.bodyMedium,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }

  Widget _buildRecommendations(BuildContext context, StreamInfoModel info) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        controller: _recommendationsScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 60),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: info.recommendations.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Focus(
              focusNode: _recommendationFocusNodes[index],
              child: SizedBox(
                width: 280,
                child: VideoCardWidget(
                  summary: info.recommendations[index],
                  isFocused: _focusedSection == 4 &&
                      _focusedRecommendationIndex == index,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m ${secs}s';
    }
  }
}

// Primary Button (Play)
class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isFocused;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.isFocused,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: isFocused ? Border.all(color: Colors.white, width: 3) : null,
      ),
      transform: Matrix4.identity()..scale(isFocused ? 1.05 : 1.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isFocused ? Colors.white : Colors.white.withOpacity(0.9),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: isFocused ? 8 : 0,
        ),
      ),
    );
  }
}

// Secondary Button (Add to Favorites)
class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isFocused;
  final VoidCallback onPressed;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.isFocused,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: isFocused ? Border.all(color: Colors.white, width: 3) : null,
      ),
      transform: Matrix4.identity()..scale(isFocused ? 1.05 : 1.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFocused
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.15),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
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
