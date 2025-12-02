import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HeroCarouselWidget extends StatefulWidget {
  const HeroCarouselWidget({super.key});

  @override
  State<HeroCarouselWidget> createState() => _HeroCarouselWidgetState();
}

class _HeroCarouselWidgetState extends State<HeroCarouselWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  int _selectedButton = 0;
  final List<FocusNode> _buttonFocusNodes = List.generate(2, (_) => FocusNode());

  final List<_HeroItem> _heroItems = [
    _HeroItem(
      title: 'Rise of X',
      description: 'An epic journey through space and time, where heroes discover their true destiny.',
      imageUrl: 'https://images.unsplash.com/photo-1626814026160-2237a95fc5a0?w=1200',
    ),
    _HeroItem(
      title: 'Dark Universe',
      description: 'Explore the mysteries of parallel dimensions in this thrilling sci-fi adventure.',
      imageUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=1200',
    ),
    _HeroItem(
      title: 'Ocean Depths',
      description: 'Dive into the unknown as marine biologists uncover ancient secrets beneath the waves.',
      imageUrl: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=1200',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    for (var node in _buttonFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_currentPage < _heroItems.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
  }

  void _navigateLeft() {
    _stopAutoPlay();
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
    _startAutoPlay();
  }

  void _navigateRight() {
    _stopAutoPlay();
    if (_currentPage < _heroItems.length - 1) {
      setState(() => _currentPage++);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
    _startAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth * 0.25;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const _NavigateLeftIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const _NavigateRightIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
      },
      child: Actions(
        actions: {
          _NavigateLeftIntent: CallbackAction<_NavigateLeftIntent>(
            onInvoke: (_) {
              if (_selectedButton == 0 && _currentPage > 0) {
                _navigateLeft();
              } else if (_selectedButton > 0) {
                setState(() => _selectedButton--);
                _buttonFocusNodes[_selectedButton].requestFocus();
              }
              return null;
            },
          ),
          _NavigateRightIntent: CallbackAction<_NavigateRightIntent>(
            onInvoke: (_) {
              if (_selectedButton < 1) {
                setState(() => _selectedButton++);
                _buttonFocusNodes[_selectedButton].requestFocus();
              } else if (_currentPage < _heroItems.length - 1) {
                _navigateRight();
              }
              return null;
            },
          ),
        },
        child: SizedBox(
          height: bannerHeight,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _heroItems.length,
                itemBuilder: (context, index) {
                  return _HeroBanner(
                    item: _heroItems[index],
                    buttonFocusNodes: _buttonFocusNodes,
                    selectedButton: _selectedButton,
                  );
                },
              ),
              // Page Indicators
              Positioned(
                bottom: 80,
                right: 60,
                child: Row(
                  children: List.generate(
                    _heroItems.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
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

class _HeroItem {
  final String title;
  final String description;
  final String imageUrl;

  _HeroItem({
    required this.title,
    required this.description,
    required this.imageUrl,
  });
}

class _HeroBanner extends StatelessWidget {
  final _HeroItem item;
  final List<FocusNode> buttonFocusNodes;
  final int selectedButton;

  const _HeroBanner({
    required this.item,
    required this.buttonFocusNodes,
    required this.selectedButton,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.network(
            item.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey[850]),
          ),
        ),
        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.transparent,
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                ],
              ),
            ),
          ),
        ),
        // Content
        Positioned(
          left: 60,
          bottom: 80,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Focus(
                      focusNode: buttonFocusNodes[0],
                      child: _ActionButton(
                        icon: Icons.play_arrow_rounded,
                        label: 'play'.tr(),
                        isPrimary: true,
                        isFocused: selectedButton == 0,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 16),
                    Focus(
                      focusNode: buttonFocusNodes[1],
                      child: _ActionButton(
                        icon: Icons.info_outline_rounded,
                        label: 'more_info'.tr(),
                        isPrimary: false,
                        isFocused: selectedButton == 1,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isFocused;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    this.isFocused = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()..scale(isFocused ? 1.05 : 1.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? (isFocused ? Theme.of(context).colorScheme.primary : Colors.white)
              : Colors.white.withOpacity(isFocused ? 0.3 : 0.2),
          foregroundColor: isPrimary ? (isFocused ? Colors.white : Colors.black) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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

class _NavigateLeftIntent extends Intent {
  const _NavigateLeftIntent();
}

class _NavigateRightIntent extends Intent {
  const _NavigateRightIntent();
}
