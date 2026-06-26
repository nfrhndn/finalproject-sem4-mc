import 'package:dartz/dartz.dart';
import 'package:padalpro/core/errors/failures.dart';
import 'package:padalpro/data/datasources/court_remote_datasource.dart';
import 'package:padalpro/domain/entities/court.dart';

/// Court repository interface
abstract class CourtRepository {
  /// Get featured courts
  Future<Either<Failure, List<Court>>> getFeaturedCourts({int? limit});

  /// Get popular courts
  Future<Either<Failure, List<Court>>> getPopularCourts({int? limit});

  /// Get all courts with optional filters (paginated)
  Future<Either<Failure, PaginatedCourtsResponse>> getCourts({
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
  Future<Either<Failure, Court>> getCourtDetails(int id);

  /// Get available time slots for a court on a specific date
  Future<Either<Failure, AvailableSlotsResponse>> getAvailableSlots(int courtId, String date);
}
