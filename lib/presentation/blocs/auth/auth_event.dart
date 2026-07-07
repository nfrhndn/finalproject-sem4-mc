import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

/// Base class for all auth events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check if user is already logged in
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Event to register a new user
class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String? phone;
  final String? gender;
  final XFile? profilePhoto;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    this.phone,
    this.gender,
    this.profilePhoto,
  });

  @override
  List<Object?> get props => [
    name,
    email,
    password,
    passwordConfirmation,
    phone,
    gender,
    profilePhoto,
  ];
}

/// Event to login with email and password
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Event to login with Google
class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// Event to send password reset email
class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Event to logout
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Event to reset auth state (clear errors)
class AuthStateReset extends AuthEvent {
  const AuthStateReset();
}

/// Event to update user profile
class AuthUpdateProfileRequested extends AuthEvent {
  final String name;
  final String email;
  final String? phone;
  final String? gender;
  final XFile? profilePhoto;
  final bool removePhoto;

  const AuthUpdateProfileRequested({
    required this.name,
    required this.email,
    this.phone,
    this.gender,
    this.profilePhoto,
    this.removePhoto = false,
  });

  @override
  List<Object?> get props => [
    name,
    email,
    phone,
    gender,
    profilePhoto,
    removePhoto,
  ];
}

/// Event to change user password
class AuthChangePasswordRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;
  final String newPasswordConfirmation;

  const AuthChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
    required this.newPasswordConfirmation,
  });

  @override
  List<Object?> get props => [
    currentPassword,
    newPassword,
    newPasswordConfirmation,
  ];
}
