import 'package:flutter/material.dart';
import 'package:padalpro/core/theme/app_colors.dart';

/// Floating bottom navigation bar used in main pages
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final VoidCallback? onHomeTap;
  final VoidCallback? onHomeDoubleTap;
  final VoidCallback? onBookingsTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onCommunityTap;
  final VoidCallback? onProfileTap;

  const BottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onHomeTap,
    this.onHomeDoubleTap,
    this.onBookingsTap,
    this.onSearchTap,
    this.onCommunityTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 30),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNavIcon(0, Icons.home_rounded, onHomeTap, onHomeDoubleTap),
              const SizedBox(width: 4),
              _buildNavIcon(
                3,
                Icons.receipt_long_outlined,
                onBookingsTap,
                null,
              ),
              const SizedBox(width: 4),
              _buildCenterButton(),
              const SizedBox(width: 4),
              _buildNavIcon(1, Icons.groups_2_outlined, onCommunityTap, null),
              const SizedBox(width: 4),
              _buildNavIcon(4, Icons.person_outline, onProfileTap, null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(
    int index,
    IconData icon,
    VoidCallback? onTap,
    VoidCallback? onDoubleTap,
  ) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFF2A2A2A),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: onSearchTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.search_rounded,
          size: 26,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
