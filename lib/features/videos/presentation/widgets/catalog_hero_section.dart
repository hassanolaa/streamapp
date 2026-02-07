import 'dart:async';
import 'package:flutter/material.dart';
import 'package:streamapp/core/di/service_locator.dart';
import 'package:streamapp/core/utils/gradients.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/data/services/recommendation_service.dart';
import 'package:streamapp/features/videos/presentation/pages/video_details_page.dart';

class CatalogHeroSection extends StatefulWidget {
  const CatalogHeroSection({super.key});

  @override
  State<CatalogHeroSection> createState() => _CatalogHeroSectionState();
}

class _CatalogHeroSectionState extends State<CatalogHeroSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  List<StreamSummaryModel> _heroVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // 🔥 Load cached recommendations
  Future<void> _loadRecommendations() async {
    try {
      final recommendationService = sl<RecommendationService>();
      final recommendations = recommendationService.getRecommendations();

      if (recommendations.isNotEmpty) {
        // Convert to StreamSummaryModel and take top 5
        final videos = recommendations
            .map((r) => r.toStreamSummary())
            .take(5)
            .toList();

        setState(() {
          _heroVideos = videos;
          _isLoading = false;
        });

        print('📺 [CatalogHeroSection] Loaded ${_heroVideos.length} hero videos');

        // Start auto-play after loading
        _startAutoPlay();
      } else {
        // No recommendations, use fallback
        setState(() {
          _heroVideos = [];
          _isLoading = false;
        });
        print('⚠️ [CatalogHeroSection] No recommendations available');
      }
    } catch (e) {
      print('❌ [CatalogHeroSection] Error loading recommendations: $e');
      setState(() {
        _heroVideos = [];
        _isLoading = false;
      });
    }
  }

  // 🔥 Auto-play functionality
  void _startAutoPlay() {
    if (_heroVideos.isEmpty) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;

      final nextPage = (_currentPage + 1) % _heroVideos.length;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  // 🔥 Stop auto-play when user interacts
  void _pauseAutoPlay() {
    _autoPlayTimer?.cancel();
  }

  // 🔥 Resume auto-play after user interaction
  void _resumeAutoPlay() {
    _autoPlayTimer?.cancel();
    _startAutoPlay();
  }

  // 🔥 Manual navigation
  void _goToPage(int page) {
    _pauseAutoPlay();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );

    // Resume auto-play after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _resumeAutoPlay();
    });
  }

  // 🔥 Open video details
  void _openVideo(StreamSummaryModel video) {
    if (video.url != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoDetailsPage(videoUrl: video.url!),
        ),
      );
    }
  }

  // 🔥 Get gradient based on index
  Gradient _getGradient(int index) {
    final gradients = [
      AppGradients.purplePink,
      AppGradients.bluePurple,
      AppGradients.orangeRed,
      AppGradients.purplePink,
      AppGradients.bluePurple,
    ];
    return gradients[index % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return SizedBox(
        height: 400,
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    // Empty state (fallback to default hero)
    if (_heroVideos.isEmpty) {
      return _buildFallbackHero();
    }

    // 🔥 Real recommendations carousel
    return SizedBox(
      height: 400,
      child: Stack(
        children: [
          // Carousel
          PageView.builder(
            controller: _pageController,
            itemCount: _heroVideos.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final video = _heroVideos[index];
              final gradient = _getGradient(index);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _openVideo(video),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Background thumbnail (if available)
                          if (video.thumbnails.isNotEmpty)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  _getHighQualityThumbnail(video.thumbnails),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(),
                                ),
                              ),
                            ),

                          // Gradient overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.3),
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Content
                          Padding(
                            padding: const EdgeInsets.all(60),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Recommended for You',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 16),

                                // Video title
                                Text(
                                  video.name ?? 'Untitled',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 36,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 12),

                                // Uploader info
                                if (video.uploader?.name != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_rounded,
                                        color: Colors.white.withOpacity(0.9),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        video.uploader!.name!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white.withOpacity(0.9),
                                            ),
                                      ),
                                      if (video.uploader!.verified ?? false) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.verified,
                                          color: Colors.blue,
                                          size: 16,
                                        ),
                                      ],
                                    ],
                                  ),

                                const SizedBox(height: 24),

                                // Play button
                                ElevatedButton.icon(
                                  onPressed: () => _openVideo(video),
                                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                                  label: const Text('Watch Now'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Page Indicators (Clickable)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _heroVideos.length,
                (index) => MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _goToPage(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
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
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Fallback hero when no recommendations
  Widget _buildFallbackHero() {
    return Container(
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        gradient: AppGradients.purplePink,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_library_rounded,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              'Discover Videos',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Watch videos to get personalized recommendations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 Get high-quality thumbnail
  String _getHighQualityThumbnail(List<dynamic> thumbnails) {
    if (thumbnails.isEmpty) return '';

    final sortedThumbnails = List.from(thumbnails)
      ..sort((a, b) {
        final aSize = a.width * a.height;
        final bSize = b.width * b.height;
        return bSize.compareTo(aSize);
      });

    return sortedThumbnails.first.url;
  }
}
