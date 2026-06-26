import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:padalpro/core/navigation/route_observer.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:padalpro/domain/entities/user.dart';
import 'package:padalpro/presentation/blocs/auth/auth.dart';
import 'package:padalpro/presentation/blocs/booking/booking.dart';
import 'package:padalpro/presentation/blocs/city/city.dart';
import 'package:padalpro/presentation/blocs/court/court.dart';
import 'package:padalpro/presentation/pages/bookings/booking_details_page.dart';
import 'package:padalpro/presentation/pages/bookings/my_bookings_page.dart';
import 'package:padalpro/presentation/pages/city/city_details_page.dart';
import 'package:padalpro/presentation/pages/court/court_details_page.dart';
import 'package:padalpro/presentation/pages/profile/profile_page.dart';
import 'package:padalpro/presentation/pages/scoreboard/scoreboard_page.dart';
import 'package:padalpro/presentation/pages/search/search_page.dart';
import 'package:padalpro/presentation/widgets/widgets.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> with RouteAware {
  int _currentNavIndex = 0;
  int _selectedCoachTab = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route observer to detect when page becomes visible
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when user navigates back to this page
    // Refresh the next booking data (silent refresh to avoid blink)
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<BookingBloc>().add(const NextBookingFetchRequested(isRefresh: true));
    }
  }

  /// Refresh all home page data (silent refresh without loading state)
  void _refreshHomeData() {
    // Refresh cities (silent)
    context.read<CityBloc>().add(const CitiesFetchRequested(isRefresh: true));
    // Refresh featured courts (silent)
    context.read<CourtBloc>().add(const FeaturedCourtsFetchRequested(isRefresh: true));
    // Refresh next booking if authenticated (silent)
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<BookingBloc>().add(const NextBookingFetchRequested(isRefresh: true));
    }
  }


  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        // Reset booking state when user logs out
        if (authState is AuthUnauthenticated) {
          context.read<BookingBloc>().add(const BookingReset());
        }
        // Fetch next booking when user logs in
        if (authState is AuthAuthenticated) {
          context.read<BookingBloc>().add(const NextBookingFetchRequested());
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState is AuthAuthenticated ? authState.user : null;
          final isAuthenticated = authState is AuthAuthenticated;

          // Fetch next booking when user is authenticated (initial load)
          if (isAuthenticated) {
            final bookingState = context.read<BookingBloc>().state;
            if (bookingState is BookingInitial) {
              context.read<BookingBloc>().add(const NextBookingFetchRequested());
            }
          }

          return Scaffold(
          backgroundColor: const Color(0xFFEDF0F6),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeader(context, user),
                const SizedBox(height: 24),

                // Latest Booking Card - only show when authenticated
                if (isAuthenticated)
                  BlocBuilder<BookingBloc, BookingState>(
                    builder: (context, bookingState) {
                      if (bookingState is NextBookingLoaded && bookingState.booking != null) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                          child: NextBookingCard(
                            booking: bookingState.booking!,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<BookingBloc>(),
                                    child: BookingDetailsPage(bookingId: bookingState.booking!.id),
                                  ),
                                ),
                              );
                            },
                            onViewAllTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => const MyBookingsPage(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(opacity: animation, child: child);
                                  },
                                  transitionDuration: const Duration(milliseconds: 150),
                                ),
                              );
                            },
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                // Browse by City Section
                _buildBrowseByCitySection(),
                const SizedBox(height: 24),

                // Featured Section
                _buildFeaturedSection(),
                const SizedBox(height: 24),

                // Coach for Hire Section
                _buildCoachSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
            // Floating Bottom Nav
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavBar(
                currentIndex: _currentNavIndex,
                onHomeTap: () => setState(() => _currentNavIndex = 0),
                onHomeDoubleTap: _refreshHomeData,
                onBookingsTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const MyBookingsPage(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 150),
                  ),
                ),
                onSearchTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const SearchPage(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 150),
                  ),
                ),
                onScoreboardTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const ScoreboardPage(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 150),
                  ),
                ),
                onProfileTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const ProfilePage(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 150),
                  ),
                ),
              ),
            ),
          ],
        ),
        );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // User Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              image: user?.profilePhotoUrl != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(user!.profilePhotoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user?.profilePhotoUrl == null
                ? Center(
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.heading2,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: AppTextStyles.body,
                ),
                Text(
                  user?.name ?? 'Guest',
                  style: AppTextStyles.heading2,
                ),
              ],
            ),
          ),
          // Notification Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
                Positioned(
                  top: 13,
                  right: 13,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
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

  Widget _buildBrowseByCitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Browse by City'),
        const SizedBox(height: 14),
        SizedBox(
          height: 145,
          child: BlocBuilder<CityBloc, CityState>(
            builder: (context, state) {
              if (state is CityLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is CityError) {
                return Center(
                  child: Text(
                    state.message,
                    style: AppTextStyles.body,
                  ),
                );
              }

              if (state is CitiesLoaded) {
                final cities = state.cities;
                if (cities.isEmpty) {
                  return Center(
                    child: Text(
                      'No cities available',
                      style: AppTextStyles.body,
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cities.length,
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    return Padding(
                      padding: EdgeInsets.only(right: index < cities.length - 1 ? 12 : 0),
                      child: CityCard(
                        city: city,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CityDetailsPage(
                              cityId: city.id,
                              cityName: city.name,
                              cityImage: city.photoUrl ?? 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=1200',
                              courtsCount: '${city.courtsCount} courts',
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Featured Courts',
          actionText: 'See All',
          onActionTap: () {},
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 200,
          child: BlocBuilder<CourtBloc, CourtState>(
            builder: (context, state) {
              if (state is CourtLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is CourtError) {
                return Center(
                  child: Text(
                    state.message,
                    style: AppTextStyles.body,
                  ),
                );
              }

              if (state is FeaturedCourtsLoaded) {
                final courts = state.courts;
                if (courts.isEmpty) {
                  return Center(
                    child: Text(
                      'No featured courts available',
                      style: AppTextStyles.body,
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: courts.length,
                  itemBuilder: (context, index) {
                    final court = courts[index];
                    return Padding(
                      padding: EdgeInsets.only(right: index < courts.length - 1 ? 16 : 0),
                      child: FeaturedCourtCard(
                        court: court,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourtDetailsPage(courtId: court.id),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCoachSection() {
    final List<String> tabs = ['Beginners', 'Intermediate', 'Advanced'];

    final List<Map<String, String>> allCoaches = [
      {'name': 'Andi Pratama', 'rating': '4.9', 'specialty': 'Padel Technique Coach', 'level': 'Intermediate', 'image': 'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?w=1200'},
      {'name': 'Maya Sari', 'rating': '4.8', 'specialty': 'Fitness & Conditioning', 'level': 'Advanced', 'image': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=1200'},
      {'name': 'Reza Gunawan', 'rating': '4.7', 'specialty': 'Strategy & Game Play', 'level': 'Advanced', 'image': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=1200'},
      {'name': 'Siti Rahma', 'rating': '4.9', 'specialty': 'Beginner Fundamentals', 'level': 'Beginners', 'image': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=1200'},
      {'name': 'Budi Santoso', 'rating': '4.6', 'specialty': 'Basic Techniques', 'level': 'Beginners', 'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=1200'},
      {'name': 'Diana Putri', 'rating': '4.8', 'specialty': 'Intermediate Skills', 'level': 'Intermediate', 'image': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=1200'},
    ];

    final coaches = allCoaches.where((c) => c['level'] == tabs[_selectedCoachTab]).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Coach for Hire', actionText: 'See All', onActionTap: () {}),
        const SizedBox(height: 14),
        // Tabs
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tabs.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedCoachTab == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedCoachTab = index),
                child: Container(
                  margin: EdgeInsets.only(right: index < tabs.length - 1 ? 10 : 0),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.textPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    tabs[index],
                    style: isSelected
                        ? AppTextStyles.white(AppTextStyles.bodySemibold)
                        : AppTextStyles.bodySemibold,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Coach cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: coaches.map((coach) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CoachCard(
                name: coach['name']!,
                rating: coach['rating']!,
                specialty: coach['specialty']!,
                imageUrl: coach['image']!,
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}
