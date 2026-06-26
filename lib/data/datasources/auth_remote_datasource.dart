import 'dart:io';

import 'package:padalpro/core/errors/exceptions.dart';
import 'package:padalpro/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

/// Remote data source for authentication operations
abstract class AuthRemoteDataSource {
  /// Register a new user
  /// Throws [ServerException], [NetworkException], or [ValidationException] on failure
  Future<AuthResultModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? gender,
    File? profilePhoto,
  });

  /// Login with email and password
  /// Throws [ServerException], [NetworkException], or [AuthException] on failure
  Future<AuthResultModel> login({
    required String email,
    required String password,
  });

  /// Login with Google SSO
  Future<void> signInWithGoogle();

  /// Check whether Supabase already has a persisted auth session
  bool hasActiveSession();

  /// Logout the current user
  /// Throws [ServerException] or [NetworkException] on failure
  Future<void> logout();

  /// Get the current authenticated user
  /// Throws [ServerException], [NetworkException], or [AuthException] on failure
  Future<UserModel> getCurrentUser();

  /// Update user profile
  /// Throws [ServerException], [NetworkException], or [ValidationException] on failure
  Future<UserModel> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? gender,
    File? profilePhoto,
    bool removePhoto,
  });

  /// Change user password
  /// Throws [ServerException], [NetworkException], or [ValidationException] on failure
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  });
}

/// Implementation of AuthRemoteDataSource using ApiClient
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabaseClient;

  AuthRemoteDataSourceImpl({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  @override
  Future<AuthResultModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? gender,
    File? profilePhoto,
  }) async {
    if (password != passwordConfirmation) {
      throw const ValidationException(message: 'Password confirmation does not match');
    }

    try {
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (gender != null && gender.isNotEmpty) 'gender': gender,
        },
      );

      final session = response.session;
      final authUser = response.user;
      if (authUser == null || session == null) {
        throw const AuthException(
          message: 'Registration succeeded. Please confirm your email before signing in.',
        );
      }

      final photoUrl = profilePhoto != null
          ? await _uploadProfilePhoto(authUser.id, profilePhoto)
          : null;
      final user = await _upsertAndFetchProfile(
        id: authUser.id,
        name: name,
        email: email,
        phone: phone,
        gender: gender,
        photoUrl: photoUrl,
      );

      return AuthResultModel(user: user, token: session.accessToken);
    } on AuthException {
      rethrow;
    } on ValidationException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AuthException(message: e.message);
    } on StorageException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: 'Failed to register: $e');
    }
  }

  @override
  Future<AuthResultModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = response.session;
      final authUser = response.user;
      if (authUser == null || session == null) {
        throw const AuthException(message: 'Invalid email or password');
      }

      final user = await _fetchProfile(authUser.id);
      return AuthResultModel(user: user, token: session.accessToken);
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AuthException(message: e.message);
    } catch (e) {
      throw ServerException(message: 'Failed to login: $e');
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      final started = await _supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.padalpro.app://login-callback/',
      );
      if (!started) {
        throw const AuthException(message: 'Unable to start Google sign in');
      }
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AuthException(message: e.message);
    } catch (e) {
      throw ServerException(message: 'Failed to start Google sign in: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _supabaseClient.auth.signOut();
  }

  @override
  bool hasActiveSession() {
    return _supabaseClient.auth.currentSession != null;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final authUser = _supabaseClient.auth.currentUser;
    if (authUser == null) {
      throw const AuthException(message: 'User is not authenticated');
    }
    return _fetchProfile(authUser.id);
  }

  @override
  Future<UserModel> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? gender,
    File? profilePhoto,
    bool removePhoto = false,
  }) async {
    try {
      final authUser = _supabaseClient.auth.currentUser;
      if (authUser == null) {
        throw const AuthException(message: 'User is not authenticated');
      }

      final photoUrl = profilePhoto != null
          ? await _uploadProfilePhoto(authUser.id, profilePhoto)
          : removePhoto
              ? null
              : undefinedPhotoUrl;

      return _upsertAndFetchProfile(
        id: authUser.id,
        name: name,
        email: email,
        phone: phone,
        gender: gender,
        photoUrl: photoUrl,
        preserveExistingPhoto: !removePhoto && profilePhoto == null,
      );
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AuthException(message: e.message);
    } on StorageException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: 'Failed to update profile: $e');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    if (newPassword != newPasswordConfirmation) {
      throw const ValidationException(message: 'Password confirmation does not match');
    }

    try {
      await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthApiException catch (e) {
      throw AuthException(message: e.message);
    } catch (e) {
      throw ServerException(message: 'Failed to change password: $e');
    }
  }

  static const String undefinedPhotoUrl = '__preserve_existing_photo__';

  Future<UserModel> _fetchProfile(String id) async {
    final data = await _supabaseClient
        .from('profiles')
        .select()
        .eq('id', id)
        .single();

    return _profileFromSupabase(data);
  }

  Future<UserModel> _upsertAndFetchProfile({
    required String id,
    required String name,
    required String email,
    String? phone,
    String? gender,
    String? photoUrl,
    bool preserveExistingPhoto = false,
  }) async {
    final payload = <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'gender': gender,
    };

    if (!preserveExistingPhoto) {
      payload['photo_url'] = photoUrl;
    }

    final data = await _supabaseClient
        .from('profiles')
        .upsert(payload)
        .select()
        .single();

    return _profileFromSupabase(data);
  }

  Future<String> _uploadProfilePhoto(String userId, File file) async {
    final extension = file.path.split('.').last;
    final objectPath = '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _supabaseClient.storage.from('profile-photos').upload(
          objectPath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return _supabaseClient.storage.from('profile-photos').getPublicUrl(objectPath);
  }

  UserModel _profileFromSupabase(Map<String, dynamic> json) {
    return UserModel.fromJson({
      'id': json['id'],
      'name': json['name'],
      'email': json['email'],
      'phone': json['phone'],
      'gender': json['gender'],
      'photo': json['photo_url'],
      'email_verified_at': null,
      'created_at': json['created_at'],
    });
  }
}
