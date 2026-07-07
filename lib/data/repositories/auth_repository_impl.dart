import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:padalpro/core/errors/exceptions.dart';
import 'package:padalpro/core/errors/failures.dart';
import 'package:padalpro/data/datasources/auth_local_datasource.dart';
import 'package:padalpro/data/datasources/auth_remote_datasource.dart';
import 'package:padalpro/domain/entities/user.dart';
import 'package:padalpro/domain/repositories/auth_repository.dart';

/// Implementation of AuthRepository
/// Connects remote and local data sources, handles error mapping
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  @override
  Future<Either<Failure, AuthResult>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? gender,
    XFile? profilePhoto,
  }) async {
    try {
      final authResult = await _remoteDataSource.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
        gender: gender,
        profilePhoto: profilePhoto,
      );

      // Cache token and user data
      await _localDataSource.cacheToken(authResult.token);
      await _localDataSource.cacheUser(authResult.user);

      return Right(authResult.toEntity());
    } on EmailConfirmationRequiredException catch (e) {
      return Left(
        AuthEmailConfirmationRequiredFailure(
          email: e.email,
          message: e.message,
        ),
      );
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message, errors: e.errors));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> login({
    required String email,
    required String password,
  }) async {
    try {
      final authResult = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      // Cache token and user data
      await _localDataSource.cacheToken(authResult.token);
      await _localDataSource.cacheUser(authResult.user);

      return Right(authResult.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message, errors: e.errors));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> signInWithGoogle() async {
    try {
      await _remoteDataSource.signInWithGoogle();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _remoteDataSource.resetPassword(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Call remote logout to invalidate token on server
      await _remoteDataSource.logout();
      // Clear local cache
      await _localDataSource.clearCache();
      return const Right(null);
    } on NetworkException catch (e) {
      // Even if network fails, clear local cache
      await _localDataSource.clearCache();
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      // Even if server fails, clear local cache
      await _localDataSource.clearCache();
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      // Clear local cache anyway
      await _localDataSource.clearCache();
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      // Update cached user
      await _localDataSource.cacheUser(user);
      return Right(user);
    } on NetworkException catch (e) {
      // Try to get cached user if network fails
      final cachedUser = await _localDataSource.getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser);
      }
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      // Clear cache if auth fails
      await _localDataSource.clearCache();
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final hasCachedToken = await _localDataSource.isLoggedIn();
    return hasCachedToken || _remoteDataSource.hasActiveSession();
  }

  @override
  Future<User?> getCachedUser() async {
    return await _localDataSource.getCachedUser();
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? gender,
    XFile? profilePhoto,
    bool removePhoto = false,
  }) async {
    try {
      final user = await _remoteDataSource.updateProfile(
        name: name,
        email: email,
        phone: phone,
        gender: gender,
        profilePhoto: profilePhoto,
        removePhoto: removePhoto,
      );

      // Update cached user
      await _localDataSource.cacheUser(user);

      return Right(user);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message, errors: e.errors));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      await _remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      );

      return const Right(null);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message, errors: e.errors));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }
}
