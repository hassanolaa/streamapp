import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/core/di/service_locator.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_cubit.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_state.dart';
import 'package:streamapp/features/videos/presentation/widgets/video_player_widget.dart';

class VideoDetailsPage extends StatelessWidget {
  final String videoUrl;

  const VideoDetailsPage({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VideosCubit(repository: sl())..getStreamInfo(videoUrl),
      child: const _VideoDetailsContent(),
    );
  }
}

class _VideoDetailsContent extends StatefulWidget {
  const _VideoDetailsContent();

  @override
  State<_VideoDetailsContent> createState() => _VideoDetailsContentState();
}

class _VideoDetailsContentState extends State<_VideoDetailsContent> {
  int _selectedButton = 0;
  final List<FocusNode> _buttonFocusNodes = List.generate(3, (_) => FocusNode());

  @override
  void dispose() {
    for (var node in _buttonFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const _BackIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const _NavigateLeftIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const _NavigateRightIntent(),
      },
      child: Actions(
        actions: {
          _BackIntent: CallbackAction<_BackIntent>(
            onInvoke: (_) {
              Navigator.of(context).pop();
              return null;
            },
          ),
          _NavigateLeftIntent: CallbackAction<_NavigateLeftIntent>(
            onInvoke: (_) {
              if (_selectedButton > 0) {
                setState(() => _selectedButton--);
                _buttonFocusNodes[_selectedButton].requestFocus();
              }
              return null;
            },
          ),
          _NavigateRightIntent: CallbackAction<_NavigateRightIntent>(
            onInvoke: (_) {
              if (_selectedButton < 2) {
                setState(() => _selectedButton++);
                _buttonFocusNodes[_selectedButton].requestFocus();
              }
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
                return _buildVideoDetails(context, state.streamInfo);
              }

              return const SizedBox.shrink();
            },
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
          // Video Player
          VideoPlayerWidget(streamInfo: info),
          
          const SizedBox(height: 32),

          // Video Info Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  info.name ?? 'untitled'.tr(),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                ),
                
                const SizedBox(height: 16),

                // Channel & Stats
                Row(
                  children: [
                    if (info.uploader?.thumbnails.isNotEmpty ?? false)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          info.uploader!.thumbnails.first.url,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Text(
                      info.uploader?.name ?? 'unknown_channel'.tr(),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (info.uploader?.verified ?? false) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified, color: Colors.blue, size: 20),
                    ],
                    const SizedBox(width: 32),
                    Text(
                      '${_formatViews(info.viewCount ?? 0)} ${'views'.tr()}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _formatDuration(info.duration ?? 0),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Focus(
                      focusNode: _buttonFocusNodes[0],
                      child: _ActionButton(
                        icon: Icons.thumb_up_outlined,
                        label: '${_formatCount(info.likeCount ?? 0)}',
                        isFocused: _selectedButton == 0,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 16),
                    Focus(
                      focusNode: _buttonFocusNodes[1],
                      child: _ActionButton(
                        icon: Icons.share_outlined,
                        label: 'share'.tr(),
                        isFocused: _selectedButton == 1,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 16),
                    Focus(
                      focusNode: _buttonFocusNodes[2],
                      child: _ActionButton(
                        icon: Icons.playlist_add_outlined,
                        label: 'add_to_playlist'.tr(),
                        isFocused: _selectedButton == 2,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Description
                if (info.description != null) ...[
                  Text(
                    'description'.tr(),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      info.description!.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Tags
                if (info.tags.isNotEmpty) ...[
                  Text(
                    'tags'.tr(),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: info.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '#$tag',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
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
    if (count >= 1000) {
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isFocused;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isFocused,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()..scale(isFocused ? 1.05 : 1.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFocused
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          foregroundColor: isFocused ? Colors.white : Theme.of(context).textTheme.bodyMedium!.color,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isFocused
                ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                : BorderSide.none,
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
