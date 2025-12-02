import 'package:flutter/material.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';

class VideoPlayerWidget extends StatelessWidget {
  final StreamInfoModel streamInfo;

  const VideoPlayerWidget({super.key, required this.streamInfo});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final playerHeight = screenWidth * 0.5625; // 16:9 aspect ratio

    return Container(
      width: double.infinity,
      height: playerHeight,
      color: Colors.black,
      child: Stack(
        children: [
          // Thumbnail placeholder
          if (streamInfo.thumbnails.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                streamInfo.thumbnails.first.url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black),
              ),
            ),

          // Play overlay
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),

          // TODO: Integrate actual video player here
          // You can use packages like video_player or better_player
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Video player coming soon',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
