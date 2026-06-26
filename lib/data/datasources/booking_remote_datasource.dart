import 'dart:io';

import 'package:dio/dio.dart';
import 'package:padalpro/core/network/api_client.dart';
import 'package:padalpro/core/network/api_endpoints.dart';
import 'package:padalpro/data/models/booking_model.dart';

/// Response model for creating a booking
class CreateBookingResponse {
  final BookingModel booking;
  final String? expiresAt;
  final int? expiresInSeconds;

  const CreateBookingResponse({
    required this.booking,
    this.expiresAt,
    this.expiresInSeconds,
  });

  factory CreateBookingResponse.fromJson(Map<String, dynamic> json) {
    return CreateBookingResponse(
      booking: BookingModel.fromJson(json['booking'] as Map<String, dynamic>),
      expiresAt: json['expires_at'] as String?,
      expiresInSeconds: json['expires_in_seconds'] != null
          ? (json['expires_in_seconds'] as num).toInt()
          : null,
    );
  }
}

/// Remote data source for booking operations
abstract class BookingRemoteDataSource {
  /// Get user's bookings with optional status filter
  Future<List<BookingModel>> getMyBookings({String? status});

  /// Get the user's next upcoming booking
  Future<BookingModel?> getNextBooking();

  /// Create a new pending booking (locks time slots)
  Future<CreateBookingResponse> createBooking({
    required int courtId,
    required String date,
    required int startHour,
    required int endHour,
  });

  /// Confirm a pending booking with proof of payment
  Future<BookingModel> confirmBooking({
    required int bookingId,
    required File proofOfPayment,
  });

  /// Cancel a pending booking
  Future<void> cancelBooking(int bookingId);
}

/// Implementation of BookingRemoteDataSource using ApiClient
class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final ApiClient _apiClient;

  BookingRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<BookingModel>> getMyBookings({String? status}) async {
    final queryParams = <String, dynamic>{};
    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await _apiClient.get(
      ApiEndpoints.bookings,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>;
    final bookingsData = data['bookings'] as List<dynamic>;

    return bookingsData
        .map((booking) => BookingModel.fromJson(booking as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BookingModel?> getNextBooking() async {
    final response = await _apiClient.get(ApiEndpoints.nextBooking);

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>;
    final bookingData = data['booking'];

    if (bookingData == null) {
      return null;
    }

    return BookingModel.fromJson(bookingData as Map<String, dynamic>);
  }

  @override
  Future<CreateBookingResponse> createBooking({
    required int courtId,
    required String date,
    required int startHour,
    required int endHour,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.createBooking,
      data: {
        'court_id': courtId,
        'date': date,
        'start_hour': startHour,
        'end_hour': endHour,
      },
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>;

    return CreateBookingResponse.fromJson(data);
  }

  @override
  Future<BookingModel> confirmBooking({
    required int bookingId,
    required File proofOfPayment,
  }) async {
    final formData = FormData.fromMap({
      'proof_of_payment': await MultipartFile.fromFile(
        proofOfPayment.path,
        filename: 'proof_of_payment.jpg',
      ),
    });

    final response = await _apiClient.post(
      ApiEndpoints.confirmBooking(bookingId),
      data: formData,
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>;

    return BookingModel.fromJson(data['booking'] as Map<String, dynamic>);
  }

  @override
  Future<void> cancelBooking(int bookingId) async {
    await _apiClient.delete(ApiEndpoints.cancelBooking(bookingId));
  }
}
