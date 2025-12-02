import 'package:flutter/material.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/presentation/pages/video_details_page.dart';

class VideoCardWidget extends StatelessWidget {
  final SummaryModel summary;
  final bool isFocused;

  const VideoCardWidget({
    super.key,
    required this.summary,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    final data = summary.data;
    
    String? thumbnailUrl;
    String? title;
    String? subtitle;
    String? url;

    if (data is StreamSummaryModel) {
      thumbnailUrl = data.thumbnails.isNotEmpty ? data.thumbnails.first.url : null;
      title = data.name;
      subtitle = data.uploader?.name;
      url = data.url;
    } else if (data is PlaylistSummaryModel) {
      thumbnailUrl = data.thumbnails.isNotEmpty ? data.thumbnails.first.url : null;
      title = data.name;
      subtitle = data.uploader?.name;
      url = data.url;
    } else if (data is ChannelSummaryModel) {
      thumbnailUrl = data.thumbnails.isNotEmpty ? data.thumbnails.first.url : null;
      title = data.name;
      subtitle = '${data.subscriberCount ?? 0} subscribers';
      url = data.url;
    }

    return InkWell(
      onTap: () {
        if (url != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoDetailsPage(videoUrl: url!),
            ),
          );
        }
      },
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
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: thumbnailUrl != null
                    ? Image.network(
                        thumbnailUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[850],
                          child: const Icon(Icons.play_circle_outline, size: 48),
                        ),
                      )
                    : Container(
                        color: Colors.grey[850],
                        child: const Icon(Icons.play_circle_outline, size: 48),
                      ),
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
}
