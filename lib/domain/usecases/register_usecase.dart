import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:padalpro/core/errors/failures.dart';
import 'package:padalpro/domain/entities/user.dart';
import 'package:padalpro/domain/repositories/auth_repository.dart';

/// Register use case parameters
class RegisterParams {
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String? phone;
  final String? gender;
  final File? profilePhoto;

  const RegisterParams({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    this.phone,
    this.gender,
    this.profilePhoto,
  });
}

/// Register use case
/// Handles user registration business logic
class RegisterUseCase {
  final AuthRepository _repository;

  const RegisterUseCase(this._repository);

  Future<Either<Failure, AuthResult>> call(RegisterParams params) {
    return _repository.register(
      name: params.name,
      email: params.email,
      password: params.password,
      passwordConfirmation: params.passwordConfirmation,
      phone: params.phone,
      gender: params.gender,
      profilePhoto: params.profilePhoto,
    );
  }
}
