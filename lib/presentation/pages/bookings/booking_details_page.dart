import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:padbro/core/theme/app_colors.dart';
import 'package:padbro/core/theme/app_text_styles.dart';
import 'package:padbro/core/utils/snackbar_helper.dart';
import 'package:padbro/domain/entities/booking.dart';
import 'package:padbro/presentation/blocs/booking/booking_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingDetailsPage extends StatelessWidget {
  final int bookingId;

  const BookingDetailsPage({
    super.key,
    required this.bookingId,
  });

  // Default court image fallback
  static const String _defaultCourtImage =
      'https://plus.unsplash.com/premium_photo-1723924861073-5764741be57c?w=1200';

  String _formatPrice(int price) {
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  /// Format date as "Sun 12 Jan" format
  String _formatFullDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('E d MMM').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  /// Check if booking has ended (date + endTime < now)
  bool _isCompleted(Booking booking) {
    if (booking.status != 'paid') return false;

    try {
      // Parse date (format: "2026-01-16") and endTime (format: "21:00")
      final endDateTime = DateTime.parse('${booking.date} ${booking.endTime}:00');
      return DateTime.now().isAfter(endDateTime);
    } catch (_) {
      return false;
    }
  }

  String _getStatusLabel(Booking booking) {
    if (booking.status == 'paid') {
      return _isCompleted(booking) ? 'Completed' : 'Upcoming';
    }
    switch (booking.status) {
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _getPaymentStatus(String status) {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get booking from BLoC cache
    final booking = context.read<BookingBloc>().findById(bookingId);

    if (booking == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'Booking not found',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final court = booking.court;
    final courtImage = court.thumbnail ?? _defaultCourtImage;
    final paymentStatus = _getPaymentStatus(booking.status);
    final statusLabel = _getStatusLabel(booking);
    final isCompleted = _isCompleted(booking);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Scrollable content (header + ticket)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header (now scrolls with content)
                  _buildHeader(context, paymentStatus, isCompleted),
                  // Ticket content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildTicket(
                      context,
                      booking: booking,
                      courtImage: courtImage,
                      paymentStatus: paymentStatus,
                      statusLabel: statusLabel,
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          // Bottom CTA
          _buildBottomCTA(context, court.phone),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String paymentStatus, bool isCompleted) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 24),
      child: Column(
        children: [
          // Back button row with centered title
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'My Booking',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Step progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Step 1 - Booking (done)
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Booking',
                    style: AppTextStyles.captionSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // Line between step 1 and 2
              Container(
                width: 50,
                height: 2,
                margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
                color: AppColors.textPrimary,
              ),
              // Step 2 - Payment (completed if Paid, failed if Failed, pending otherwise)
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: paymentStatus == 'Paid'
                          ? AppColors.textPrimary
                          : paymentStatus == 'Failed'
                              ? AppColors.error
                              : AppColors.textPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: paymentStatus == 'Paid' || paymentStatus == 'Failed'
                          ? null
                          : Border.all(color: AppColors.textPrimary, width: 2),
                    ),
                    child: paymentStatus == 'Paid'
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 20)
                        : paymentStatus == 'Failed'
                            ? const Icon(Icons.close_rounded,
                                color: Colors.white, size: 20)
                            : const Icon(Icons.access_time_rounded,
                                color: AppColors.textPrimary, size: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Payment',
                    style: AppTextStyles.captionSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: paymentStatus == 'Failed' ? AppColors.error : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // Line between step 2 and 3
              Container(
                width: 50,
                height: 2,
                margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
                color: isCompleted || paymentStatus == 'Paid'
                    ? AppColors.textPrimary
                    : paymentStatus == 'Failed'
                        ? AppColors.error.withValues(alpha: 0.3)
                        : AppColors.textSecondary.withValues(alpha: 0.3),
              ),
              // Step 3 - Playing (completed if done, active if Paid, cancelled if Failed)
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.textPrimary
                          : paymentStatus == 'Paid'
                              ? AppColors.textPrimary.withValues(alpha: 0.1)
                              : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isCompleted
                          ? null
                          : Border.all(
                              color: paymentStatus == 'Paid'
                                  ? AppColors.textPrimary
                                  : paymentStatus == 'Failed'
                                      ? AppColors.error.withValues(alpha: 0.3)
                                      : AppColors.textSecondary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 20)
                        : Icon(
                            Icons.sports_tennis_rounded,
                            color: paymentStatus == 'Paid'
                                ? AppColors.textPrimary
                                : paymentStatus == 'Failed'
                                    ? AppColors.error.withValues(alpha: 0.5)
                                    : AppColors.textSecondary.withValues(alpha: 0.5),
                            size: 18,
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCompleted ? 'Completed' : 'Playing',
                    style: AppTextStyles.captionSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCompleted || paymentStatus == 'Paid'
                          ? AppColors.textPrimary
                          : paymentStatus == 'Failed'
                              ? AppColors.error.withValues(alpha: 0.5)
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicket(
    BuildContext context, {
    required Booking booking,
    required String courtImage,
    required String paymentStatus,
    required String statusLabel,
  }) {
    final court = booking.court;
    final categoryName = court.category?.name ?? court.material;

    return Stack(
      children: [
        // Main ticket body
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Court mini card
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        courtImage,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 90,
                            height: 90,
                            color: Colors.grey[300],
                            child: const Icon(
                                Icons.image_not_supported_outlined),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            court.name,
                            style: AppTextStyles.heading4.copyWith(
                              fontSize: 17,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  court.city?.name ?? 'Unknown',
                                  style: AppTextStyles.body,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                categoryName == 'Cement'
                                    ? Icons.grid_4x4_outlined
                                    : Icons.grass_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                categoryName,
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Booking details
                Text(
                  'BOOKING INFORMATION',
                  style: AppTextStyles.captionSmallBold.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                        child: _buildDetailRow(Icons.calendar_today_rounded,
                            'Date', _formatFullDate(booking.date))),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildDetailRow(Icons.schedule_rounded,
                            'Duration', '${booking.totalHours} hours')),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                    Icons.access_time_rounded, 'Time', booking.timeSlot),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(Icons.confirmation_number_rounded,
                          'Booking ID', '#${booking.id}'),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (statusLabel == 'Upcoming' || statusLabel == 'Completed')
                            ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                            : statusLabel == 'Cancelled'
                                ? AppColors.error.withValues(alpha: 0.1)
                                : const Color(0xFFFF9800)
                                    .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTextStyles.captionSemibold.copyWith(
                          color: (statusLabel == 'Upcoming' || statusLabel == 'Completed')
                              ? const Color(0xFF4CAF50)
                              : statusLabel == 'Cancelled'
                                  ? AppColors.error
                                  : const Color(0xFFFF9800),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Space for half circle notches
                const SizedBox(height: 30),

                // Payment details
                Text(
                  'PAYMENT SUMMARY',
                  style: AppTextStyles.captionSmallBold.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),

                _buildPaymentRow('Subtotal', booking.subTotal),
                const SizedBox(height: 10),
                _buildPaymentRow('Tax (11%)', booking.taxAmount),
                const SizedBox(height: 10),
                _buildPaymentRow('Total Payment', booking.grandTotal,
                    isTotal: true),

                const SizedBox(height: 24),

                // Barcode - only lines, no text
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Row(
                    children: List.generate(
                      100,
                      (index) => Expanded(
                        flex: index % 4 == 0 ? 3 : (index % 3 == 0 ? 2 : 1),
                        child: Container(
                          height: 50,
                          color:
                              index % 2 == 0 ? AppColors.textPrimary : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Dashed line at notch position (below Booking ID)
        Positioned(
          left: 24,
          right: 24,
          top: 340,
          child: Row(
            children: List.generate(
              50,
              (index) => Expanded(
                child: Container(
                  height: 1.5,
                  color: index % 2 == 0
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : Colors.transparent,
                ),
              ),
            ),
          ),
        ),

        // Left and right circular notches (below Booking ID)
        Positioned(
          left: -15,
          top: 325,
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: -15,
          top: 325,
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.captionSmall,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyLargeSemibold.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, int amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.bodyLargeSemibold.copyWith(fontWeight: FontWeight.w700)
              : AppTextStyles.body,
        ),
        Text(
          amount == 0 ? 'Free' : _formatPrice(amount),
          style: isTotal
              ? AppTextStyles.heading4.copyWith(fontWeight: FontWeight.w800)
              : AppTextStyles.bodySemibold,
        ),
      ],
    );
  }

  Widget _buildBottomCTA(BuildContext context, String? phone) {
    final hasPhone = phone != null && phone.isNotEmpty;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                SnackBarHelper.showInfo(context, 'Share feature coming soon!');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.share_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Share',
                      style: AppTextStyles.white(AppTextStyles.buttonMedium),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: hasPhone
                  ? () => _makePhoneCall(phone)
                  : () => SnackBarHelper.showInfo(
                      context, 'Phone number not available'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: hasPhone ? AppColors.primary : AppColors.primary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_rounded,
                        color: hasPhone ? AppColors.textPrimary : AppColors.textPrimary.withValues(alpha: 0.5),
                        size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Call Manager',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: hasPhone ? AppColors.textPrimary : AppColors.textPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
