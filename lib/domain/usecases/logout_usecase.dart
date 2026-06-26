import 'package:dartz/dartz.dart';
import 'package:padalpro/core/errors/failures.dart';
import 'package:padalpro/domain/repositories/auth_repository.dart';

/// Logout use case
/// Handles user logout business logic
class LogoutUseCase {
  final AuthRepository _repository;

  const LogoutUseCase(this._repository);

  Future<Either<Failure, void>> call() {
    return _repository.logout();
  }
}
