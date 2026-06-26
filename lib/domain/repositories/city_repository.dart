import 'package:dartz/dartz.dart';
import 'package:padalpro/core/errors/failures.dart';
import 'package:padalpro/domain/entities/city.dart';

/// City repository interface
abstract class CityRepository {
  /// Get all cities
  Future<Either<Failure, List<City>>> getCities();

  /// Get a single city by ID or slug
  Future<Either<Failure, City>> getCity(String identifier);
}
