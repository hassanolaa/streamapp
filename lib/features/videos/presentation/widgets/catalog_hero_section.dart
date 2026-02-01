import 'package:flutter/material.dart';
import 'package:streamapp/core/utils/gradients.dart';

class CatalogHeroSection extends StatefulWidget {
  const CatalogHeroSection({super.key});

  @override
  State<CatalogHeroSection> createState() => _CatalogHeroSectionState();
}

class _CatalogHeroSectionState extends State<CatalogHeroSection> {
  int _currentPage = 0;
  
  final List<_HeroContent> _heroItems = [
    _HeroContent(
      title: 'Trending Videos',
      subtitle: 'Discover what\'s popular on YouTube and SoundCloud',
      gradient: AppGradients.purplePink,
      icon: Icons.trending_up_rounded,
    ),
    _HeroContent(
      title: 'Music Collection',
      subtitle: 'Explore curated playlists and albums',
      gradient: AppGradients.bluePurple,
      icon: Icons.music_note_rounded,
    ),
    _HeroContent(
      title: 'Latest Uploads',
      subtitle: 'Check out the newest content from creators',
      gradient: AppGradients.orangeRed,
      icon: Icons.fiber_new_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: _heroItems.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final item = _heroItems[index];
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: item.gradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // Background pattern
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.1,
                          child: Icon(
                            item.icon,
                            size: 300,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      // Content (NO BUTTONS)
                      Padding(
                        padding: const EdgeInsets.all(60),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              size: 64,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              item.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                            ),
                            // BUTTONS REMOVED
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Page indicators
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _heroItems.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroContent {
  final String title;
  final String subtitle;
  final Gradient gradient;
  final IconData icon;

  _HeroContent({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
  });
}
