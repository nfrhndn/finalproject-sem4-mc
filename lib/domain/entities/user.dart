import 'package:equatable/equatable.dart';

/// User entity representing the core user data
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? gender;
  final String? profilePhotoUrl;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.gender,
    this.profilePhotoUrl,
    this.emailVerifiedAt,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        gender,
        profilePhotoUrl,
        emailVerifiedAt,
        createdAt,
      ];
}

/// Auth result containing user and token
class AuthResult extends Equatable {
  final User user;
  final String token;

  const AuthResult({
    required this.user,
    required this.token,
  });

  @override
  List<Object?> get props => [user, token];
}
