import 'package:intl/intl.dart';
import 'package:padalpro/core/errors/exceptions.dart';
import 'package:padalpro/core/storage/storage_upload.dart';
import 'package:padalpro/data/models/booking_model.dart';
import 'package:image_picker/image_picker.dart';
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

  /// Watch a booking by ID for realtime status/detail updates
  Stream<BookingModel?> watchBookingById(int bookingId);

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
    required XFile proofOfPayment,
  });

  /// Cancel a pending booking
  Future<void> cancelBooking(int bookingId);
}

/// Implementation of BookingRemoteDataSource using Supabase.
class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final SupabaseClient _supabaseClient;

  BookingRemoteDataSourceImpl({required SupabaseClient supabaseClient})
    : _supabaseClient = supabaseClient;

  @override
  Future<List<BookingModel>> getMyBookings({String? status}) async {
    if (_supabaseClient.auth.currentUser == null) {
      return [];
    }

    try {
      final data = await _baseBookingQuery()
          .order('booking_date', ascending: false)
          .order('start_hour');
      final bookings = await _hydrateBookingModels(data);
      return _filterBookings(bookings, status);
    } catch (e) {
      throw ServerException(message: 'Failed to load bookings: $e');
    }
  }

  @override
  Future<BookingModel?> getNextBooking() async {
    if (_supabaseClient.auth.currentUser == null) {
      return null;
    }

    try {
      final data = await _baseBookingQuery()
          .gte('booking_date', DateFormat('yyyy-MM-dd').format(DateTime.now()))
          .filter('status', 'in', '(pending_payment,paid)')
          .order('booking_date')
          .order('start_hour')
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      final bookings = await _hydrateBookingModels([data]);
      return bookings.isEmpty ? null : bookings.first;
    } catch (e) {
      throw ServerException(message: 'Failed to load next booking: $e');
    }
  }

  @override
  Stream<BookingModel?> watchBookingById(int bookingId) {
    if (_supabaseClient.auth.currentUser == null) {
      return Stream.value(null);
    }

    return _supabaseClient
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('id', bookingId)
        .asyncMap((rows) async {
          if (rows.isEmpty) return null;
          final bookings = await _hydrateBookingModels(rows);
          return bookings.isEmpty ? null : bookings.first;
        });
  }

  @override
  Future<CreateBookingResponse> createBooking({
    required int courtId,
    required String date,
    required int startHour,
    required int endHour,
  }) async {
    if (_supabaseClient.auth.currentUser == null) {
      throw const AuthException(
        message: 'Please sign in before booking a court',
      );
    }

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

      return CreateBookingResponse.fromJson(_asStringKeyMap(data));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to create booking: $e');
    }
  }

  @override
  Future<BookingModel> confirmBooking({
    required int bookingId,
    required XFile proofOfPayment,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthException(message: 'User is not authenticated');
      }

      final extension = pickedFileExtension(proofOfPayment);
      final objectPath =
          '$userId/$bookingId-${DateTime.now().millisecondsSinceEpoch}.$extension';
      await uploadPickedFile(
        client: _supabaseClient,
        bucket: 'payment-proofs',
        objectPath: objectPath,
        file: proofOfPayment,
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
        'provider_order_id':
            'MANUAL-$bookingId-${DateTime.now().millisecondsSinceEpoch}',
        'amount': booking['grand_total'],
        'status': 'settlement',
        'raw_payload': {'proof_path': objectPath},
      });

      final refreshedBooking = await _baseBookingQuery()
          .eq('id', bookingId)
          .single();
      final bookings = await _hydrateBookingModels([refreshedBooking]);
      if (bookings.isEmpty) {
        throw const ServerException(message: 'Booking not found');
      }
      return bookings.first;
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
    return _supabaseClient
        .from('bookings')
        .select(
          'id, court_id, booking_date, start_hour, end_hour, total_hours, price_per_hour, '
          'sub_total, tax_amount, grand_total, status, created_at',
        );
  }

  Future<List<BookingModel>> _hydrateBookingModels(dynamic data) async {
    final bookings = _asList(data).map(_asStringKeyMap).toList();
    if (bookings.isEmpty) return [];

    final courtIds = bookings
        .map((booking) => booking['court_id'])
        .whereType<num>()
        .map((id) => id.toInt())
        .toSet();
    final courtRows = courtIds.isEmpty
        ? <dynamic>[]
        : await _supabaseClient
              .from('courts')
              .select(
                'id, city_id, category_id, name, thumbnail_url, material, address, phone',
              )
              .filter('id', 'in', _inExpression(courtIds));

    final courts = _asList(courtRows).map(_asStringKeyMap).toList();
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

    final citiesById = {
      for (final row in _asList(cityRows).map(_asStringKeyMap))
        (row['id'] as num).toInt(): row,
    };
    final categoriesById = {
      for (final row in _asList(categoryRows).map(_asStringKeyMap))
        (row['id'] as num).toInt(): row,
    };
    final courtsById = <int, Map<String, dynamic>>{};
    for (final court in courts) {
      final courtId = (court['id'] as num).toInt();
      final cityId = (court['city_id'] as num?)?.toInt();
      final categoryId = (court['category_id'] as num?)?.toInt();
      courtsById[courtId] = {
        ...court,
        'cities': cityId != null ? citiesById[cityId] : null,
        'court_categories': categoryId != null
            ? categoriesById[categoryId]
            : null,
      };
    }

    return bookings.map((booking) {
      final courtId = (booking['court_id'] as num?)?.toInt();
      return BookingModel.fromJson(
        _bookingJson({
          ...booking,
          'courts': courtId != null ? courtsById[courtId] : null,
        }),
      );
    }).toList();
  }

  Map<String, dynamic> _bookingJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['booking_date'] as String);
    final startHour = (json['start_hour'] as num).toInt();
    final endHour = (json['end_hour'] as num).toInt();
    final court = json['courts'] as Map<String, dynamic>? ?? {};

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
      'grand_total_formatted': _formatRupiah(
        (json['grand_total'] as num).toInt(),
      ),
      'status': json['status'],
      'court': {
        'id': (court['id'] as num?)?.toInt() ?? 0,
        'name': court['name'] ?? 'Unknown Court',
        'thumbnail': court['thumbnail_url'],
        'material': court['material'] ?? '-',
        'address': court['address'] ?? '-',
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

  List<BookingModel> _filterBookings(
    List<BookingModel> bookings,
    String? filter,
  ) {
    if (filter == null) return bookings;

    final now = DateTime.now();
    return bookings.where((booking) {
      return switch (filter) {
        'upcoming' =>
          booking.status == 'paid' && !_hasBookingEnded(booking, now),
        'pending' => booking.status == 'pending_payment',
        'completed' =>
          booking.status == 'paid' && _hasBookingEnded(booking, now),
        'cancelled' =>
          booking.status == 'cancelled' ||
              booking.status == 'expired' ||
              booking.status == 'failed',
        _ => booking.status == filter,
      };
    }).toList();
  }

  bool _hasBookingEnded(BookingModel booking, DateTime now) {
    final date = DateTime.tryParse(booking.date);
    if (date == null) return false;

    final endHour = int.tryParse(booking.endTime.split(':').first) ?? 0;
    final endDateTime = DateTime(date.year, date.month, date.day, endHour);
    return now.isAfter(endDateTime);
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
