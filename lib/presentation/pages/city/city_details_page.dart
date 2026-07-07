import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:padalpro/core/injection/injection_container.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:padalpro/domain/entities/court.dart';
import 'package:padalpro/presentation/blocs/court/court.dart';
import 'package:padalpro/presentation/pages/court/court_details_page.dart';

class CityDetailsPage extends StatefulWidget {
  final int cityId;
  final String cityName;
  final String cityImage;
  final String courtsCount;

  const CityDetailsPage({
    super.key,
    required this.cityId,
    required this.cityName,
    required this.cityImage,
    required this.courtsCount,
  });

  @override
  State<CityDetailsPage> createState() => _CityDetailsPageState();
}

class _CityDetailsPageState extends State<CityDetailsPage> {
  // Filter states
  String _selectedCategory = 'All';
  String _selectedMaterial = 'All';

  // Local BLoC instance for city courts
  late final CourtBloc _courtBloc;

  final List<String> categories = ['All', 'Indoor', 'Outdoor'];
  final List<String> materials = ['All', 'Grass', 'Cement'];

  // Default court images
  final List<String> _defaultImages = [
    'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=1200',
    'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=1200',
    'https://images.unsplash.com/photo-1526232761682-d26e03ac148e?w=1200',
    'https://plus.unsplash.com/premium_photo-1723924861073-5764741be57c?w=1200',
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=1200',
  ];

  @override
  void initState() {
    super.initState();
    _courtBloc = sl<CourtBloc>();
    _fetchCourts();
  }

  @override
  void dispose() {
    _courtBloc.close();
    super.dispose();
  }

  void _fetchCourts() {
    _courtBloc.add(
      CourtsFetchRequested(
        cityId: widget.cityId,
        material: _selectedMaterial != 'All' ? _selectedMaterial : null,
      ),
    );
  }

  List<Court> _filterCourts(List<Court> courts) {
    return courts.where((court) {
      if (_selectedCategory != 'All' &&
          court.category?.name != _selectedCategory) {
        return false;
      }
      if (_selectedMaterial != 'All' && court.material != _selectedMaterial) {
        return false;
      }
      return true;
    }).toList();
  }

  String _getCourtImage(Court court, int index) {
    return court.thumbnail ?? _defaultImages[index % _defaultImages.length];
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _courtBloc,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Banner with City Image and Location Icon
                  _buildHeroSection(),
                  const SizedBox(height: 24),
                  // Courts Section
                  _buildCourtsSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            // Floating Bottom Nav with Selected Filters
            Positioned(
              left: 16,
              right: 16,
              bottom: 30,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Selected filter chips with X to remove
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (_selectedCategory != 'All')
                              _buildSelectedFilterChip(_selectedCategory, () {
                                setState(() => _selectedCategory = 'All');
                              }),
                            if (_selectedMaterial != 'All')
                              _buildSelectedFilterChip(_selectedMaterial, () {
                                setState(() => _selectedMaterial = 'All');
                              }),
                            if (_selectedCategory == 'All' &&
                                _selectedMaterial == 'All')
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'No filters applied',
                                  style: AppTextStyles.body,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Filter icon button
                    GestureDetector(
                      onTap: () => _showFilterSheet(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourtsSection() {
    return BlocBuilder<CourtBloc, CourtState>(
      builder: (context, state) {
        if (state is CourtLoading) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is CourtError) {
          return Padding(
            padding: const EdgeInsets.all(48),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _fetchCourts,
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
                        style: AppTextStyles.white(AppTextStyles.bodySemibold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is CourtsLoaded) {
          final allCourts = state.courts;
          final filteredCourts = _filterCourts(allCourts);

          if (allCourts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.sports_tennis_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No courts available in ${widget.cityName}',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // All Courts Section
              _buildAllCourtsSection(filteredCourts),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHeroSection() {
    // Alternative city images
    final Map<String, String> cityImages = {
      'Jakarta':
          'https://images.unsplash.com/photo-1546874177-9e664107314e?w=1600',
      'Bandung':
          'https://images.unsplash.com/photo-1584810359583-96fc3448beaa?w=1600',
      'Surabaya':
          'https://images.unsplash.com/photo-1590559899731-a382839e5549?w=1600',
      'Bali':
          'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=1600',
      'Jogja':
          'https://images.unsplash.com/photo-1565371767810-ef913a6c4e5e?w=1600',
    };

    final bannerImage = cityImages[widget.cityName] ?? widget.cityImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner with location icon
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Image Banner
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(80),
                  bottomRight: Radius.circular(80),
                ),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(bannerImage),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
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
                ),
              ),
            ),
            // Location Icon Circle - positioned at bottom center, half overlapping
            Positioned(
              bottom: -30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.textPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
        // City name and total courts
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.cityName, style: AppTextStyles.heading1),
              const SizedBox(height: 2),
              Text(
                widget.courtsCount,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.only(left: 14, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.white(AppTextStyles.bodySemibold)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllCourtsSection(List<Court> courts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Courts',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${courts.length} courts',
                style: AppTextStyles.secondary(AppTextStyles.bodySemibold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (courts.isEmpty)
          _buildEmptyState('No courts match your filters')
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: courts.asMap().entries.map((entry) {
                return _buildCourtCard(entry.value, entry.key);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Text(
          message,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCourtCard(Court court, int index) {
    final imageUrl = _getCourtImage(court, index);
    final cityName = court.city?.name ?? widget.cityName;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourtDetailsPage(courtId: court.id),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Court Image with category badge
            Container(
              width: 100,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Category badge - bottom left
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            court.material.toLowerCase() == 'cement'
                                ? Icons.grid_4x4_outlined
                                : Icons.grass_outlined,
                            size: 12,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            court.material,
                            style: AppTextStyles.tiny.copyWith(height: 1.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Court Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Court name
                  Text(
                    court.name,
                    style: AppTextStyles.heading3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Location + Category row
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          cityName,
                          style: AppTextStyles.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Price
                  Text(
                    '${court.pricePerHourFormatted}/hr',
                    style: AppTextStyles.buttonSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter Courts', style: AppTextStyles.heading2),
                    GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          _selectedCategory = 'All';
                          _selectedMaterial = 'All';
                        });
                      },
                      child: Text(
                        'Reset',
                        style: AppTextStyles.secondary(
                          AppTextStyles.bodyLargeSemibold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Category filter
                Text('Category', style: AppTextStyles.bodyLargeSemibold),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          category,
                          style: AppTextStyles.bodySemibold.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Material filter
                Text(
                  'Surface Material',
                  style: AppTextStyles.bodyLargeSemibold,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: materials.map((material) {
                    final isSelected = _selectedMaterial == material;
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          _selectedMaterial = material;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          material,
                          style: AppTextStyles.bodySemibold.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {});
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Center(
                        child: Text(
                          'Apply Filters',
                          style: AppTextStyles.heading4,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
