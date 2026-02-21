import 'package:flutter/material.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/presentation/pages/video_details_page.dart';
import 'package:streamapp/features/videos/presentation/pages/channel_details_page.dart';
import 'package:streamapp/features/videos/presentation/pages/playlist_details_page.dart';

class VideoCardWidget extends StatelessWidget {
  final SummaryModel summary;
  final bool isFocused;
  final VoidCallback? onTap;
  final StreamInfoModel? detailedInfo; // 🆕 Optional detailed info

  const VideoCardWidget({
    super.key,
    required this.summary,
    this.isFocused = false,
    this.onTap,
    this.detailedInfo,
  });

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
    if (seconds == null || seconds <= 0) return '';
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
    final data = summary.data;
    String? thumbnailUrl;
    String? title;
    String? subtitle;
    String? url;
    String itemType = summary.type.toLowerCase();
    bool _isHovering = false;

    final isActive = _isHovering || isFocused;
    if (data is StreamSummaryModel) {
      thumbnailUrl = _getValidThumbnailUrl(data.thumbnails);
      title = data.name;
      subtitle = data.uploader?.name;
      url = data.url;
      itemType = 'stream';
    } else if (data is PlaylistSummaryModel) {
      thumbnailUrl = _getValidThumbnailUrl(data.thumbnails);
      title = data.name;
      subtitle = data.uploader?.name;
      url = data.url;
      itemType = 'playlist';
    } else if (data is ChannelSummaryModel) {
      thumbnailUrl = _getValidThumbnailUrl(data.thumbnails);
      title = data.name;
      subtitle = '${data.subscriberCount ?? 0} subscribers';
      url = data.url;
      itemType = 'channel';
    }

    return InkWell(
      onTap: onTap ?? () => _handleNavigation(context, itemType, url, data),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 320,
        transform: Matrix4.identity()..scale(isActive ? 1.05 : 1.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Container
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surfaceVariant,
                border: isFocused
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
                  if (thumbnailUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        thumbnailUrl,
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
                  if (_formatDuration(data is StreamSummaryModel ? data.duration : null) != '')
                    // Duration Badge
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatDuration(data is StreamSummaryModel ? data.duration : null),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // item badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        itemType.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
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
                data.name ?? 'Untitled Video',
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
            if (data is StreamSummaryModel && data.uploader != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    // Channel Avatar
                    if (data.uploader!.thumbnails.isNotEmpty)
                      ClipOval(
                        child: Image.network(
                          data.uploader!.thumbnails.first.url,
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
                          if (data.uploader?.verified == true)
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          if (data.uploader?.verified == true)
                            const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              data.uploader?.name ?? 'Unknown',
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
            
            if (data is StreamSummaryModel )
            // Views
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _formatViews(data.views),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.6),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Extract valid thumbnail URL
  String? _getValidThumbnailUrl(List<dynamic> thumbnails) {
    if (thumbnails.isEmpty) return null;

    // Try to get the best quality thumbnail
    for (var thumbnail in thumbnails) {
      try {
        final url = thumbnail.url as String?;
        if (url != null && url.isNotEmpty && Uri.tryParse(url) != null) {
          return url;
        }
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  // Build thumbnail with proper error handling
  Widget _buildThumbnail(BuildContext context, String? thumbnailUrl, String itemType) {
    if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
      return _buildPlaceholder(context, itemType);
    }

    return Image.network(
      thumbnailUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: frame != null
              ? child
              : Container(
                  color: Colors.grey[850],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return Container(
          color: Colors.grey[850],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Error loading thumbnail: $error');
        return _buildPlaceholder(context, itemType);
      },
    );
  }

  // Build placeholder when thumbnail fails
  Widget _buildPlaceholder(BuildContext context, String itemType) {
    return Container(
      color: Colors.grey[850],
      child: Center(
        child: Icon(
          _getIconForType(itemType),
          size: 48,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, String itemType, String? url, dynamic data) {
    if (url == null) return;

    switch (itemType) {
      case 'stream':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoDetailsPage(
              videoUrl: url,
              streamInfo: detailedInfo, // 🆕 Pass detailed info if available
            ),
          ),
        );
        break;

      case 'channel':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChannelDetailsPage(channelUrl: url),
          ),
        );
        break;

      case 'playlist':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistDetailsPage(playlistUrl: url),
          ),
        );
        break;

      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoDetailsPage(
              videoUrl: url,
              streamInfo: detailedInfo, // 🆕 Pass detailed info if available
            ),
          ),
        );
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'stream':
        return Icons.play_circle_outline;
      case 'channel':
        return Icons.person_outline_rounded;
      case 'playlist':
        return Icons.playlist_play_rounded;
      default:
        return Icons.play_circle_outline;
    }
  }
}
