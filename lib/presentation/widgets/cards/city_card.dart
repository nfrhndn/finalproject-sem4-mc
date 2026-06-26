import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:padalpro/domain/entities/city.dart';

/// Compact city card with circular image for horizontal lists
class CityCard extends StatelessWidget {
  final City city;
  final VoidCallback? onTap;
  final double width;

  const CityCard({
    super.key,
    required this.city,
    this.onTap,
    this.width = 94,
  });

  static const _defaultCityImages = {
    'jakarta': 'https://images.unsplash.com/photo-1555899434-94d1368aa7af?w=1200',
    'bandung': 'https://images.unsplash.com/photo-1596402184320-417e7178b2cd?w=1200',
    'surabaya': 'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?w=1200',
    'denpasar': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=1200',
    'yogyakarta': 'https://images.unsplash.com/photo-1584810359583-96fc3448beaa?w=1200',
  };

  static const _fallbackImage = 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=1200';

  String get imageUrl {
    return city.photoUrl ??
        _defaultCityImages[city.slug] ??
        _fallbackImage;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // City photo - circular
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.background,
                image: DecorationImage(
                  image: CachedNetworkImageProvider(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // City name
            Text(
              city.name,
              style: AppTextStyles.bodyLargeSemibold.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Courts count
            Text(
              '${city.courtsCount} courts',
              style: AppTextStyles.secondary(AppTextStyles.captionSmall).copyWith(height: 1.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
