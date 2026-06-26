import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:padalpro/domain/entities/court.dart';

/// Featured court card with gradient overlay and category badge
class FeaturedCourtCard extends StatelessWidget {
  final Court court;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const FeaturedCourtCard({
    super.key,
    required this.court,
    this.onTap,
    this.width = 280,
    this.height = 200,
  });

  static const _defaultImages = [
    'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=1200',
    'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=1200',
    'https://images.unsplash.com/photo-1526232761682-d26e03ac148e?w=1200',
    'https://plus.unsplash.com/premium_photo-1723924861073-5764741be57c?w=1200',
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=1200',
  ];

  @override
  Widget build(BuildContext context) {
    final imageUrl = court.thumbnail ?? _defaultImages[court.id % _defaultImages.length];
    final cityName = court.city?.name ?? 'Unknown';
    final categoryName = court.category?.name ?? court.material;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: CachedNetworkImageProvider(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
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
          child: Stack(
            children: [
              // Category badge - top right
              Positioned(
                top: 0,
                right: 0,
                child: _buildCategoryBadge(categoryName),
              ),
              // Bottom content
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    court.name,
                    style: AppTextStyles.white(AppTextStyles.heading4),
                  ),
                  const SizedBox(height: 4),
                  _buildLocationRow(cityName),
                  const SizedBox(height: 8),
                  _buildPriceRow(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String categoryName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            court.material.toLowerCase() == 'cement'
                ? Icons.grid_4x4_outlined
                : Icons.grass_outlined,
            size: 14,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            categoryName,
            style: AppTextStyles.captionSmallBold.copyWith(height: 1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(String cityName) {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          cityName,
          style: AppTextStyles.withColor(AppTextStyles.caption, Colors.white70),
        ),
        const SizedBox(width: 10),
        Icon(
          court.material.toLowerCase() == 'cement'
              ? Icons.grid_4x4_outlined
              : Icons.grass_outlined,
          size: 14,
          color: Colors.white70,
        ),
        const SizedBox(width: 4),
        Text(
          court.material,
          style: AppTextStyles.withColor(AppTextStyles.caption, Colors.white70),
        ),
      ],
    );
  }

  Widget _buildPriceRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${court.pricePerHourFormatted}/hr',
          style: AppTextStyles.withColor(AppTextStyles.bodyLargeSemibold, AppColors.primary).copyWith(fontWeight: FontWeight.w700),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'Book Now',
            style: AppTextStyles.captionSmallBold,
          ),
        ),
      ],
    );
  }
}
