import 'package:padbro/domain/entities/user.dart';

/// Data model for User with JSON serialization
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.gender,
    super.profilePhotoUrl,
    super.emailVerifiedAt,
    required super.createdAt,
  });

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      profilePhotoUrl: json['photo'] as String?,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'gender': gender,
      'photo': profilePhotoUrl,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create UserModel from User entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      gender: user.gender,
      profilePhotoUrl: user.profilePhotoUrl,
      emailVerifiedAt: user.emailVerifiedAt,
      createdAt: user.createdAt,
    );
  }
}

/// Data model for AuthResult with JSON serialization
class AuthResultModel {
  final UserModel user;
  final String token;

  const AuthResultModel({
    required this.user,
    required this.token,
  });

  /// Create AuthResultModel from JSON (API response)
  factory AuthResultModel.fromJson(Map<String, dynamic> json) {
    return AuthResultModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }

  /// Convert to domain entity
  AuthResult toEntity() {
    return AuthResult(
      user: user,
      token: token,
    );
  }
}
