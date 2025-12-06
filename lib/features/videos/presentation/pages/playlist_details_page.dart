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
  State<_PlaylistDetailsContent> createState() => _PlaylistDetailsContentState();
}

class _PlaylistDetailsContentState extends State<_PlaylistDetailsContent> {
  bool _isDescriptionExpanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
          // context.read<VideosCubit>().loadMorePlaylistItems(playlist.items!.nextPageToken!);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
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

              if (state is VideosPlaylistInfoSuccess) {
                return _buildPlaylistDetails(context, state.playlistInfo);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistDetails(BuildContext context, PlaylistInfoModel playlist) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Playlist Banner
          _buildPlaylistBanner(context, playlist),

          const SizedBox(height: 40),

          // Playlist Stats
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 60),
          //   child: Row(
          //     children: [
          //       _buildStatCard(
          //         context,
          //         Icons.video_library_rounded,
          //         'videos'.tr(),
          //         '${playlist.items?.items.length ?? 0}',
          //         Theme.of(context).colorScheme.primary,
          //       ),
          //       const SizedBox(width: 24),
          //       if (playlist.playlistType != null)
          //         _buildStatCard(
          //           context,
          //           Icons.category_rounded,
          //           'type'.tr(),
          //           playlist.playlistType!,
          //           Theme.of(context).colorScheme.secondary,
          //         ),
          //     ],
          //   ),
          // ),

          // const SizedBox(height: 40),

          // // Description Section
          // if (playlist.description != null) ...[
          //   Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 60),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         Text(
          //           'description'.tr(),
          //           style: Theme.of(context)
          //               .textTheme
          //               .displayMedium
          //               ?.copyWith(fontSize: 20),
          //         ),
          //         const SizedBox(height: 12),
          //         Container(
          //           width: double.infinity,
          //           padding: const EdgeInsets.all(20),
          //           decoration: BoxDecoration(
          //             color: Theme.of(context).colorScheme.surface,
          //             borderRadius: BorderRadius.circular(12),
          //           ),
          //           child: Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               Text(
          //                 playlist.description!.content,
          //                 style: Theme.of(context).textTheme.bodyMedium,
          //                 maxLines: _isDescriptionExpanded ? null : 3,
          //                 overflow: _isDescriptionExpanded
          //                     ? null
          //                     : TextOverflow.ellipsis,
          //               ),
          //               const SizedBox(height: 12),
          //               MouseRegion(
          //                 cursor: SystemMouseCursors.click,
          //                 child: GestureDetector(
          //                   onTap: () {
          //                     setState(() {
          //                       _isDescriptionExpanded = !_isDescriptionExpanded;
          //                     });
          //                   },
          //                   child: Container(
          //                     padding: const EdgeInsets.symmetric(
          //                       horizontal: 16,
          //                       vertical: 8,
          //                     ),
          //                     decoration: BoxDecoration(
          //                       color: Theme.of(context)
          //                           .colorScheme
          //                           .primary
          //                           .withOpacity(0.1),
          //                       borderRadius: BorderRadius.circular(20),
          //                     ),
          //                     child: Row(
          //                       mainAxisSize: MainAxisSize.min,
          //                       children: [
          //                         Text(
          //                           _isDescriptionExpanded
          //                               ? 'see_less'.tr()
          //                               : 'see_more'.tr(),
          //                           style: Theme.of(context)
          //                               .textTheme
          //                               .bodyMedium
          //                               ?.copyWith(
          //                                 color: Theme.of(context)
          //                                     .colorScheme
          //                                     .primary,
          //                                 fontWeight: FontWeight.w600,
          //                               ),
          //                         ),
          //                         const SizedBox(width: 4),
          //                         AnimatedRotation(
          //                           duration: const Duration(milliseconds: 300),
          //                           turns: _isDescriptionExpanded ? 0.5 : 0,
          //                           child: Icon(
          //                             Icons.keyboard_arrow_down_rounded,
          //                             color:
          //                                 Theme.of(context).colorScheme.primary,
          //                             size: 20,
          //                           ),
          //                         ),
          //                       ],
          //                     ),
          //                   ),
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          //   const SizedBox(height: 40),
          // ],

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

  Widget _buildPlaylistBanner(BuildContext context, PlaylistInfoModel playlist) {
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
                     filterQuality: FilterQuality.high, // High quality rendering
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
             // back Button
          Positioned(
            left: 20,
            top: 40,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 32, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black45,
                padding: const EdgeInsets.all(8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                // Uploader Info
                if (playlist.uploader != null)
                  InkWell(
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (playlist.uploader!.thumbnails.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                _getHighQualityThumbnail(
                                        playlist.uploader!.thumbnails) ??
                                    playlist.uploader!.thumbnails.first.url,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 32,
                                  height: 32,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            playlist.uploader!.name ?? 'unknown_channel'.tr(),
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          Colors.white.withOpacity(0.5),
                                    ),
                          ),
                          if (playlist.uploader!.verified ?? false) ...[
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

                const SizedBox(height: 16),

                // Play All Button
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement play all functionality
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
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 16),
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
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildPlaylistItems(BuildContext context, PlaylistInfoModel tab) {
  final items = tab.items?.items ?? [];

  return SizedBox(
    height: 220,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 60),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: SizedBox(
            width: 280,
            child: InkWell(
              onTap: () {
                final item = items[index];
                // Check if it's a playlist
                if (item.type.toLowerCase() == 'playlist') {
                  final playlistData = item.data;
                  if (playlistData.url != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailsPage(
                          playlistUrl: playlistData.url!,
                        ),
                      ),
                    );
                  }
                } else {
                  // It's a video, use the existing VideoCardWidget
                  // VideoCardWidget already handles video navigation
                }
              },
              child: VideoCardWidget(
                summary: items[index],
                isFocused: false,
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
