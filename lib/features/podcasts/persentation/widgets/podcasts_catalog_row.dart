import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/presentation/managers/video_focus_manager.dart';
import 'package:streamapp/features/videos/presentation/pages/playlist_details_page.dart';
import 'package:streamapp/features/videos/presentation/pages/video_details_page.dart';

class PodcastsCatalogRow extends StatefulWidget {
  final String catalogName;
  final List<PlaylistSummaryModel> videos;
  final int catalogIndex;

  const PodcastsCatalogRow({
    super.key,
    required this.catalogName,
    required this.videos,
    required this.catalogIndex,
  });

  @override
  State<PodcastsCatalogRow> createState() => _PodcastsCatalogRowState();
}

class _PodcastsCatalogRowState extends State<PodcastsCatalogRow> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    final double itemWidth = 336.0; // 320 width + 16 margin (8 each side)
    final double targetScroll = index * itemWidth - 100; // Center the item
    
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) return const SizedBox.shrink();

    return Consumer<VideoFocusManager>(
      builder: (context, focusManager, child) {
        // Auto-scroll when this catalog is focused
        if (focusManager.isCatalogFocused(widget.catalogIndex)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToIndex(focusManager.currentVideoIndex);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Catalog Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_outline_rounded,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.catalogName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Video List - Disable scroll physics to prevent interference
            SizedBox(
              height: 320,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(), // Disable manual scrolling
                  itemCount: widget.videos.length,
                  itemBuilder: (context, index) {
                    final video = widget.videos[index];
                    final isFocused = focusManager.isFocused(widget.catalogIndex, index);
                    
                    return _ModernVideoCard(
                      video: video,
                      isFocused: isFocused,
                      onTap: () {
                        focusManager.selectVideo(widget.catalogIndex, index);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ModernVideoCard extends StatefulWidget {
  final PlaylistSummaryModel video;
  final bool isFocused;
  final VoidCallback onTap;

  const _ModernVideoCard({
    required this.video,
    required this.isFocused,
    required this.onTap,
  });

  @override
  State<_ModernVideoCard> createState() => _ModernVideoCardState();
}

class _ModernVideoCardState extends State<_ModernVideoCard> {
  bool _isHovering = false;

  String _formatViews(int? views) {
    if (views == null) return 'N/A';
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M views';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K views';
    }
    return '$views views';
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return 'LIVE';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = widget.video.thumbnails.isNotEmpty
        ? widget.video.thumbnails
            .where((t) => (t.width ?? 0) >= 300)
            .firstOrNull
            ?.url ?? widget.video.thumbnails.first.url
        : null;

    final isActive = _isHovering || widget.isFocused;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () {
          widget.onTap();
          if (widget.video.url != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaylistDetailsPage(
                  playlistUrl: widget.video.url!,
                ),
              ),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 320,
          transform: Matrix4.identity()
            ..scale(isActive ? 1.05 : 1.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Container
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  border: widget.isFocused
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 4,
                        )
                      : null,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                            spreadRadius: 2,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Stack(
                  children: [
                    // Thumbnail Image
                    if (thumbnail != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          thumbnail,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Theme.of(context).colorScheme.primaryContainer,
                                    Theme.of(context).colorScheme.secondaryContainer,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.play_circle_outline_rounded,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primaryContainer,
                              Theme.of(context).colorScheme.secondaryContainer,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.play_circle_outline_rounded,
                            size: 64,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),

                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),

                  

                  
                    // Play Button Overlay
                    if (isActive)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Video Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.video.name ?? 'Untitled Video',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 8),

              // Channel Info
              if (widget.video.uploader != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      // Channel Avatar
                      if (widget.video.uploader!.thumbnails.isNotEmpty)
                        ClipOval(
                          child: Image.network(
                            widget.video.uploader!.thumbnails.first.url,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 14,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      const SizedBox(width: 8),
                      
                      // Channel Name
                      Expanded(
                        child: Row(
                          children: [
                            if (widget.video.uploader?.verified == true)
                              Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            if (widget.video.uploader?.verified == true)
                              const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.video.uploader?.name ?? 'Unknown',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color
                                          ?.withOpacity(0.7),
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 4),

             
            ],
          ),
        ),
      ),
    );
  }
}
