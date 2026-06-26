import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:padalpro/core/errors/failures.dart';
import 'package:padalpro/domain/entities/user.dart';
import 'package:padalpro/domain/repositories/auth_repository.dart';
import 'package:padalpro/presentation/blocs/auth/auth_event.dart';
import 'package:padalpro/presentation/blocs/auth/auth_state.dart';

/// BLoC for managing authentication state
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  /// Stores current user to persist across error states
  User? _currentUser;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthStateReset>(_onAuthStateReset);
    on<AuthUpdateProfileRequested>(_onAuthUpdateProfileRequested);
    on<AuthChangePasswordRequested>(_onAuthChangePasswordRequested);
  }

  /// Handle auth check on app startup
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final isLoggedIn = await _authRepository.isLoggedIn();
    if (!isLoggedIn) {
      emit(const AuthUnauthenticated());
      return;
    }

    // Try to get current user
    final result = await _authRepository.getCurrentUser();
    result.fold(
      (failure) {
        _currentUser = null;
        emit(const AuthUnauthenticated());
      },
      (user) {
        _currentUser = user;
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  /// Handle user registration
  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.register(
      name: event.name,
      email: event.email,
      password: event.password,
      passwordConfirmation: event.passwordConfirmation,
      phone: event.phone,
      gender: event.gender,
      profilePhoto: event.profilePhoto,
    );

    result.fold(
      (failure) => emit(_mapFailureToAuthError(failure)),
      (authResult) {
        _currentUser = authResult.user;
        emit(AuthAuthenticated(user: authResult.user));
      },
    );
  }

  /// Handle user login
  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.login(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(_mapFailureToAuthError(failure)),
      (authResult) {
        _currentUser = authResult.user;
        emit(AuthAuthenticated(user: authResult.user));
      },
    );
  }

  /// Handle user logout
  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    await _authRepository.logout();
    _currentUser = null;
    emit(const AuthUnauthenticated());
  }

  /// Reset auth state (clear errors)
  void _onAuthStateReset(
    AuthStateReset event,
    Emitter<AuthState> emit,
  ) {
    // If user is logged in, restore authenticated state
    if (_currentUser != null) {
      emit(AuthAuthenticated(user: _currentUser!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Handle profile update
  Future<void> _onAuthUpdateProfileRequested(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.updateProfile(
      name: event.name,
      email: event.email,
      phone: event.phone,
      gender: event.gender,
      profilePhoto: event.profilePhoto,
      removePhoto: event.removePhoto,
    );

    result.fold(
      (failure) => emit(_mapFailureToAuthError(failure)),
      (user) {
        _currentUser = user;
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  /// Handle password change
  Future<void> _onAuthChangePasswordRequested(
    AuthChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Check if user is logged in
    final currentUser = _currentUser;
    if (currentUser == null) {
      emit(const AuthError(message: 'You must be logged in to change password'));
      return;
    }

    emit(const AuthLoading());

    final result = await _authRepository.changePassword(
      currentPassword: event.currentPassword,
      newPassword: event.newPassword,
      newPasswordConfirmation: event.newPasswordConfirmation,
    );

    result.fold(
      (failure) => emit(_mapFailureToAuthError(failure)),
      (_) => emit(AuthAuthenticated(user: currentUser)),
    );
  }

  /// Map domain failures to auth error state
  AuthError _mapFailureToAuthError(Failure failure) {
    if (failure is ValidationFailure) {
      return AuthError(
        message: failure.message,
        validationErrors: failure.errors,
      );
    }
    return AuthError(message: failure.message);
  }
}
