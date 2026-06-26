import 'package:dartz/dartz.dart';
import 'package:padbro/core/errors/failures.dart';
import 'package:padbro/domain/entities/city.dart';

/// City repository interface
abstract class CityRepository {
  /// Get all cities
  Future<Either<Failure, List<City>>> getCities();

  /// Get a single city by ID or slug
  Future<Either<Failure, City>> getCity(String identifier);
}
