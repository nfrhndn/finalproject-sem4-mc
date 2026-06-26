import 'package:dartz/dartz.dart';
import 'package:padbro/core/errors/failures.dart';
import 'package:padbro/domain/repositories/auth_repository.dart';

/// Logout use case
/// Handles user logout business logic
class LogoutUseCase {
  final AuthRepository _repository;

  const LogoutUseCase(this._repository);

  Future<Either<Failure, void>> call() {
    return _repository.logout();
  }
}
