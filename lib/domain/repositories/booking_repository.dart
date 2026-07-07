import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:padalpro/core/errors/failures.dart';
import 'package:padalpro/data/datasources/booking_remote_datasource.dart';
import 'package:padalpro/domain/entities/booking.dart';

/// Booking repository interface
abstract class BookingRepository {
  /// Get user's bookings with optional status filter
  Future<Either<Failure, List<Booking>>> getMyBookings({String? status});

  /// Get the user's next upcoming booking
  /// Returns null if no upcoming booking exists
  Future<Either<Failure, Booking?>> getNextBooking();

  /// Watch a booking by ID for realtime status/detail updates
  Stream<Booking?> watchBookingById(int bookingId);

  /// Create a new pending booking (locks time slots)
  Future<Either<Failure, CreateBookingResponse>> createBooking({
    required int courtId,
    required String date,
    required int startHour,
    required int endHour,
  });

  /// Confirm a pending booking with proof of payment
  Future<Either<Failure, Booking>> confirmBooking({
    required int bookingId,
    required XFile proofOfPayment,
  });

  /// Cancel a pending booking
  Future<Either<Failure, void>> cancelBooking(int bookingId);
}
