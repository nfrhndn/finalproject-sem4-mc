import 'package:padalpro/core/errors/exceptions.dart';
import 'package:padalpro/data/models/court_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Time slot model for available slots API response
class TimeSlotModel {
  final String time;
  final bool available;

  const TimeSlotModel({required this.time, required this.available});

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      time: json['time'] as String,
      available: json['available'] as bool,
    );
  }
}

/// Available slots response model
class AvailableSlotsResponse {
  final int courtId;
  final String courtName;
  final String date;
  final double pricePerHour;
  final List<TimeSlotModel> slots;

  const AvailableSlotsResponse({
    required this.courtId,
    required this.courtName,
    required this.date,
    required this.pricePerHour,
    required this.slots,
  });

  factory AvailableSlotsResponse.fromJson(Map<String, dynamic> json) {
    final slotsData = json['slots'] as List<dynamic>;
    return AvailableSlotsResponse(
      courtId: (json['court_id'] as num).toInt(),
      courtName: json['court_name'] as String,
      date: json['date'] as String,
      pricePerHour: (json['price_per_hour'] is String)
          ? double.parse(json['price_per_hour'] as String)
          : (json['price_per_hour'] as num).toDouble(),
      slots: slotsData
          .map((slot) => TimeSlotModel.fromJson(slot as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Pagination info model
class PaginationInfo {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PaginationInfo({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMorePages => currentPage < lastPage;

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
    );
  }
}

/// Paginated courts response
class PaginatedCourtsResponse {
  final List<CourtModel> courts;
  final PaginationInfo pagination;

  const PaginatedCourtsResponse({
    required this.courts,
    required this.pagination,
  });
}

/// Remote data source for court operations
abstract class CourtRemoteDataSource {
  /// Get featured courts
  Future<List<CourtModel>> getFeaturedCourts({int? limit});

  /// Get popular courts
  Future<List<CourtModel>> getPopularCourts({int? limit});

  /// Get all courts with optional filters (paginated)
  Future<PaginatedCourtsResponse> getCourts({
    int? cityId,
    int? categoryId,
    String? material,
    String? search,
    int? minPrice,
    int? maxPrice,
    int? perPage,
    int? page,
  });

  /// Get court details by ID
  Future<CourtModel> getCourtDetails(int id);

  /// Get available time slots for a court on a specific date
  Future<AvailableSlotsResponse> getAvailableSlots(int courtId, String date);
}

/// Implementation of CourtRemoteDataSource using Supabase.
class CourtRemoteDataSourceImpl implements CourtRemoteDataSource {
  final SupabaseClient _supabaseClient;

  CourtRemoteDataSourceImpl({required SupabaseClient supabaseClient})
    : _supabaseClient = supabaseClient;

  @override
  Future<List<CourtModel>> getFeaturedCourts({int? limit}) async {
    try {
      var query = _baseCourtQuery().eq('is_featured', true).order('id');
      if (limit != null) {
        query = query.limit(limit);
      }
      final data = await query;
      return _hydrateCourtModels(data);
    } catch (e) {
      throw ServerException(message: 'Failed to load featured courts: $e');
    }
  }

  @override
  Future<List<CourtModel>> getPopularCourts({int? limit}) async {
    try {
      var query = _baseCourtQuery().order('id');
      if (limit != null) {
        query = query.limit(limit);
      }
      final data = await query;
      return _hydrateCourtModels(data);
    } catch (e) {
      throw ServerException(message: 'Failed to load popular courts: $e');
    }
  }

  @override
  Future<PaginatedCourtsResponse> getCourts({
    int? cityId,
    int? categoryId,
    String? material,
    String? search,
    int? minPrice,
    int? maxPrice,
    int? perPage,
    int? page,
  }) async {
    try {
      var query = _baseCourtQuery();
      if (cityId != null) query = query.eq('city_id', cityId);
      if (categoryId != null) query = query.eq('category_id', categoryId);
      if (material != null) query = query.eq('material', material);
      if (search != null && search.isNotEmpty) {
        query = query.ilike('name', '%$search%');
      }
      if (minPrice != null) query = query.gte('price_per_hour', minPrice);
      if (maxPrice != null) query = query.lte('price_per_hour', maxPrice);

      final int currentPage = page ?? 1;
      final int pageSize = perPage ?? 10;
      final int from = (currentPage - 1) * pageSize;
      final int to = from + pageSize - 1;
      final data = await query.order('id').range(from, to);
      final courts = await _hydrateCourtModels(data);

      return PaginatedCourtsResponse(
        courts: courts,
        pagination: PaginationInfo(
          currentPage: currentPage,
          lastPage: courts.length < pageSize ? currentPage : currentPage + 1,
          perPage: pageSize,
          total: (from + courts.length).toInt(),
        ),
      );
    } catch (e) {
      throw ServerException(message: 'Failed to load courts: $e');
    }
  }

  @override
  Future<CourtModel> getCourtDetails(int id) async {
    try {
      final data = await _baseCourtQuery().eq('id', id).single();
      final courts = await _hydrateCourtModels([data]);
      if (courts.isEmpty) {
        throw const ServerException(message: 'Court not found');
      }
      return courts.first;
    } catch (e) {
      throw ServerException(message: 'Failed to load court details: $e');
    }
  }

  @override
  Future<AvailableSlotsResponse> getAvailableSlots(
    int courtId,
    String date,
  ) async {
    try {
      final data = await _supabaseClient.rpc(
        'get_available_slots',
        params: {'p_court_id': courtId, 'p_date': date},
      );
      return AvailableSlotsResponse.fromJson(_asStringKeyMap(data));
    } catch (e) {
      throw ServerException(message: 'Failed to load available slots: $e');
    }
  }

  dynamic _baseCourtQuery() {
    return _supabaseClient
        .from('courts')
        .select(
          'id, city_id, category_id, name, thumbnail_url, about, material, '
          'price_per_hour, address, phone, status, is_featured',
        )
        .eq('status', 'active');
  }

  Future<List<CourtModel>> _hydrateCourtModels(dynamic data) async {
    final courts = _asList(data).map(_asStringKeyMap).toList();
    if (courts.isEmpty) return [];

    final courtIds = courts
        .map((court) => (court['id'] as num).toInt())
        .toSet();
    final cityIds = courts
        .map((court) => court['city_id'])
        .whereType<num>()
        .map((id) => id.toInt())
        .toSet();
    final categoryIds = courts
        .map((court) => court['category_id'])
        .whereType<num>()
        .map((id) => id.toInt())
        .toSet();

    final cityRows = cityIds.isEmpty
        ? <dynamic>[]
        : await _supabaseClient
              .from('cities')
              .select('id, name')
              .filter('id', 'in', _inExpression(cityIds));
    final categoryRows = categoryIds.isEmpty
        ? <dynamic>[]
        : await _supabaseClient
              .from('court_categories')
              .select('id, name')
              .filter('id', 'in', _inExpression(categoryIds));
    final imageRows = await _supabaseClient
        .from('court_images')
        .select('court_id, image_url, sort_order')
        .filter('court_id', 'in', _inExpression(courtIds))
        .order('sort_order')
        .order('id');
    final featureRows = await _supabaseClient
        .from('court_features')
        .select('court_id, name')
        .filter('court_id', 'in', _inExpression(courtIds))
        .order('id');

    final citiesById = {
      for (final row in _asList(cityRows).map(_asStringKeyMap))
        (row['id'] as num).toInt(): row,
    };
    final categoriesById = {
      for (final row in _asList(categoryRows).map(_asStringKeyMap))
        (row['id'] as num).toInt(): row,
    };
    final imagesByCourtId = <int, List<Map<String, dynamic>>>{};
    for (final row in _asList(imageRows).map(_asStringKeyMap)) {
      final courtId = (row['court_id'] as num).toInt();
      imagesByCourtId.putIfAbsent(courtId, () => []).add(row);
    }
    final featuresByCourtId = <int, List<Map<String, dynamic>>>{};
    for (final row in _asList(featureRows).map(_asStringKeyMap)) {
      final courtId = (row['court_id'] as num).toInt();
      featuresByCourtId.putIfAbsent(courtId, () => []).add(row);
    }

    return courts.map((court) {
      final courtId = (court['id'] as num).toInt();
      final cityId = (court['city_id'] as num?)?.toInt();
      final categoryId = (court['category_id'] as num?)?.toInt();

      return CourtModel.fromJson(
        _courtJson({
          ...court,
          'cities': cityId != null ? citiesById[cityId] : null,
          'court_categories': categoryId != null
              ? categoriesById[categoryId]
              : null,
          'court_images': imagesByCourtId[courtId] ?? [],
          'court_features': featuresByCourtId[courtId] ?? [],
        }),
      );
    }).toList();
  }

  Map<String, dynamic> _courtJson(Map<String, dynamic> json) {
    final images =
        (json['court_images'] as List<dynamic>? ?? [])
            .map((image) => image as Map<String, dynamic>)
            .toList()
          ..sort(
            (a, b) => ((a['sort_order'] as num?)?.toInt() ?? 0).compareTo(
              (b['sort_order'] as num?)?.toInt() ?? 0,
            ),
          );
    final features = (json['court_features'] as List<dynamic>? ?? [])
        .map((feature) => feature as Map<String, dynamic>)
        .toList();

    return {
      'id': (json['id'] as num).toInt(),
      'name': json['name'],
      'thumbnail': json['thumbnail_url'],
      'photos': images.map((image) => image['image_url'] as String).toList(),
      'about': json['about'],
      'features': features.map((feature) => feature['name'] as String).toList(),
      'material': json['material'],
      'price_per_hour': (json['price_per_hour'] as num).toDouble(),
      'price_per_hour_formatted': _formatRupiah(
        (json['price_per_hour'] as num).toInt(),
      ),
      'address': json['address'],
      'phone': json['phone'],
      'status': json['status'],
      'bookings_this_month': 0,
      'city': json['cities'] != null
          ? {
              'id': (json['cities']['id'] as num).toInt(),
              'name': json['cities']['name'],
            }
          : null,
      'category': json['court_categories'] != null
          ? {
              'id': (json['court_categories']['id'] as num).toInt(),
              'name': json['court_categories']['name'],
            }
          : null,
    };
  }

  String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return 'Rp $buffer';
  }

  Map<String, dynamic> _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ServerException(message: 'Unexpected Supabase response: $value');
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List<dynamic>) return value;
    if (value is List) return List<dynamic>.from(value);
    throw ServerException(message: 'Unexpected Supabase response: $value');
  }

  String _inExpression(Iterable<int> ids) {
    return '(${ids.join(',')})';
  }
}
