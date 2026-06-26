import 'package:flutter/material.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:padalpro/presentation/pages/auth/get_started_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      image: 'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=1600',
      title: 'Find Your\nPerfect Court',
      description: 'Discover the best padel courts near you with real photos and reviews.',
    ),
    OnboardingItem(
      image: 'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=1600',
      title: 'Book in\nSeconds',
      description: 'Select your preferred date, time, and court. Instant confirmation.',
    ),
    OnboardingItem(
      image: 'https://images.unsplash.com/photo-1526232761682-d26e03ac148e?w=1600',
      title: 'Play &\nEnjoy',
      description: 'Show up, play, and have fun. We handle all the booking details.',
    ),
  ];

  void _onNextPressed() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToGetStarted();
    }
  }

  void _navigateToGetStarted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GetStartedPage()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Page content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _items.length,
            itemBuilder: (context, index) {
              return _OnboardingContent(item: _items[index]);
            },
          ),
          // Top bar with skip
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo/Brand
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/icon app.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PadalPro',
                        style: AppTextStyles.white(AppTextStyles.heading2).copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  // Skip button
                  TextButton(
                    onPressed: _navigateToGetStarted,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: AppTextStyles.white(AppTextStyles.bodyLarge).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) => _PageIndicator(isActive: index == _currentPage),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Next/Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onNextPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentPage == _items.length - 1 ? 'Get Started' : 'Next',
                        style: AppTextStyles.buttonLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String image;
  final String title;
  final String description;

  OnboardingItem({
    required this.image,
    required this.title,
    required this.description,
  });
}

class _OnboardingContent extends StatelessWidget {
  final OnboardingItem item;

  const _OnboardingContent({required this.item});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full screen image
        Image.network(
          item.image,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: AppColors.textPrimary,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: AppColors.primary,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.textPrimary,
                    AppColors.textPrimary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.sports_tennis,
                  size: 100,
                  color: AppColors.primary,
                ),
              ),
            );
          },
        ),
        // Gradient overlay for text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4, 0.7, 1.0],
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.9),
              ],
            ),
          ),
        ),
        // Text content
        Positioned(
          left: 24,
          right: 24,
          bottom: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: AppTextStyles.white(AppTextStyles.heading2).copyWith(
                  fontSize: 40,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.description,
                style: AppTextStyles.white(AppTextStyles.bodyLarge).copyWith(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final bool isActive;

  const _PageIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
