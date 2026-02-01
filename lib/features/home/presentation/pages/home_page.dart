import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:streamapp/features/home/widgets/category_filter_widget.dart';
import 'package:streamapp/features/home/widgets/content_row_widget.dart';
import 'package:streamapp/features/home/widgets/hero_carousel_widget.dart';
import 'package:streamapp/features/videos/presentation/pages/videos_home_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedCategory = 'all';
  final GlobalKey<VideosHomePageState> _videosHomeKey = GlobalKey();
  final GlobalKey<CategoryFilterWidgetState> _categoryFilterKey = GlobalKey(); 
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onNavigateDownFromCategory() {
  
    // When DOWN is pressed on category filter, focus videos
    if (_selectedCategory == 'videos') {
      if (_videosHomeKey.currentState != null) {
        _videosHomeKey.currentState!.requestVideoFocus();
      } else {
        print('❌ [HomePage] VideosHomeKey.currentState is NULL!');
      }
    } else {
      print('🏠 [HomePage] Not on videos category');
    }
  }

  void _onNavigateUpFromVideos() {
    
    // Scroll to top using our ScrollController
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      print('❌ [HomePage] ScrollController has no clients!');
    }

    // Refocus the CategoryFilter on "Videos" tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_categoryFilterKey.currentState != null) {
        _categoryFilterKey.currentState!.requestFocusOnVideos();
      } else {
        print('❌ [HomePage] CategoryFilter key is NULL!');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Category Filter (Always visible)
          CategoryFilterWidget(
            key: _categoryFilterKey,
            onCategoryChanged: _onCategoryChanged,
            onNavigateDown: _onNavigateDownFromCategory,
          ),
          
          const SizedBox(height: 24),
          
          // Dynamic content based on selected category
          _buildCategoryContent(),
        ],
      ),
    );
  }

  Widget _buildCategoryContent() {
    switch (_selectedCategory) {
      case 'all':
        return _buildAllContent();
      case 'videos':
        return VideosHomePage(
          key: _videosHomeKey,
          onNavigateUp: _onNavigateUpFromVideos,
        );
      case 'movies':
        return _buildComingSoon('Movies');
      case 'series':
        return _buildComingSoon('Series');
      case 'tv_shows':
        return _buildComingSoon('TV Shows');
      case 'podcasts':
        return _buildComingSoon('Podcasts');
      case 'iptv':
        return _buildComingSoon('IPTV');
      case 'live_channels':
        return _buildComingSoon('Live Channels');
      default:
        return _buildAllContent();
    }
  }

  Widget _buildAllContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HeroCarouselWidget(),
        const SizedBox(height: 40),
        ContentRowWidget(title: 'popular'.tr()),
        const SizedBox(height: 32),
        ContentRowWidget(title: 'continue_watching'.tr()),
        const SizedBox(height: 32),
        ContentRowWidget(title: 'new_releases'.tr()),
        const SizedBox(height: 32),
        ContentRowWidget(title: 'trending_now'.tr()),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildComingSoon(String feature) {
    return Padding(
      padding: const EdgeInsets.all(60.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upcoming_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '$feature - Coming Soon',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'This feature is under development',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.color
                        ?.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
