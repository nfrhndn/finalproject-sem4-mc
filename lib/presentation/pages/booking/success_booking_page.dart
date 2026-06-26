import 'package:flutter/material.dart';
import 'package:padbro/core/theme/app_colors.dart';
import 'package:padbro/core/theme/app_text_styles.dart';
import 'package:padbro/presentation/pages/bookings/my_bookings_page.dart';
import 'package:padbro/presentation/pages/browse/browse_page.dart';

class SuccessBookingPage extends StatelessWidget {
  final String courtName;
  final String courtImage;
  final String location;
  final String category;

  const SuccessBookingPage({
    super.key,
    required this.courtName,
    required this.courtImage,
    required this.location,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [ 
              // Success illustration
              Image.asset(
                'assets/images/success_booking.png',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ), 
              // Success message
              Text(
                'Payment Submitted!',
                style: AppTextStyles.heading1.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'Your payment is being reviewed.\nWe\'ll notify you once it\'s approved.',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading5.copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Court mini card
              _buildCourtMiniCard(),
              const Spacer(),
              // CTA buttons
              _buildCTAButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourtMiniCard() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Court image - left side
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: Image.network(
              courtImage,
              width: 100,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 100,
                  height: 100,
                  color: AppColors.background,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 32,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          // Court details - right side
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    courtName,
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        category == 'Cement'
                            ? Icons.grid_4x4_outlined
                            : Icons.grass_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        category,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Book Other button
          SizedBox(
            width: double.infinity,
            height: 56,
          child: ElevatedButton(
            onPressed: () {
              // Navigate back to browse page
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const BrowsePage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 150),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Text(
              'Book Another Court',
              style: AppTextStyles.buttonLarge,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // My Bookings button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              // Navigate to My Bookings page
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const MyBookingsPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 150),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              side: const BorderSide(color: AppColors.textPrimary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Text(
              'My Bookings',
              style: AppTextStyles.buttonLarge,
            ),
          ),
        ),
        ],
      ),
    );
  }
}
