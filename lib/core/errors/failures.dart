import 'package:equatable/equatable.dart';

/// Base failure class for handling errors in the domain layer
abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Failure for server-related errors
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

/// Failure for network/connection errors
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Network error. Please check your connection.',
  });
}

/// Failure for cache/local storage errors
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Cache error occurred',
  });
}

/// Failure for authentication errors
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed',
  });
}

/// Failure for validation errors
class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;

  const ValidationFailure({
    required super.message,
    this.errors,
  });

  /// Get the first error message from the validation errors
  String get firstError {
    if (errors == null || errors!.isEmpty) return message;
    final firstField = errors!.keys.first;
    final fieldErrors = errors![firstField];
    if (fieldErrors == null || fieldErrors.isEmpty) return message;
    return fieldErrors.first;
  }

  @override
  List<Object?> get props => [message, errors];
}
