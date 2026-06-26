import 'package:flutter/material.dart';
import 'package:padalpro/core/injection/injection_container.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:padalpro/data/datasources/court_remote_datasource.dart';
import 'package:padalpro/domain/repositories/booking_repository.dart';
import 'package:padalpro/domain/repositories/court_repository.dart';
import 'package:padalpro/presentation/pages/payment/payment_page.dart';

class BookingPage extends StatefulWidget {
  final int courtId;
  final String courtName;
  final String courtImage;
  final String location;
  final String category;
  final int price;

  const BookingPage({
    super.key,
    required this.courtId,
    required this.courtName,
    required this.courtImage,
    required this.location,
    required this.category,
    required this.price,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // Repositories
  late final CourtRepository _courtRepository;
  late final BookingRepository _bookingRepository;

  // Selected date and time
  int _selectedDateIndex = 0;
  int? _selectedStartTime;
  int? _selectedEndTime;

  // API state
  bool _isLoadingSlots = false;
  bool _isValidating = false;
  String? _slotsError;
  List<TimeSlotModel> _timeSlots = [];

  // Available dates (next 8 days starting from tomorrow)
  List<DateTime> get _availableDates {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return List.generate(8, (i) => tomorrow.add(Duration(days: i)));
  }

  @override
  void initState() {
    super.initState();
    _courtRepository = sl<CourtRepository>();
    _bookingRepository = sl<BookingRepository>();
    _fetchAvailableSlots();
  }

  /// Fetch available slots for the selected date
  Future<void> _fetchAvailableSlots() async {
    final hadPreviousSlots = _timeSlots.isNotEmpty;

    setState(() {
      _isLoadingSlots = true;
      _slotsError = null;
      _selectedStartTime = null;
      _selectedEndTime = null;
    });

    final selectedDate = _availableDates[_selectedDateIndex];
    final dateString = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    final result = await _courtRepository.getAvailableSlots(widget.courtId, dateString);

    result.fold(
      (failure) {
        setState(() {
          _isLoadingSlots = false;
          _slotsError = failure.message;
          // Only clear slots if this is the first load (no previous slots)
          if (!hadPreviousSlots) {
            _timeSlots = [];
          }
        });
        // Show snackbar for error when switching dates
        if (hadPreviousSlots && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                failure.message,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red.shade600,
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _fetchAvailableSlots,
              ),
            ),
          );
        }
      },
      (response) {
        setState(() {
          _isLoadingSlots = false;
          _slotsError = null;
          _timeSlots = response.slots;
        });
      },
    );
  }

  /// Validate selected slots are still available before proceeding to payment
  Future<void> _validateAndProceed() async {
    if (_selectedStartTime == null || _selectedEndTime == null) return;

    setState(() {
      _isValidating = true;
    });

    final selectedDate = _availableDates[_selectedDateIndex];
    final dateString = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    final result = await _courtRepository.getAvailableSlots(widget.courtId, dateString);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isValidating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to verify availability: ${failure.message}',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade600,
            margin: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      (response) {
        // Check if all selected hours are still available
        final unavailableSlots = <String>[];

        for (int hour = _selectedStartTime!; hour < _selectedEndTime!; hour++) {
          final timeString = '${hour.toString().padLeft(2, '0')}:00';
          final slot = response.slots.firstWhere(
            (s) => s.time == timeString,
            orElse: () => const TimeSlotModel(time: '', available: false),
          );

          if (!slot.available) {
            unavailableSlots.add(_formatTime(hour));
          }
        }

        setState(() {
          _isValidating = false;
          _timeSlots = response.slots; // Update slots with latest data
        });

        if (unavailableSlots.isNotEmpty) {
          // Some slots are no longer available
          setState(() {
            _selectedStartTime = null;
            _selectedEndTime = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                unavailableSlots.length == 1
                    ? 'Sorry, ${unavailableSlots.first} is no longer available'
                    : 'Sorry, some slots are no longer available: ${unavailableSlots.join(", ")}',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red.shade600,
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          // All slots are available, create pending booking
          _createBookingAndProceed(dateString);
        }
      },
    );
  }

  /// Create a pending booking and navigate to payment page
  Future<void> _createBookingAndProceed(String dateString) async {
    final bookingResult = await _bookingRepository.createBooking(
      courtId: widget.courtId,
      date: dateString,
      startHour: _selectedStartTime!,
      endHour: _selectedEndTime!,
    );

    if (!mounted) return;

    bookingResult.fold(
      (failure) {
        setState(() {
          _isValidating = false;
        });
        // Refresh slots in case they were taken
        _fetchAvailableSlots();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failure.message,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade600,
            margin: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      (response) {
        setState(() {
          _isValidating = false;
        });
        // Navigate to payment page with booking info
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentPage(
              bookingId: response.booking.id,
              courtName: widget.courtName,
              courtImage: widget.courtImage,
              location: widget.location,
              category: widget.category,
              pricePerHour: widget.price,
              bookingDate: _availableDates[_selectedDateIndex],
              startTime: _selectedStartTime!,
              endTime: _selectedEndTime!,
              expiresInSeconds: response.expiresInSeconds ?? 180,
            ),
          ),
        );
      },
    );
  }

  /// Get hour from time string (e.g., "10:00" -> 10)
  int _getHourFromTimeString(String time) {
    return int.parse(time.split(':')[0]);
  }

  /// Check if a time slot is booked
  bool _isTimeBooked(String time) {
    final slot = _timeSlots.firstWhere(
      (s) => s.time == time,
      orElse: () => const TimeSlotModel(time: '', available: false),
    );
    return !slot.available;
  }

  /// Check if a time slot is booked by hour
  bool _isHourBooked(int hour) {
    final timeString = '${hour.toString().padLeft(2, '0')}:00';
    return _isTimeBooked(timeString);
  }

  // Check if any hour in range is booked (for "To" section validation)
  bool _isRangeAvailable(int startHour, int endHour) {
    for (int h = startHour; h < endHour; h++) {
      if (_isHourBooked(h)) return false;
    }
    return true;
  }

  // Check if a start hour has any valid end time options
  bool _hasValidEndTime(int startHour) {
    // Check if the start hour itself is booked
    if (_isHourBooked(startHour)) return false;

    // Get all available hours from time slots
    final hours = _timeSlots.map((s) => _getHourFromTimeString(s.time)).toList();

    // Check if there's at least one valid end time after this start hour
    for (int endHour in hours) {
      if (endHour > startHour && _isRangeAvailable(startHour, endHour)) {
        return true;
      }
    }
    return false;
  }

  String _formatPrice(int price) {
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _formatTime(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:00 $period';
  }

  String _getDayName(DateTime date) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }

  String _getMonthName(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  int get _totalHours {
    if (_selectedStartTime == null || _selectedEndTime == null) return 0;
    return _selectedEndTime! - _selectedStartTime!;
  }

  int get _subtotal {
    return _totalHours * widget.price;
  }

  int get _taxAmount {
    return (_subtotal * 0.11).round();
  }

  int get _totalPrice {
    return _subtotal + _taxAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with black background
                _buildHeader(),
                // Court card overlapping header
                Transform.translate(
                  offset: const Offset(0, -55),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildCourtInfoCard(),
                  ),
                ),
                // Date selection
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildDateSection(),
                  ),
                ),
                // Time selection
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildTimeSection(),
                  ),
                ),
                // Booking summary
                if (_selectedStartTime != null && _selectedEndTime != null)
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildBookingSummary(),
                    ),
                  ),
                if (_selectedStartTime != null && _selectedEndTime != null)
                  const SizedBox(height: 40),
                const SizedBox(height: 120),
              ],
            ),
          ),
          // Floating bottom booking bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(),
          ),
        ],
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
          Expanded(
            child: Text(
              'Book Court',
              textAlign: TextAlign.center,
              style: AppTextStyles.white(AppTextStyles.heading3).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildCourtInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.courtImage,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          // Court info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.courtName,
                  style: AppTextStyles.heading4,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.location,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.category,
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatPrice(widget.price)}/hour',
                  style: AppTextStyles.bodyLargeSemibold.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,

            itemCount: _availableDates.length,
            itemBuilder: (context, index) {
              final date = _availableDates[index];
              final isSelected = _selectedDateIndex == index;

              return GestureDetector(
                onTap: () {
                  if (_selectedDateIndex != index) {
                    setState(() {
                      _selectedDateIndex = index;
                    });
                    _fetchAvailableSlots();
                  }
                },
                child: Container(
                  width: 56,
                  margin: EdgeInsets.only(right: index < _availableDates.length - 1 ? 10 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.textPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayName(date),
                        style: AppTextStyles.captionSmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: isSelected
                            ? AppTextStyles.white(AppTextStyles.heading3)
                            : AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getMonthName(date),
                        style: AppTextStyles.tiny.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Select Time',
              style: AppTextStyles.heading4,
            ),
            if (_isLoadingSlots && _timeSlots.isNotEmpty) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (_slotsError != null && _timeSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 32, color: AppColors.textSecondary),
                const SizedBox(height: 8),
                Text(
                  _slotsError!,
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _fetchAvailableSlots,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Retry',
                      style: AppTextStyles.white(AppTextStyles.captionSemibold),
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (_timeSlots.isEmpty && !_isLoadingSlots)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No available slots for this date',
                style: AppTextStyles.body,
              ),
            ),
          )
        else if (_timeSlots.isEmpty && _isLoadingSlots)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          )
        else ...[
          // From time
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isLoadingSlots ? 0.5 : 1.0,
            child: IgnorePointer(
              ignoring: _isLoadingSlots,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From',
                      style: AppTextStyles.secondary(AppTextStyles.bodySemibold),
                    ),
                    const SizedBox(height: 10),
                    _buildTimeGrid(
                      isFromSection: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // To time
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isLoadingSlots ? 0.5 : 1.0,
            child: IgnorePointer(
              ignoring: _isLoadingSlots,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To',
                      style: AppTextStyles.secondary(AppTextStyles.bodySemibold),
                    ),
                    const SizedBox(height: 10),
                    _buildTimeGrid(
                      isFromSection: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeGrid({required bool isFromSection}) {
    // Get hours from time slots
    final hours = _timeSlots.map((s) => _getHourFromTimeString(s.time)).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth = (constraints.maxWidth - 16) / 3; // 3 columns with spacing

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: hours.map((hour) {
            final isBooked = _isHourBooked(hour);
            final isSelected = isFromSection
                ? _selectedStartTime == hour
                : _selectedEndTime == hour;

            // For "From" section: disabled if booked, no valid end times, or if end time is already selected and hour >= end time
            // For "To" section: disabled if no start time, hour <= start time, or if range contains booked slot
            final isDisabled = isFromSection
                ? (isBooked || !_hasValidEndTime(hour) || (_selectedEndTime != null && hour >= _selectedEndTime!))
                : (_selectedStartTime == null || hour <= _selectedStartTime! || !_isRangeAvailable(_selectedStartTime!, hour));

            return GestureDetector(
              onTap: (isDisabled && !isSelected) ? null : () {
                setState(() {
                  if (isFromSection) {
                    // Toggle selection - if already selected, deselect
                    if (_selectedStartTime == hour) {
                      _selectedStartTime = null;
                      _selectedEndTime = null; // Also reset end time
                    } else {
                      _selectedStartTime = hour;
                      // Reset end time if it's before or equal to start time or range has booked slots
                      if (_selectedEndTime != null &&
                          (_selectedEndTime! <= hour || !_isRangeAvailable(hour, _selectedEndTime!))) {
                        _selectedEndTime = null;
                      }
                    }
                  } else {
                    // Toggle selection - if already selected, deselect
                    if (_selectedEndTime == hour) {
                      _selectedEndTime = null;
                    } else {
                      _selectedEndTime = hour;
                    }
                  }
                });
              },
              child: Container(
                width: buttonWidth,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isBooked
                      ? const Color(0xFFFFE5E5)
                      : (isSelected ? AppColors.textPrimary : (isDisabled ? AppColors.background : Colors.white)),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isBooked
                        ? const Color(0xFFFFCCCC)
                        : (isSelected ? AppColors.textPrimary : (isDisabled ? Colors.transparent : AppColors.background)),
                    width: 2,
                  ),
                ),
                child: Text(
                  _formatTime(hour),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionSemibold.copyWith(
                    color: isBooked
                        ? const Color(0xFFE57373)
                        : (isSelected ? Colors.white : (isDisabled ? AppColors.textSecondary.withValues(alpha: 0.5) : AppColors.textPrimary)),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBookingSummary() {
    final selectedDate = _availableDates[_selectedDateIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Details',
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: 16),
          // Date
          _buildSummaryRow(
            Icons.calendar_today_outlined,
            'Date',
            '${_getDayName(selectedDate)}, ${selectedDate.day} ${_getMonthName(selectedDate)} ${selectedDate.year}',
          ),
          const SizedBox(height: 16),
          // Time
          _buildSummaryRow(
            Icons.access_time_outlined,
            'Time',
            '${_formatTime(_selectedStartTime!)} - ${_formatTime(_selectedEndTime!)}',
          ),
          const SizedBox(height: 16),
          // Duration
          _buildSummaryRow(
            Icons.timelapse_outlined,
            'Duration',
            '$_totalHours ${_totalHours == 1 ? 'hour' : 'hours'}',
          ),
          const SizedBox(height: 16),
          // Price per hour
          _buildSummaryRow(
            Icons.payments_outlined,
            'Price per hour',
            _formatPrice(widget.price),
          ),
          const SizedBox(height: 16),
          // Subtotal
          _buildSummaryRow(
            Icons.calculate_outlined,
            'Subtotal',
            _formatPrice(_subtotal),
          ),
          const SizedBox(height: 16),
          // Tax 11%
          _buildSummaryRow(
            Icons.percent_outlined,
            'Tax (11%)',
            _formatPrice(_taxAmount),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          ),
          // Total
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 18,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 10),
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

  Widget _buildBottomBar() {
    final canProceed = _selectedStartTime != null && _selectedEndTime != null;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
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
              // Price section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canProceed ? _formatPrice(_totalPrice) : '-',
                      style: AppTextStyles.white(AppTextStyles.heading3),
                    ),
                    Text(
                      'Total',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Continue button
              GestureDetector(
                onTap: (canProceed && !_isValidating) ? _validateAndProceed : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: canProceed ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: _isValidating
                      ? SizedBox(
                          width: 70,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          'Continue',
                          style: AppTextStyles.heading4.copyWith(
                            color: canProceed ? AppColors.textPrimary : AppColors.textSecondary,
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
