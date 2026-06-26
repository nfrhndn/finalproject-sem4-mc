import 'package:padalpro/core/network/api_client.dart';
import 'package:padalpro/core/network/api_endpoints.dart';
import 'package:padalpro/data/models/court_model.dart';

/// Time slot model for available slots API response
class TimeSlotModel {
  final String time;
  final bool available;

  const TimeSlotModel({
    required this.time,
    required this.available,
  });

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
      courtId: json['court_id'] as int,
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

/// Implementation of CourtRemoteDataSource using ApiClient
class CourtRemoteDataSourceImpl implements CourtRemoteDataSource {
  final ApiClient _apiClient;

  CourtRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<CourtModel>> getFeaturedCourts({int? limit}) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) {
      queryParams['limit'] = limit;
    }

    final response = await _apiClient.get(
      ApiEndpoints.featuredCourts,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>;
    final courtsData = data['courts'] as List<dynamic>;

    return courtsData
        .map((json) => CourtModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<CourtModel>> getPopularCourts({int? limit}) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) {
      queryParams['limit'] = limit;
    }

    final response = await _apiClient.get(
      ApiEndpoints.popularCourts,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>;
    final courtsData = data['courts'] as List<dynamic>;

    return courtsData
        .map((json) => CourtModel.fromJson(json as Map<String, dynamic>))
        .toList();
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
    final queryParams = <String, dynamic>{};
    if (cityId != null) queryParams['city_id'] = cityId;
    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (material != null) queryParams['material'] = material;
    if (search != null) queryParams['search'] = search;
    if (minPrice != null) queryParams['min_price'] = minPrice;
    if (maxPrice != null) queryParams['max_price'] = maxPrice;
    if (perPage != null) queryParams['per_page'] = perPage;
    if (page != null) queryParams['page'] = page;

    final response = await _apiClient.get(
      ApiEndpoints.courts,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>;
    final courtsData = data['courts'] as List<dynamic>;
    final paginationData = data['pagination'] as Map<String, dynamic>;

    final courts = courtsData
        .map((json) => CourtModel.fromJson(json as Map<String, dynamic>))
        .toList();

    return PaginatedCourtsResponse(
      courts: courts,
      pagination: PaginationInfo.fromJson(paginationData),
    );
  }

  @override
  Future<CourtModel> getCourtDetails(int id) async {
    final response = await _apiClient.get(ApiEndpoints.courtDetails(id.toString()));

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>;
    return CourtModel.fromJson(data['court'] as Map<String, dynamic>);
  }

  @override
  Future<AvailableSlotsResponse> getAvailableSlots(int courtId, String date) async {
    final response = await _apiClient.get(
      ApiEndpoints.courtAvailableSlots(courtId.toString()),
      queryParameters: {'date': date},
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>;
    return AvailableSlotsResponse.fromJson(data);
  }
}
