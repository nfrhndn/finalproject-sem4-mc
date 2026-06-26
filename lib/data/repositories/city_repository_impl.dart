import 'package:dartz/dartz.dart';
import 'package:padalpro/core/errors/exceptions.dart';
import 'package:padalpro/core/errors/failures.dart';
import 'package:padalpro/data/datasources/city_remote_datasource.dart';
import 'package:padalpro/domain/entities/city.dart';
import 'package:padalpro/domain/repositories/city_repository.dart';

/// Implementation of CityRepository
class CityRepositoryImpl implements CityRepository {
  final CityRemoteDataSource _remoteDataSource;

  CityRepositoryImpl({required CityRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<City>>> getCities() async {
    try {
      final cities = await _remoteDataSource.getCities();
      return Right(cities);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, City>> getCity(String identifier) async {
    try {
      final city = await _remoteDataSource.getCity(identifier);
      return Right(city);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }
}
