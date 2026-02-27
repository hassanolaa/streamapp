import 'package:flutter/material.dart';
import 'package:streamapp/features/iptv/data/models/iptv_enriched_channel.dart';

class IptvChannelCard extends StatefulWidget {
  final IptvEnrichedChannel channel;
  final bool isFocused;
  final VoidCallback? onTap;

  const IptvChannelCard({
    super.key,
    required this.channel,
    this.isFocused = false,
    this.onTap,
  });

  @override
  State<IptvChannelCard> createState() => _IptvChannelCardState();
}

class _IptvChannelCardState extends State<IptvChannelCard> {
  bool _isHovering = false;

  bool get _isActive => _isHovering || widget.isFocused;

  /// Returns a deterministic pastel accent color based on the channel name.
  Color _accentColor(BuildContext context) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Colors.teal,
      Colors.indigo,
      Colors.deepOrange,
      Colors.purple,
      Colors.cyan,
    ];
    final hash = widget.channel.name.codeUnits
        .fold<int>(0, (prev, c) => (prev + c) % colors.length);
    return colors[hash];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(context);
    final logoUrl = widget.channel.logoUrl;
    final hasStream = widget.channel.streamUrl != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.identity()..scale(_isActive ? 1.07 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isActive
                  ? [
                      accent.withOpacity(0.25),
                      Theme.of(context).colorScheme.surface,
                    ]
                  : [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface,
                    ],
            ),
            border: Border.all(
              color: widget.isFocused
                  ? accent
                  : _isHovering
                      ? accent.withOpacity(0.5)
                      : Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: widget.isFocused ? 3 : 1.5,
            ),
            boxShadow: _isActive
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.35),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / placeholder
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildLogo(context, logoUrl, accent),
                    ),
                  ),

                  // Channel name
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      widget.channel.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            color: _isActive
                                ? accent
                                : Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                          ),
                    ),
                  ),

                  // Quality badge
                  if (widget.channel.quality != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.channel.quality!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // LIVE badge top-left
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 6),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // No stream indicator
              if (!hasStream)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'No Stream',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Play overlay on focus/hover
              if (_isActive && hasStream)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, String? logoUrl, Color accent) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildPlaceholder(context, accent),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return _buildPlaceholder(context, accent);
          },
        ),
      );
    }
    return _buildPlaceholder(context, accent);
  }

  Widget _buildPlaceholder(BuildContext context, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.tv_rounded,
          size: 40,
          color: accent.withOpacity(0.6),
        ),
      ),
    );
  }
}
