import 'package:equatable/equatable.dart';
import 'package:padalpro/domain/entities/user.dart';

/// Base class for all auth states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - unknown authentication status
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state - authentication in progress
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state - user is logged in
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Password changed successfully state
class AuthPasswordChanged extends AuthState {
  final User user;

  const AuthPasswordChanged({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Unauthenticated state - user is not logged in
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Error state - authentication failed
class AuthError extends AuthState {
  final String message;
  final Map<String, List<String>>? validationErrors;

  const AuthError({
    required this.message,
    this.validationErrors,
  });

  /// Get the first error message for a specific field
  String? getFieldError(String field) {
    if (validationErrors == null) return null;
    final errors = validationErrors![field];
    if (errors == null || errors.isEmpty) return null;
    return errors.first;
  }

  @override
  List<Object?> get props => [message, validationErrors];
}
