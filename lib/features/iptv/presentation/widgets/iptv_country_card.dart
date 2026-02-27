import 'package:flutter/material.dart';
import 'package:streamapp/features/iptv/data/models/iptv_country_model.dart';
import 'package:streamapp/features/iptv/data/models/iptv_enriched_channel.dart';

class IptvCountryCard extends StatefulWidget {
  final String countryCode;
  final List<IptvEnrichedChannel> channels;
  final IptvCountryModel? country;
  final bool isFocused;
  final VoidCallback? onTap;

  const IptvCountryCard({
    super.key,
    required this.countryCode,
    required this.channels,
    this.country,
    this.isFocused = false,
    this.onTap,
  });

  @override
  State<IptvCountryCard> createState() => _IptvCountryCardState();
}

class _IptvCountryCardState extends State<IptvCountryCard>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool get _isActive => _isHovering || widget.isFocused;

  // Deterministic gradient based on country code
  List<Color> _gradientColors(BuildContext context) {
    final palettes = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // indigo-violet
      [const Color(0xFF0EA5E9), const Color(0xFF06B6D4)], // sky-cyan
      [const Color(0xFF10B981), const Color(0xFF059669)], // emerald
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)], // amber-red
      [const Color(0xFFEC4899), const Color(0xFFA855F7)], // pink-purple
      [const Color(0xFF3B82F6), const Color(0xFF6366F1)], // blue-indigo
      [const Color(0xFF14B8A6), const Color(0xFF06B6D4)], // teal-cyan
      [const Color(0xFFF97316), const Color(0xFFEF4444)], // orange-red
    ];
    final hash = widget.countryCode.codeUnits
        .fold<int>(0, (p, c) => (p + c) % palettes.length);
    return palettes[hash];
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grad = _gradientColors(context);
    final flag = widget.country?.flag ?? '🌍';
    final name = widget.country?.name ?? widget.countryCode;
    final channelCount = widget.channels.length;
    final streamCount =
        widget.channels.where((c) => c.streamUrl != null).length;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..scale(_isActive ? 1.06 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isActive
                  ? [grad[0], grad[1]]
                  : [
                      grad[0].withOpacity(0.15),
                      grad[1].withOpacity(0.08),
                    ],
            ),
            border: Border.all(
              color: widget.isFocused
                  ? grad[0]
                  : _isHovering
                      ? grad[0].withOpacity(0.6)
                      : grad[0].withOpacity(0.25),
              width: widget.isFocused ? 3 : 1.5,
            ),
            boxShadow: _isActive
                ? [
                    BoxShadow(
                      color: grad[0].withOpacity(0.45),
                      blurRadius: 28,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // Background glow orb
              if (_isActive)
                Positioned(
                  top: -20,
                  right: -20,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (_, __) => Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                  ),
                ),

              // Main content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Flag emoji
                    Text(
                      flag,
                      style: TextStyle(
                        fontSize: _isActive ? 46 : 40,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    // Country name
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1.2,
                        color: _isActive
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Channel count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isActive
                            ? Colors.white.withOpacity(0.2)
                            : grad[0].withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isActive
                              ? Colors.white.withOpacity(0.3)
                              : grad[0].withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.live_tv_rounded,
                            size: 11,
                            color: _isActive ? Colors.white : grad[0],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$channelCount ch',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _isActive ? Colors.white : grad[0],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (streamCount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isActive
                                  ? Colors.greenAccent
                                  : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$streamCount live',
                            style: TextStyle(
                              fontSize: 10,
                              color: _isActive
                                  ? Colors.white70
                                  : Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow on focus
              if (widget.isFocused)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
