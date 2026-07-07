/// Exception thrown when there is a server error
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({
    this.message = 'Server error occurred',
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

/// Exception thrown when there is a network/connection error
class NetworkException implements Exception {
  final String message;

  const NetworkException({
    this.message = 'Network error occurred. Please check your connection.',
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when there is a cache/local storage error
class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Cache error occurred'});

  @override
  String toString() => 'CacheException: $message';
}

/// Exception thrown when authentication fails
class AuthException implements Exception {
  final String message;

  const AuthException({this.message = 'Authentication failed'});

  @override
  String toString() => 'AuthException: $message';
}

/// Exception thrown when registration succeeded but email confirmation is required.
class EmailConfirmationRequiredException implements Exception {
  final String email;
  final String message;

  const EmailConfirmationRequiredException({
    required this.email,
    this.message =
        'Registration succeeded. Please confirm your email before signing in.',
  });

  @override
  String toString() => 'EmailConfirmationRequiredException: $message';
}

/// Exception thrown for validation errors
class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;

  const ValidationException({this.message = 'Validation failed', this.errors});

  @override
  String toString() => 'ValidationException: $message';
}
