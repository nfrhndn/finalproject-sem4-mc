import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:padalpro/core/errors/exceptions.dart';
import 'package:padalpro/core/errors/failures.dart';
import 'package:padalpro/data/datasources/booking_remote_datasource.dart';
import 'package:padalpro/domain/entities/booking.dart';
import 'package:padalpro/domain/repositories/booking_repository.dart';

/// Implementation of BookingRepository
class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource _remoteDataSource;

  BookingRepositoryImpl({required BookingRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<Booking>>> getMyBookings({String? status}) async {
    try {
      final bookings = await _remoteDataSource.getMyBookings(status: status);
      return Right(bookings);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, Booking?>> getNextBooking() async {
    try {
      final booking = await _remoteDataSource.getNextBooking();
      return Right(booking);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Stream<Booking?> watchBookingById(int bookingId) {
    return _remoteDataSource.watchBookingById(bookingId).handleError((error) {
      throw ServerFailure(message: 'Failed to watch booking: $error');
    });
  }

  @override
  Future<Either<Failure, CreateBookingResponse>> createBooking({
    required int courtId,
    required String date,
    required int startHour,
    required int endHour,
  }) async {
    try {
      final response = await _remoteDataSource.createBooking(
        courtId: courtId,
        date: date,
        startHour: startHour,
        endHour: endHour,
      );
      return Right(response);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, Booking>> confirmBooking({
    required int bookingId,
    required XFile proofOfPayment,
  }) async {
    try {
      final booking = await _remoteDataSource.confirmBooking(
        bookingId: bookingId,
        proofOfPayment: proofOfPayment,
      );
      return Right(booking);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelBooking(int bookingId) async {
    try {
      await _remoteDataSource.cancelBooking(bookingId);
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }
}
