import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:padbro/core/injection/injection_container.dart';
import 'package:padbro/core/theme/app_colors.dart';
import 'package:padbro/core/theme/app_text_styles.dart';
import 'package:padbro/domain/entities/booking.dart';
import 'package:padbro/presentation/blocs/booking/booking_bloc.dart';
import 'package:padbro/presentation/blocs/booking/booking_event.dart';
import 'package:padbro/presentation/blocs/booking/booking_state.dart';
import 'package:padbro/presentation/pages/bookings/booking_details_page.dart';
import 'package:padbro/presentation/pages/browse/browse_page.dart';
import 'package:padbro/presentation/pages/profile/profile_page.dart';
import 'package:padbro/presentation/pages/scoreboard/scoreboard_page.dart';
import 'package:padbro/presentation/pages/search/search_page.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  int _currentNavIndex = 3;
  String _selectedTab = 'Upcoming';

  // Default court image fallback
  static const String _defaultCourtImage = 'https://plus.unsplash.com/premium_photo-1723924861073-5764741be57c?w=1200';

  final List<String> _tabs = ['Upcoming', 'Pending', 'Completed', 'Cancelled'];

  late BookingBloc _bookingBloc;

  @override
  void initState() {
    super.initState();
    _bookingBloc = sl<BookingBloc>();
    _fetchBookings();
  }

  void _fetchBookings() {
    _bookingBloc.add(MyBookingsFetchRequested(status: _getStatusFilter()));
  }

  String _getStatusFilter() {
    switch (_selectedTab) {
      case 'Upcoming':
        return 'upcoming';
      case 'Pending':
        return 'pending';
      case 'Completed':
        return 'completed';
      case 'Cancelled':
        return 'cancelled';
      default:
        return 'upcoming';
    }
  }

  String _formatPrice(int price) {
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _getPaymentStatus(String bookingStatus) {
    switch (bookingStatus) {
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
    return BlocProvider.value(
      value: _bookingBloc,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Column(
              children: [
                // Header
                _buildHeader(),
                // Tabs
                _buildTabs(),
                // Bookings list
                Expanded(
                  child: BlocBuilder<BookingBloc, BookingState>(
                    builder: (context, state) {
                      if (state is BookingLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.textPrimary,
                          ),
                        );
                      }

                      if (state is BookingError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load bookings',
                                style: AppTextStyles.heading4.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.message,
                                style: AppTextStyles.secondary(AppTextStyles.bodyLarge),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchBookings,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textPrimary,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is MyBookingsLoaded) {
                        if (state.bookings.isEmpty) {
                          return _buildEmptyState();
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            _fetchBookings();
                          },
                          color: AppColors.textPrimary,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                            children: [
                              // Booking cards
                              ...state.bookings.map((booking) => _buildBookingCard(booking)),
                            ],
                          ),
                        );
                      }

                      // Initial state
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
            // Floating Bottom Nav
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'My Bookings',
              style: AppTextStyles.white(AppTextStyles.heading1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                });
                _fetchBookings();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.textPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: isSelected
                      ? AppTextStyles.white(AppTextStyles.captionSemibold)
                      : AppTextStyles.captionSemibold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final isUpcoming = _selectedTab == 'Upcoming';
    final court = booking.court;
    final courtImage = court.thumbnail ?? _defaultCourtImage;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top row: Booking ID
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ID: #${booking.id}',
                        style: AppTextStyles.captionSmallBold.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Payment status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getPaymentStatus(booking.status),
                        style: AppTextStyles.withColor(
                          AppTextStyles.captionSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          _getStatusColor(booking.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Horizontal court card
                Row(
                  children: [
                    // Court image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        courtImage,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder();
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Court details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            court.name,
                            style: AppTextStyles.heading4,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                court.city?.name ?? 'Unknown',
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                court.material == 'Cement' ? Icons.grid_4x4_outlined : Icons.grass_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  court.category?.name ?? court.material,
                                  style: AppTextStyles.caption,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Price with lime background
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isUpcoming ? AppColors.primary : AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatPrice(booking.grandTotal),
                              style: AppTextStyles.bodyLargeSemibold.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Date and Time info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: AppTextStyles.captionSmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    booking.dateFormatted,
                                    style: AppTextStyles.bodySemibold.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time',
                                    style: AppTextStyles.captionSmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    booking.timeSlot,
                                    style: AppTextStyles.captionSmallBold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Action button for all bookings
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    // Navigate to details page - just pass booking ID
                    // Details page will read full booking from BLoC cache
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: _bookingBloc,
                          child: BookingDetailsPage(bookingId: booking.id),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isUpcoming ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Center(
                      child: Text(
                        'View Details',
                        style: AppTextStyles.buttonSmall,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: AppColors.background,
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 32,
        color: AppColors.textSecondary,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/no data empty state.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            'No ${_selectedTab.toLowerCase()} bookings',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your ${_selectedTab.toLowerCase()} bookings will appear here',
            style: AppTextStyles.secondary(AppTextStyles.bodyLarge),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(
        bottom: 30,
      ),
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
              _buildNavIcon(0, Icons.home_rounded),
              const SizedBox(width: 4),
              _buildNavIcon(3, Icons.receipt_long_outlined),
              const SizedBox(width: 4),
              _buildNavCenterButton(),
              const SizedBox(width: 4),
              _buildNavIcon(1, Icons.scoreboard_outlined),
              const SizedBox(width: 4),
              _buildNavIcon(4, Icons.person_outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData icon) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          // Navigate to Browse page
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
        } else if (index == 1) {
          // Navigate to Scoreboard page
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const ScoreboardPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 150),
            ),
          );
        } else if (index == 4) {
          // Navigate to Profile page
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const ProfilePage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 150),
            ),
          );
        } else {
          setState(() {
            _currentNavIndex = index;
          });
        }
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.15) : const Color(0xFF2A2A2A),
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

  Widget _buildNavCenterButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const SearchPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 150),
          ),
        );
      },
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
