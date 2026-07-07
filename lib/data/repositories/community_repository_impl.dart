import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:padalpro/core/errors/exceptions.dart';
import 'package:padalpro/core/errors/failures.dart';
import 'package:padalpro/data/datasources/community_remote_datasource.dart';
import 'package:padalpro/domain/entities/community_match.dart';
import 'package:padalpro/domain/repositories/community_repository.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final CommunityRemoteDataSource _remoteDataSource;

  CommunityRepositoryImpl({required CommunityRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<CommunityMatch>>> getMatches({
    String? status,
    String? skillLevel,
  }) async {
    try {
      final matches = await _remoteDataSource.getMatches(
        status: status,
        skillLevel: skillLevel,
      );
      return Right(matches);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  @override
  Future<Either<Failure, CommunityMatch>> getMatchDetails(int matchId) async {
    try {
      final match = await _remoteDataSource.getMatchDetails(matchId);
      return Right(match);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  @override
  Future<Either<Failure, CommunityMatch>> createOpenMatch({
    required int courtId,
    required String date,
    required int startHour,
    required int endHour,
    required String skillLevel,
    String? notes,
  }) async {
    try {
      final match = await _remoteDataSource.createOpenMatch(
        courtId: courtId,
        date: date,
        startHour: startHour,
        endHour: endHour,
        skillLevel: skillLevel,
        notes: notes,
      );
      return Right(match);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  @override
  Future<Either<Failure, CommunityMatch>> joinMatch(int matchId) async {
    try {
      final match = await _remoteDataSource.joinMatch(matchId);
      return Right(match);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  @override
  Future<Either<Failure, CommunityMatch>> confirmSplitBill({
    required int billId,
    required XFile proofOfPayment,
  }) async {
    try {
      final match = await _remoteDataSource.confirmSplitBill(
        billId: billId,
        proofOfPayment: proofOfPayment,
      );
      return Right(match);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  @override
  Future<Either<Failure, CommunityMatch>> cancelMatch(int matchId) async {
    try {
      final match = await _remoteDataSource.cancelMatch(matchId);
      return Right(match);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  Failure _mapFailure(Object error) {
    if (error is NetworkException) {
      return NetworkFailure(message: error.message);
    }
    if (error is AuthException) {
      return AuthFailure(message: error.message);
    }
    if (error is ServerException) {
      return ServerFailure(
        message: error.message,
        statusCode: error.statusCode,
      );
    }
    return ServerFailure(message: 'An unexpected error occurred: $error');
  }
}
