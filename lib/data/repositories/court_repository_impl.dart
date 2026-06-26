import 'package:dartz/dartz.dart';
import 'package:padalpro/core/errors/exceptions.dart';
import 'package:padalpro/core/errors/failures.dart';
import 'package:padalpro/data/datasources/court_remote_datasource.dart';
import 'package:padalpro/domain/entities/court.dart';
import 'package:padalpro/domain/repositories/court_repository.dart';

/// Implementation of CourtRepository
class CourtRepositoryImpl implements CourtRepository {
  final CourtRemoteDataSource _remoteDataSource;

  CourtRepositoryImpl({required CourtRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<Court>>> getFeaturedCourts({int? limit}) async {
    try {
      final courts = await _remoteDataSource.getFeaturedCourts(limit: limit);
      return Right(courts);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Court>>> getPopularCourts({int? limit}) async {
    try {
      final courts = await _remoteDataSource.getPopularCourts(limit: limit);
      return Right(courts);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedCourtsResponse>> getCourts({
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
      final response = await _remoteDataSource.getCourts(
        cityId: cityId,
        categoryId: categoryId,
        material: material,
        search: search,
        minPrice: minPrice,
        maxPrice: maxPrice,
        perPage: perPage,
        page: page,
      );
      return Right(response);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, Court>> getCourtDetails(int id) async {
    try {
      final court = await _remoteDataSource.getCourtDetails(id);
      return Right(court);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, AvailableSlotsResponse>> getAvailableSlots(int courtId, String date) async {
    try {
      final slots = await _remoteDataSource.getAvailableSlots(courtId, date);
      return Right(slots);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }
}
