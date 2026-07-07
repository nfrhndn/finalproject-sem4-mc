import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:padalpro/core/injection/injection_container.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:padalpro/domain/entities/court.dart';
import 'package:padalpro/presentation/blocs/court/court.dart';
import 'package:padalpro/presentation/pages/booking/booking_page.dart';
import 'package:padalpro/presentation/pages/community/create_match_page.dart';
import 'package:url_launcher/url_launcher.dart';

class CourtDetailsPage extends StatefulWidget {
  final int courtId;

  const CourtDetailsPage({super.key, required this.courtId});

  @override
  State<CourtDetailsPage> createState() => _CourtDetailsPageState();
}

class _CourtDetailsPageState extends State<CourtDetailsPage> {
  int _selectedPhotoIndex = 0;
  late final CourtBloc _courtBloc;

  // Feature icon mapping
  static const Map<String, IconData> _featureIcons = {
    'Parking Lot': Icons.local_parking_outlined,
    'Canteen': Icons.restaurant_outlined,
    'Locker Room': Icons.checkroom_outlined,
    'Shower': Icons.shower_outlined,
    'Free WiFi': Icons.wifi_outlined,
    'Gear Rental': Icons.sports_tennis_outlined,
    'Air Conditioning': Icons.ac_unit_outlined,
    'Pro Shop': Icons.store_outlined,
    'Lighting': Icons.lightbulb_outlined,
    'Seating Area': Icons.chair_outlined,
  };

  // Default court photos (fallback)
  final List<String> _defaultPhotos = [
    'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=1600',
    'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=1600',
    'https://images.unsplash.com/photo-1526232761682-d26e03ac148e?w=1600',
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=1600',
    'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=1600',
  ];

  // Sample testimonials (would come from backend in future)
  final List<Map<String, dynamic>> _testimonials = [
    {
      'name': 'Andi Pratama',
      'avatar':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      'rating': 5,
      'review':
          'Amazing court! The facilities are top-notch and the staff is very friendly. Will definitely come back!',
      'date': '2 days ago',
    },
    {
      'name': 'Sarah Wijaya',
      'avatar':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      'rating': 5,
      'review':
          'Best padel court in the city. Clean, well-maintained, and great lighting for night games.',
      'date': '1 week ago',
    },
    {
      'name': 'Budi Santoso',
      'avatar':
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200',
      'rating': 4,
      'review':
          'Good court overall. Parking can be a bit tricky during peak hours but the court itself is excellent.',
      'date': '2 weeks ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    _courtBloc = sl<CourtBloc>();
    _courtBloc.add(CourtDetailsFetchRequested(id: widget.courtId));
  }

  @override
  void dispose() {
    _courtBloc.close();
    super.dispose();
  }

  List<String> _getCourtPhotos(Court court) {
    final List<String> photos = [];

    // Always add thumbnail as first photo if available
    if (court.thumbnail != null) {
      photos.add(court.thumbnail!);
    }

    // Add other photos (excluding thumbnail if it's duplicated)
    if (court.photos != null && court.photos!.isNotEmpty) {
      for (final photo in court.photos!) {
        if (photo != court.thumbnail) {
          photos.add(photo);
        }
      }
    }

    // If no photos at all, use defaults
    if (photos.isEmpty) {
      return _defaultPhotos;
    }

    return photos;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _courtBloc,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<CourtBloc, CourtState>(
          builder: (context, state) {
            if (state is CourtLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CourtError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style: AppTextStyles.secondary(AppTextStyles.bodyLarge),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          _courtBloc.add(
                            CourtDetailsFetchRequested(id: widget.courtId),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Retry',
                            style: AppTextStyles.white(
                              AppTextStyles.bodyLargeSemibold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Go Back',
                          style: AppTextStyles.secondary(
                            AppTextStyles.bodyLargeSemibold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is CourtDetailsLoaded) {
              final court = state.court;
              return _buildCourtContent(court);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildCourtContent(Court court) {
    final photos = _getCourtPhotos(court);

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Image Section with overlapping info card
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildHeroSection(court, photos),
                  // Overlapping info card
                  Positioned(
                    bottom: -60,
                    left: 16,
                    right: 16,
                    child: _buildInfoCard(court),
                  ),
                ],
              ),
              const SizedBox(height: 80),
              // Additional content section
              _buildCourtInfoSection(court),
            ],
          ),
        ),
        // Floating bottom booking bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomBookingBar(court),
        ),
      ],
    );
  }

