import 'package:dartz/dartz.dart';
import 'package:padalpro/core/errors/failures.dart';
import 'package:padalpro/domain/entities/user.dart';
import 'package:padalpro/domain/repositories/auth_repository.dart';

/// Login use case parameters
class LoginParams {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });
}

/// Login use case
/// Handles user login business logic
class LoginUseCase {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  Future<Either<Failure, AuthResult>> call(LoginParams params) {
    return _repository.login(
      email: params.email,
      password: params.password,
    );
  }
}
