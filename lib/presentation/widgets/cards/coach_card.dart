import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';

/// Coach card for displaying coach information in lists
class CoachCard extends StatelessWidget {
  final String name;
  final String rating;
  final String specialty;
  final String imageUrl;
  final VoidCallback? onBookTap;
  final VoidCallback? onMessageTap;

  const CoachCard({
    super.key,
    required this.name,
    required this.rating,
    required this.specialty,
    required this.imageUrl,
    this.onBookTap,
    this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Photo
          Container(
            width: 80,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: CachedNetworkImageProvider(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTextStyles.heading5,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFD700)),
                    const SizedBox(width: 2),
                    Text(
                      rating,
                      style: AppTextStyles.captionSemibold,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Specialty
                Text(
                  specialty,
                  style: AppTextStyles.secondary(AppTextStyles.caption),
                ),
                const SizedBox(height: 12),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onBookTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Center(
                            child: Text(
                              'Book Now',
                              style: AppTextStyles.captionSemibold.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: onMessageTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 16,
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Message',
                                style: AppTextStyles.captionSemibold.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
