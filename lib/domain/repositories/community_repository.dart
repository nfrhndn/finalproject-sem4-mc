import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:padalpro/core/errors/failures.dart';
import 'package:padalpro/domain/entities/community_match.dart';

abstract class CommunityRepository {
  Future<Either<Failure, List<CommunityMatch>>> getMatches({
    String? status,
    String? skillLevel,
  });

  Future<Either<Failure, CommunityMatch>> getMatchDetails(int matchId);

  Future<Either<Failure, CommunityMatch>> createOpenMatch({
    required int courtId,
    required String date,
    required int startHour,
    required int endHour,
    required String skillLevel,
    String? notes,
  });

  Future<Either<Failure, CommunityMatch>> joinMatch(int matchId);

  Future<Either<Failure, CommunityMatch>> confirmSplitBill({
    required int billId,
    required XFile proofOfPayment,
  });

  Future<Either<Failure, CommunityMatch>> cancelMatch(int matchId);
}
