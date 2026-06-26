import 'dart:io';

import 'package:intl/intl.dart';
import 'package:padalpro/core/errors/exceptions.dart';
import 'package:padalpro/data/models/booking_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

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
  final SupabaseClient _supabaseClient;

  BookingRemoteDataSourceImpl({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  @override
  Future<List<BookingModel>> getMyBookings({String? status}) async {
    try {
      var query = _baseBookingQuery();
      if (status != null) {
        query = query.eq('status', status);
      }

      final data = await query.order('booking_date', ascending: false).order('start_hour');
      return data.map((booking) => BookingModel.fromJson(_bookingJson(booking))).toList();
    } catch (e) {
      throw ServerException(message: 'Failed to load bookings: $e');
    }
  }

  @override
  Future<BookingModel?> getNextBooking() async {
    try {
      final data = await _baseBookingQuery()
          .gte('booking_date', DateFormat('yyyy-MM-dd').format(DateTime.now()))
          .filter('status', 'in', '(pending_payment,paid)')
          .order('booking_date')
          .order('start_hour')
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      return BookingModel.fromJson(_bookingJson(data));
    } catch (e) {
      throw ServerException(message: 'Failed to load next booking: $e');
    }
  }

  @override
  Future<CreateBookingResponse> createBooking({
    required int courtId,
    required String date,
    required int startHour,
    required int endHour,
  }) async {
    try {
      final data = await _supabaseClient.rpc(
        'create_booking',
        params: {
          'p_court_id': courtId,
          'p_date': date,
          'p_start_hour': startHour,
          'p_end_hour': endHour,
        },
      );

      return CreateBookingResponse.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (e) {
      throw ServerException(message: 'Failed to create booking: $e');
    }
  }

  @override
  Future<BookingModel> confirmBooking({
    required int bookingId,
    required File proofOfPayment,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthException(message: 'User is not authenticated');
      }

      final extension = proofOfPayment.path.split('.').last;
      final objectPath =
          '$userId/$bookingId-${DateTime.now().millisecondsSinceEpoch}.$extension';
      await _supabaseClient.storage.from('payment-proofs').upload(
            objectPath,
            proofOfPayment,
            fileOptions: const FileOptions(upsert: true),
          );

      final booking = await _supabaseClient
          .from('bookings')
          .update({'status': 'paid'})
          .eq('id', bookingId)
          .select()
          .single();

      await _supabaseClient.from('payments').insert({
        'booking_id': bookingId,
        'user_id': userId,
        'provider': 'manual',
        'provider_order_id': 'MANUAL-$bookingId-${DateTime.now().millisecondsSinceEpoch}',
        'amount': booking['grand_total'],
        'status': 'settlement',
        'raw_payload': {'proof_path': objectPath},
      });

      final refreshedBooking = await _baseBookingQuery().eq('id', bookingId).single();
      return BookingModel.fromJson(_bookingJson(refreshedBooking));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to confirm booking: $e');
    }
  }

  @override
  Future<void> cancelBooking(int bookingId) async {
    try {
      await _supabaseClient
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);
    } catch (e) {
      throw ServerException(message: 'Failed to cancel booking: $e');
    }
  }

  dynamic _baseBookingQuery() {
    return _supabaseClient.from('bookings').select(
          'id, booking_date, start_hour, end_hour, total_hours, price_per_hour, '
          'sub_total, tax_amount, grand_total, status, created_at, '
          'courts(id, name, thumbnail_url, material, address, phone, '
          'cities(id, name), court_categories(id, name))',
        );
  }

  Map<String, dynamic> _bookingJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['booking_date'] as String);
    final startHour = (json['start_hour'] as num).toInt();
    final endHour = (json['end_hour'] as num).toInt();
    final court = json['courts'] as Map<String, dynamic>;

    return {
      'id': (json['id'] as num).toInt(),
      'date': DateFormat('yyyy-MM-dd').format(date),
      'date_formatted': DateFormat('EEEE, dd MMM yyyy').format(date),
      'start_time': '${startHour.toString().padLeft(2, '0')}:00',
      'end_time': '${endHour.toString().padLeft(2, '0')}:00',
      'time_slot':
          '${startHour.toString().padLeft(2, '0')}:00 - ${endHour.toString().padLeft(2, '0')}:00',
      'total_hours': (json['total_hours'] as num).toInt(),
      'price_per_hour': (json['price_per_hour'] as num).toInt(),
      'sub_total': (json['sub_total'] as num).toInt(),
      'tax_amount': (json['tax_amount'] as num).toInt(),
      'grand_total': (json['grand_total'] as num).toInt(),
      'grand_total_formatted': _formatRupiah((json['grand_total'] as num).toInt()),
      'status': json['status'],
      'court': {
        'id': (court['id'] as num).toInt(),
        'name': court['name'],
        'thumbnail': court['thumbnail_url'],
        'material': court['material'],
        'address': court['address'],
        'phone': court['phone'],
        'city': court['cities'] != null
            ? {
                'id': (court['cities']['id'] as num).toInt(),
                'name': court['cities']['name'],
              }
            : null,
        'category': court['court_categories'] != null
            ? {
                'id': (court['court_categories']['id'] as num).toInt(),
                'name': court['court_categories']['name'],
              }
            : null,
      },
      'created_at': json['created_at'],
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
}
