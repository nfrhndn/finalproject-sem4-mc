import 'package:dartz/dartz.dart';
import 'package:padalpro/core/errors/failures.dart';
import 'package:padalpro/domain/entities/user.dart';
import 'package:padalpro/domain/repositories/auth_repository.dart';

/// Get current user use case
/// Retrieves the currently authenticated user
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  Future<Either<Failure, User>> call() {
    return _repository.getCurrentUser();
  }
}