  Widget _buildBottomBookingBar(Court court) {
    final photos = _getCourtPhotos(court);
    final cityName = court.city?.name ?? 'Unknown';
    final categoryName = court.category?.name ?? court.material;

    return Container(
      padding: const EdgeInsets.only(bottom: 30),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      court.pricePerHourFormatted,
                      style: AppTextStyles.white(AppTextStyles.heading3),
                    ),
                    Text('/hour', style: AppTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Create open match button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateMatchPage(initialCourt: court),
                    ),
                  );
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups_2_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Book Now button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingPage(
                        courtId: court.id,
                        courtName: court.name,
                        courtImage: photos.isNotEmpty
                            ? photos.first
                            : _defaultPhotos.first,
                        location: cityName,
                        category: categoryName,
                        price: court.pricePerHour.toInt(),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('Book Now', style: AppTextStyles.heading4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(Court court) {
    final cityName = court.city?.name ?? 'Unknown';
    final categoryName = court.category?.name ?? court.material;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Court name
          Text(
            court.name,
            style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          // Info rows with rating badge on far right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side - Location, Category, Material, Booked
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location and Category
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(cityName, style: AppTextStyles.body),
                        const SizedBox(width: 12),
                        Icon(
                          court.material.toLowerCase() == 'cement'
                              ? Icons.grid_4x4_outlined
                              : Icons.grass_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(categoryName, style: AppTextStyles.body),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Material and Total Booked
                    Row(
                      children: [
                        Icon(
                          Icons.layers_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(court.material, style: AppTextStyles.body),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${court.bookingsThisMonth ?? 0} booked this month',
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Rating badge - far right, vertically centered
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '4.8',
                      style: AppTextStyles.captionSemibold.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(Court court, List<String> photos) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Image
        Container(
          width: double.infinity,
          height: 480,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
            image: DecorationImage(
              image: CachedNetworkImageProvider(photos[_selectedPhotoIndex]),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button and actions row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
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
                    // Action buttons
                    Row(
                      children: [
                        _buildActionButton(Icons.favorite_border_rounded),
                        const SizedBox(width: 8),
                        _buildActionButton(Icons.share_rounded),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Photo thumbnails - inside main image
        Positioned(
          bottom: 80,
          left: 16,
          right: 16,
          child: SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedPhotoIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPhotoIndex = index;
                    });
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    margin: EdgeInsets.only(
                      right: index < photos.length - 1 ? 10 : 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.white,
                        width: isSelected ? 3 : 2,
                      ),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(photos[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 22),
    );
  }

  Widget _buildCourtInfoSection(Court court) {
    final cityName = court.city?.name ?? 'Unknown';
    final courtFeatures = court.features ?? [];
    final aboutText =
        court.about ??
        'Professional padel court with high-quality facilities. Perfect for both beginners and experienced players.';
    final phoneNumber = court.phone ?? '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About this court', style: AppTextStyles.heading4),
                const SizedBox(height: 8),
                Text(
                  aboutText,
                  style: AppTextStyles.secondary(
                    AppTextStyles.bodyLarge,
                  ).copyWith(height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Court Features section
          if (courtFeatures.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Court Features', style: AppTextStyles.heading4),
                  const SizedBox(height: 12),
                  _buildFeaturesGrid(courtFeatures),
                ],
              ),
            ),
          if (courtFeatures.isNotEmpty) const SizedBox(height: 16),
          // Testimonials section
          _buildTestimonialsSection(),
          const SizedBox(height: 16),
          // Location section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with Location and Get Directions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Location', style: AppTextStyles.heading4),
                        const SizedBox(height: 4),
                        Text(court.name, style: AppTextStyles.body),
                      ],
                    ),
                    // Get Directions button
                    GestureDetector(
                      onTap: () async {
                        final query = Uri.encodeComponent(
                          '${court.name}, $cityName',
                        );
                        final url = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=$query',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions_outlined,
                              color: AppColors.textPrimary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text('Directions', style: AppTextStyles.buttonTiny),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Map placeholder with map-like design
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    color: const Color(0xFFE8E4DA),
                    child: Stack(
                      children: [
                        // Horizontal road lines
                        Positioned(
                          top: 40,
                          left: 0,
                          right: 0,
                          child: Container(height: 8, color: Colors.white),
                        ),
                        Positioned(
                          top: 100,
                          left: 0,
                          right: 0,
                          child: Container(height: 12, color: Colors.white),
                        ),
                        // Vertical road lines
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: 60,
                          child: Container(width: 6, color: Colors.white),
                        ),
                        Positioned(
                          top: 0,
                          bottom: 0,
                          right: 80,
                          child: Container(width: 10, color: Colors.white),
                        ),
                        // Green park areas
                        Positioned(
                          top: 55,
                          left: 80,
                          child: Container(
                            width: 50,
                            height: 35,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC5D9A4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: Container(
                            width: 40,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC5D9A4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        // Location pin in center
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: AppColors.textPrimary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  court.name,
                                  style: AppTextStyles.captionSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        court.address,
                        style: AppTextStyles.body.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Contact section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Contact info
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.store_outlined,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(court.name, style: AppTextStyles.heading5),
                      const SizedBox(height: 2),
                      Text('Court Owner', style: AppTextStyles.body),
                    ],
                  ),
                ),
                // Call button
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse('tel:$phoneNumber');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Icon(
                      Icons.call_outlined,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Message button
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse('sms:$phoneNumber');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Icon(
                      Icons.chat_outlined,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 150),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid(List<String> features) {
    final List<Widget> rows = [];

    for (int i = 0; i < features.length; i += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
          child: Row(
            children: [
              Expanded(child: _buildFeatureItem(features[i])),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < features.length
                    ? _buildFeatureItem(features[i + 1])
                    : Container(),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildFeatureItem(String name) {
    final icon = _featureIcons[name] ?? Icons.check_circle_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodySemibold.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Testimonials', style: AppTextStyles.heading4),
              Text(
                '${_testimonials.length} reviews',
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Carousel
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _testimonials.length,
            itemBuilder: (context, index) {
              final testimonial = _testimonials[index];
              return _buildTestimonialCard(testimonial, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonialCard(Map<String, dynamic> testimonial, int index) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: index < _testimonials.length - 1 ? 12 : 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(testimonial['avatar']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Name and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          testimonial['name'],
                          style: AppTextStyles.bodySemibold,
                        ),
                        const SizedBox(width: 6),
                        // Verified badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified,
                                size: 10,
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Verified',
                                style: AppTextStyles.tiny.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      testimonial['date'],
                      style: AppTextStyles.captionSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Review text
          Expanded(
            child: Text(
              testimonial['review'],
              style: AppTextStyles.caption.copyWith(height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          // 5 stars at bottom
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < testimonial['rating']
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 16,
                color: const Color(0xFFFFD700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
