import 'package:flutter/material.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/presentation/pages/playlist_details_page.dart';

class CatalogRowWidget extends StatelessWidget {
  final String catalogProvider;
  final List<PlaylistInfoModel> playlists;

  const CatalogRowWidget({
    super.key,
    required this.catalogProvider,
    required this.playlists,
  });

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            children: [
              Icon(
                _getProviderIcon(catalogProvider),
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                catalogProvider,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // Navigate to see all
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            scrollDirection: Axis.horizontal,
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return _PlaylistCard(playlist: playlist);
            },
          ),
        ),
      ],
    );
  }

  IconData _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'youtube':
        return Icons.play_circle_outline_rounded;
      case 'soundcloud':
        return Icons.audio_file_rounded;
      default:
        return Icons.video_library_rounded;
    }
  }
}

class _PlaylistCard extends StatefulWidget {
  final PlaylistInfoModel playlist;

  const _PlaylistCard({required this.playlist});

  @override
  State<_PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<_PlaylistCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final thumbnail = widget.playlist.thumbnails.isNotEmpty
        ? widget.playlist.thumbnails.first.url
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () {
          if (widget.playlist.url != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaylistDetailsPage(
                  playlistUrl: widget.playlist.url!,
                ),
              ),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 240,
          transform: Matrix4.identity()
            ..scale(_isHovering ? 1.05 : 1.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  boxShadow: _isHovering
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : [],
                ),
                child: Stack(
                  children: [
                    // Image
                    if (thumbnail != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          thumbnail,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              child: Icon(
                                Icons.playlist_play_rounded,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.playlist_play_rounded,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),

                    // Stream count badge
                    // if (widget.playlist.streamCount != null)
                    //   Positioned(
                    //     top: 12,
                    //     right: 12,
                    //     child: Container(
                    //       padding: const EdgeInsets.symmetric(
                    //         horizontal: 12,
                    //         vertical: 6,
                    //       ),
                    //       decoration: BoxDecoration(
                    //         color: Colors.black.withOpacity(0.7),
                    //         borderRadius: BorderRadius.circular(8),
                    //       ),
                    //       child: Row(
                    //         mainAxisSize: MainAxisSize.min,
                    //         children: [
                    //           const Icon(
                    //             Icons.playlist_play_rounded,
                    //             size: 16,
                    //             color: Colors.white,
                    //           ),
                    //           const SizedBox(width: 4),
                    //           Text(
                    //             '${widget.playlist.streamCount}',
                    //             style: const TextStyle(
                    //               color: Colors.white,
                    //               fontSize: 12,
                    //               fontWeight: FontWeight.w600,
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ),

                    // Play button on hover
                    if (_isHovering)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                widget.playlist.name ?? 'Unnamed Playlist',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Uploader
              if (widget.playlist.uploader?.name != null)
                Row(
                  children: [
                    if (widget.playlist.uploader!.verified == true)
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    if (widget.playlist.uploader!.verified == true)
                      const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.playlist.uploader!.name!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
