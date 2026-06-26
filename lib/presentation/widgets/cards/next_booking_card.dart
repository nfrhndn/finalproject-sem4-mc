import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:padbro/core/theme/app_colors.dart';
import 'package:padbro/core/theme/app_text_styles.dart';
import 'package:padbro/domain/entities/booking.dart';

/// Stacked card showing the user's next booking with court image
class NextBookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final VoidCallback? onViewAllTap;

  const NextBookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.onViewAllTap,
  });

  static const _defaultImage = 'https://plus.unsplash.com/premium_photo-1723924861073-5764741be57c?w=1200';

  @override
  Widget build(BuildContext context) {
    final courtImage = booking.court.thumbnail ?? _defaultImage;
    final cityName = booking.court.city?.name ?? 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Next Booking',
              style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
            ),
            GestureDetector(
              onTap: onViewAllTap,
              child: Text(
                'View All',
                style: AppTextStyles.secondary(AppTextStyles.bodySemibold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Stacked cards
        SizedBox(
          height: 230,
          child: Stack(
            children: [
              // Background card 2 (furthest back)
              Positioned(
                left: 16,
                right: 16,
                bottom: 0,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Background card 1
              Positioned(
                left: 8,
                right: 8,
                bottom: 10,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              // Main card (front)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(courtImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                  height: 210,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date and duration badges
                        _buildTopBadges(),
                        // Court info
                        _buildBottomInfo(cityName),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Date badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textPrimary),
              const SizedBox(width: 6),
              Text(
                booking.dateFormatted,
                style: AppTextStyles.captionSemibold.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        // Duration badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                '${booking.totalHours} ${booking.totalHours == 1 ? 'hour' : 'hours'}',
                style: AppTextStyles.white(AppTextStyles.captionSemibold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomInfo(String cityName) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.court.name,
                style: AppTextStyles.white(AppTextStyles.heading3).copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    cityName,
                    style: AppTextStyles.withColor(AppTextStyles.body, Colors.white70).copyWith(height: 1.0),
                  ),
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
