import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:image_picker/image_picker.dart';
import 'package:padalpro/core/injection/injection_container.dart';
import 'package:padalpro/core/utils/snackbar_helper.dart';
import 'package:padalpro/domain/repositories/booking_repository.dart';
import 'package:padalpro/presentation/pages/booking/success_booking_page.dart';

class PaymentPage extends StatefulWidget {
  final int bookingId;
  final String courtName;
  final String courtImage;
  final String location;
  final String category;
  final int pricePerHour;
  final DateTime bookingDate;
  final int startTime;
  final int endTime;
  final int expiresInSeconds;

  const PaymentPage({
    super.key,
    required this.bookingId,
    required this.courtName,
    required this.courtImage,
    required this.location,
    required this.category,
    required this.pricePerHour,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.expiresInSeconds,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // Repository
  late final BookingRepository _bookingRepository;

  // Payment tabs
  int _selectedPaymentTab = 0; // Default to Transfer
  final List<String> _paymentMethods = ['Transfer', 'E-Wallet', 'Credit Card'];

  // Proof of payment
  File? _proofOfPayment;

  // Countdown timer - uses backend expiration time
  late int _remainingSeconds;
  Timer? _timer;

  bool _isProcessing = false;
  bool _isCancelling = false;

  int get _totalHours => widget.endTime - widget.startTime;
  int get _subtotal => _totalHours * widget.pricePerHour;
  int get _taxAmount => (_subtotal * 0.11).round();
  int get _totalPrice => _subtotal + _taxAmount;

  String _formatPrice(int price) {
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _formatTime(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:00 $period';
  }

  String _getMonthName(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  String _getDayName(DateTime date) {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[date.weekday % 7];
  }

  String _formatCountdown() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _bookingRepository = sl<BookingRepository>();
    _remainingSeconds = widget.expiresInSeconds;
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _handleExpired();
        }
      });
    });
  }

  Future<void> _handleExpired() async {
    // Cancel the booking in the backend (slots will be released)
    await _bookingRepository.cancelBooking(widget.bookingId);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time,
                  color: AppColors.error,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Time Expired',
                style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Your payment time has expired. Please try booking again.',
                textAlign: TextAlign.center,
                style: AppTextStyles.secondary(AppTextStyles.bodyLarge),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Text(
                    'Back to Home',
                    style: AppTextStyles.buttonMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickProofOfPayment() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Upload Proof of Payment',
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final image = await picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 85,
                        );
                        if (image != null) {
                          setState(() {
                            _proofOfPayment = File(image.path);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 32,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Camera',
                              style: AppTextStyles.bodyLargeSemibold.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final image = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 85,
                        );
                        if (image != null) {
                          setState(() {
                            _proofOfPayment = File(image.path);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 32,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gallery',
                              style: AppTextStyles.bodyLargeSemibold.copyWith(fontWeight: FontWeight.w500),
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
      ),
    );
  }

  void _showConfirmationModal() {
    // Check if proof of payment is uploaded
    if (_proofOfPayment == null) {
      SnackBarHelper.showError(context, 'Please upload proof of payment first');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.help_outline_rounded,
                color: AppColors.textPrimary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Confirm Booking',
              style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to submit this booking?',
              textAlign: TextAlign.center,
              style: AppTextStyles.secondary(AppTextStyles.bodyLarge),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.buttonMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _handleSubmitBooking();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Center(
                        child: Text(
                          'Submit',
                          style: AppTextStyles.buttonMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmitBooking() async {
    if (_proofOfPayment == null) return;

    setState(() {
      _isProcessing = true;
    });

    final result = await _bookingRepository.confirmBooking(
      bookingId: widget.bookingId,
      proofOfPayment: _proofOfPayment!,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isProcessing = false;
        });
        SnackBarHelper.showError(context, failure.message);
      },
      (booking) {
        setState(() {
          _isProcessing = false;
        });
        // Stop the timer
        _timer?.cancel();
        // Navigate to success page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => SuccessBookingPage(
              courtName: widget.courtName,
              courtImage: widget.courtImage,
              location: widget.location,
              category: widget.category,
            ),
          ),
          (route) => false,
        );
      },
    );
  }

  Future<bool> _handleBackNavigation() async {
    if (_isProcessing || _isCancelling) return false;

    final shouldLeave = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cancel Booking?',
              style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'If you leave now, your booking will be cancelled and the time slots will be released.',
              textAlign: TextAlign.center,
              style: AppTextStyles.secondary(AppTextStyles.bodyLarge),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Center(
                        child: Text(
                          'Stay',
                          style: AppTextStyles.buttonMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Center(
                        child: Text(
                          'Leave',
                          style: AppTextStyles.white(AppTextStyles.buttonMedium).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (shouldLeave == true) {
      setState(() {
        _isCancelling = true;
      });
      _timer?.cancel();
      await _bookingRepository.cancelBooking(widget.bookingId);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBackNavigation();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                // Court card
                Transform.translate(
                  offset: const Offset(0, -55),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildCourtCard(),
                  ),
                ),
                // Booking summary
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildBookingSummary(),
                  ),
                ),
                // Payment section
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildPaymentSection(),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          // Countdown timer notification - floating on top
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: _buildCountdownNotification(),
            ),
          ),
          // Bottom CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomCTA(),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 75),
      decoration: const BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final shouldPop = await _handleBackNavigation();
              if (shouldPop && mounted) {
                Navigator.pop(context);
              }
            },
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Payment',
              style: AppTextStyles.white(AppTextStyles.heading3).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownNotification() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Complete payment in ',
            style: AppTextStyles.white(AppTextStyles.body).copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
          Text(
            _formatCountdown(),
            style: AppTextStyles.white(AppTextStyles.heading5).copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildCourtCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        image: DecorationImage(
          image: CachedNetworkImageProvider(widget.courtImage),
          fit: BoxFit.cover,
        ),
      ),
      height: 160,
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
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.courtName,
              style: AppTextStyles.white(AppTextStyles.heading3).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  widget.location,
                  style: AppTextStyles.withColor(AppTextStyles.body, Colors.white70),
                ),
                const SizedBox(width: 10),
                Icon(
                  widget.category == 'Cement' ? Icons.grid_4x4_outlined : Icons.grass_outlined,
                  size: 14,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.category,
                  style: AppTextStyles.withColor(AppTextStyles.body, Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking Summary',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildSummaryRow(
                Icons.calendar_today_rounded,
                'Date',
                '${_getDayName(widget.bookingDate)}, ${widget.bookingDate.day} ${_getMonthName(widget.bookingDate)} ${widget.bookingDate.year}',
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                Icons.access_time_rounded,
                'Time',
                '${_formatTime(widget.startTime)} - ${_formatTime(widget.endTime)}',
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                Icons.schedule_rounded,
                'Duration',
                '$_totalHours ${_totalHours == 1 ? 'hour' : 'hours'}',
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: AppColors.textSecondary.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              _buildSummaryRow(
                Icons.payments_rounded,
                'Price per hour',
                _formatPrice(widget.pricePerHour),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                Icons.receipt_long_rounded,
                'Subtotal',
                _formatPrice(_subtotal),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                Icons.percent_rounded,
                'Tax (11%)',
                _formatPrice(_taxAmount),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: AppColors.textSecondary.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Total',
                    style: AppTextStyles.heading5,
                  ),
                  const Spacer(),
                  Text(
                    _formatPrice(_totalPrice),
                    style: AppTextStyles.heading3,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textPrimary,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.body,
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodySemibold,
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: 12),
        // White card containing tabs and content
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Payment tabs inside the card
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(100),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: List.generate(_paymentMethods.length, (index) {
                    final isSelected = _selectedPaymentTab == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPaymentTab = index;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.textPrimary : Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          child: Text(
                            _paymentMethods[index],
                            style: isSelected
                                ? AppTextStyles.white(AppTextStyles.bodySemibold)
                                : AppTextStyles.secondary(AppTextStyles.bodySemibold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              // Payment content based on selected tab
              _buildPaymentContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentContent() {
    if (_selectedPaymentTab == 0) {
      // Transfer
      return _buildBankTransferInfo();
    } else {
      // E-Wallet or Credit Card - Coming Soon
      return _buildComingSoon();
    }
  }

  Widget _buildComingSoon() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.schedule_rounded,
              size: 40,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Coming Soon',
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'This payment method will be available soon',
            textAlign: TextAlign.center,
            style: AppTextStyles.secondary(AppTextStyles.bodyLarge),
          ),
        ],
      ),
    );
  }

  Widget _buildBankTransferInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bank selection (only BCA for now)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BCA',
                    style: AppTextStyles.heading4,
                  ),
                  Text(
                    'Bank Central Asia',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Bank account details
        Text(
          'Account Details',
          style: AppTextStyles.bodyLargeSemibold.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _buildBankDetail('Account Number', '8234567890'),
        const SizedBox(height: 10),
        _buildBankDetail('Account Name', 'PadalPro Indonesia'),
        const SizedBox(height: 20),
        // Instructions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Transfer the exact amount to the account above. Your booking will be confirmed after payment verification.',
                  style: AppTextStyles.captionSemibold.copyWith(fontWeight: FontWeight.w400, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Proof of payment upload
        GestureDetector(
          onTap: _pickProofOfPayment,
          child: _proofOfPayment != null
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Preview image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _proofOfPayment!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Receipt Uploaded',
                                  style: AppTextStyles.heading5,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to change image',
                              style: AppTextStyles.body,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_rounded,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ],
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.upload_file_rounded,
                          size: 28,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Upload Payment Receipt',
                        style: AppTextStyles.heading5,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to take a photo or choose from gallery',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBankDetail(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.body,
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodySemibold,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            // TODO: Copy to clipboard
            SnackBarHelper.showInfo(context, 'Copied to clipboard');
          },
          child: Icon(
            Icons.copy_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCTA() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
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
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _showConfirmationModal,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
            disabledBackgroundColor: AppColors.textSecondary.withValues(alpha: 0.3),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          child: _isProcessing
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.textPrimary,
                  ),
                )
              : Text(
                  'Submit Booking',
                  style: AppTextStyles.buttonLarge,
                ),
        ),
      ),
    );
  }
}
