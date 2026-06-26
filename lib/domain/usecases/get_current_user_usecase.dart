import 'package:dartz/dartz.dart';
import 'package:padbro/core/errors/failures.dart';
import 'package:padbro/domain/entities/user.dart';
import 'package:padbro/domain/repositories/auth_repository.dart';

/// Get current user use case
/// Retrieves the currently authenticated user
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  Future<Either<Failure, User>> call() {
    return _repository.getCurrentUser();
  }
}
