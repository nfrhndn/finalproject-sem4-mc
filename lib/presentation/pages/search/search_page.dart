import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:padalpro/core/injection/injection_container.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:padalpro/data/datasources/search_local_datasource.dart';
import 'package:padalpro/domain/entities/court.dart';
import 'package:padalpro/presentation/blocs/court/court.dart';
import 'package:padalpro/presentation/pages/court/court_details_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _searchLocalDataSource = sl<SearchLocalDataSource>();

  late final CourtBloc _courtBloc;
  late Future<List<String>> _recentSearchesFuture;

  bool _hasSearched = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<Court> _searchResults = [];
  String? _errorMessage;
  String _currentQuery = '';

  // Pagination state
  int _currentPage = 1;
  bool _hasMorePages = false;
  int _totalResults = 0;
  static const int _perPage = 10;

  // Popular searches (static - city and category names)
  final List<Map<String, dynamic>> _popularSearches = [
    {'label': 'Jakarta', 'icon': Icons.location_city_rounded},
    {'label': 'Bandung', 'icon': Icons.location_city_rounded},
    {'label': 'Surabaya', 'icon': Icons.location_city_rounded},
    {'label': 'Indoor', 'icon': Icons.home_rounded},
    {'label': 'Outdoor', 'icon': Icons.park_rounded},
    {'label': 'Grass', 'icon': Icons.grass_rounded},
    {'label': 'Cement', 'icon': Icons.grid_4x4_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _courtBloc = sl<CourtBloc>();
    _recentSearchesFuture = _loadRecentSearches();
    _scrollController.addListener(_onScroll);

    // Auto focus the search field when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _courtBloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreIfNeeded();
    }
  }

  void _loadMoreIfNeeded() {
    if (!_isLoadingMore && _hasMorePages && _hasSearched) {
      _loadMore();
    }
  }

  Future<List<String>> _loadRecentSearches() async {
    return _searchLocalDataSource.getRecentSearches();
  }

  void _refreshRecentSearches() {
    setState(() {
      _recentSearchesFuture = _loadRecentSearches();
    });
  }

  Future<void> _removeRecentSearch(String query) async {
    await _searchLocalDataSource.removeRecentSearch(query);
    _refreshRecentSearches();
  }

  Future<void> _clearAllRecent() async {
    await _searchLocalDataSource.clearRecentSearches();
    _refreshRecentSearches();
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) return;

    // Save to recent searches
    await _searchLocalDataSource.addRecentSearch(query);

    setState(() {
      _recentSearchesFuture = _loadRecentSearches();
      _hasSearched = true;
      _isLoading = true;
      _errorMessage = null;
      _searchResults = [];
      _currentQuery = query;
      _currentPage = 1;
      _hasMorePages = false;
      _totalResults = 0;
    });

    // Fetch from backend (page 1)
    _courtBloc.add(
      CourtsFetchRequested(search: query, perPage: _perPage, page: 1),
    );
  }

  void _loadMore() {
    setState(() {
      _isLoadingMore = true;
    });

    _courtBloc.add(
      CourtsFetchRequested(
        search: _currentQuery,
        perPage: _perPage,
        page: _currentPage + 1,
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _hasSearched = false;
      _searchResults = [];
      _errorMessage = null;
      _currentQuery = '';
      _currentPage = 1;
      _hasMorePages = false;
      _totalResults = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CourtBloc, CourtState>(
      bloc: _courtBloc,
      listener: (context, state) {
        if (state is CourtsLoaded) {
          setState(() {
            if (_isLoadingMore) {
              // Append results for load more
              _searchResults = [..._searchResults, ...state.courts];
              _isLoadingMore = false;
            } else {
              // Replace results for new search
              _searchResults = state.courts;
              _isLoading = false;
            }
            _currentPage = state.pagination.currentPage;
            _hasMorePages = state.pagination.hasMorePages;
            _totalResults = state.pagination.total;
          });
        } else if (state is CourtError) {
          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
            _errorMessage = state.message;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // Header with search field
            _buildHeader(),
            // Content
            Expanded(
              child: _hasSearched
                  ? _buildSearchResultsView()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          // Recent searches
                          _buildRecentSearchesFuture(),
                          // Popular searches
                          _buildPopularSearches(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 16,
        16,
        20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Search field
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: AppTextStyles.heading5.copyWith(
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: 'Search courts, locations...',
                  hintStyle: AppTextStyles.heading5.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: _clearSearch,
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                onSubmitted: _onSearch,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearchesFuture() {
    return FutureBuilder<List<String>>(
      future: _recentSearchesFuture,
      builder: (context, snapshot) {
        final searches = snapshot.data ?? const <String>[];
        if (snapshot.connectionState == ConnectionState.waiting ||
            searches.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            _buildRecentSearches(searches),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildRecentSearches(List<String> recentSearches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Searches', style: AppTextStyles.heading4),
            GestureDetector(
              onTap: _clearAllRecent,
              child: Text(
                'Clear All',
                style: AppTextStyles.secondary(AppTextStyles.bodySemibold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: recentSearches.asMap().entries.map((entry) {
              final index = entry.key;
              final search = entry.value;
              final isLast = index == recentSearches.length - 1;

              return Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      _searchController.text = search;
                      _onSearch(search);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(search, style: AppTextStyles.bodyLarge),
                          ),
                          GestureDetector(
                            onTap: () => _removeRecentSearch(search),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        height: 1,
                        color: AppColors.textSecondary.withValues(alpha: 0.2),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Popular Searches', style: AppTextStyles.heading4),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _popularSearches.map((search) {
            return GestureDetector(
              onTap: () {
                _searchController.text = search['label'] as String;
                _onSearch(search['label'] as String);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      search['icon'] as IconData,
                      color: AppColors.textPrimary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      search['label'] as String,
                      style: AppTextStyles.bodySemibold.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchResultsView() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildErrorState(),
      );
    }

    if (_searchResults.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildEmptyState(),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount:
          _searchResults.length +
          2, // +1 for header, +1 for loading/end indicator
      itemBuilder: (context, index) {
        if (index == 0) {
          // Header row
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Search Results', style: AppTextStyles.heading4),
                Text(
                  '$_totalResults courts found',
                  style: AppTextStyles.bodySemibold.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        if (index == _searchResults.length + 1) {
          // Bottom indicator
          if (_isLoadingMore) {
            return _buildLoadingMoreIndicator();
          } else if (!_hasMorePages) {
            return _buildEndOfListIndicator();
          }
          return const SizedBox.shrink();
        }

        // Court card
        return _buildCourtCard(_searchResults[index - 1]);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching...',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildEndOfListIndicator() {
    if (_searchResults.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(child: Text('No more results', style: AppTextStyles.body)),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: AppTextStyles.heading4.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            _errorMessage ?? 'Please try again',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _onSearch(_searchController.text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'Try Again',
                style: AppTextStyles.white(AppTextStyles.bodySemibold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No courts found',
            style: AppTextStyles.heading4.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text('Try a different search term', style: AppTextStyles.body),
        ],
      ),
    );
  }

  Widget _buildCourtCard(Court court) {
    final categoryName = court.category?.name ?? court.material;

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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image with badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20),
                  ),
                  child: Image.network(
                    court.thumbnail ??
                        'https://plus.unsplash.com/premium_photo-1723924861073-5764741be57c?w=800',
                    height: 130,
                    width: 130,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 130,
                        width: 130,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported_outlined),
                      );
                    },
                  ),
                ),
                // Category badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      categoryName,
                      style: AppTextStyles.tiny.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      court.name,
                      style: AppTextStyles.heading5,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            court.city?.name ?? 'Unknown',
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Material
                    Row(
                      children: [
                        Icon(
                          court.material.toLowerCase() == 'cement'
                              ? Icons.grid_4x4_outlined
                              : Icons.grass_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(court.material, style: AppTextStyles.caption),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Price
                    Row(
                      children: [
                        Text(
                          court.pricePerHourFormatted,
                          style: AppTextStyles.bodyLargeSemibold.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text('/hr', style: AppTextStyles.captionSmall),
                      ],
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
}
