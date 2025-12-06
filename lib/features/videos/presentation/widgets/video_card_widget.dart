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

  const VideoCardWidget({
    super.key,
    required this.summary,
    this.isFocused = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = summary.data;
    String? thumbnailUrl;
    String? title;
    String? subtitle;
    String? url;
    String itemType = summary.type.toLowerCase();

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
        transform: Matrix4.identity()..scale(isFocused ? 1.05 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFocused ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 3,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with type badge
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: _buildThumbnail(context, thumbnailUrl, itemType),
                  ),
                  // Type badge
                  if (itemType != 'stream')
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getIconForType(itemType),
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              itemType.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? 'Untitled',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
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
            builder: (_) => VideoDetailsPage(videoUrl: url),
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
            builder: (_) => VideoDetailsPage(videoUrl: url),
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
