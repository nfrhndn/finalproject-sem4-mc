import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:padbro/core/errors/failures.dart';
import 'package:padbro/domain/entities/user.dart';

/// Auth repository interface (contract)
/// This defines what operations are available for authentication
abstract class AuthRepository {
  /// Register a new user
  /// Returns [AuthResult] on success or [Failure] on error
  Future<Either<Failure, AuthResult>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? gender,
    File? profilePhoto,
  });

  /// Login with email and password
  /// Returns [AuthResult] on success or [Failure] on error
  Future<Either<Failure, AuthResult>> login({
    required String email,
    required String password,
  });

  /// Logout the current user
  /// Returns [void] on success or [Failure] on error
  Future<Either<Failure, void>> logout();

  /// Get the current authenticated user
  /// Returns [User] on success or [Failure] on error
  Future<Either<Failure, User>> getCurrentUser();

  /// Check if user is logged in
  Future<bool> isLoggedIn();

  /// Get cached user data
  Future<User?> getCachedUser();

  /// Update user profile
  /// Returns [User] on success or [Failure] on error
  Future<Either<Failure, User>> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? gender,
    File? profilePhoto,
    bool removePhoto,
  });

  /// Change user password
  /// Returns [void] on success or [Failure] on error
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  });
}
