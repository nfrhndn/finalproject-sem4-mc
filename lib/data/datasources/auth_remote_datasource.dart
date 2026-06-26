import 'dart:io';

import 'package:dio/dio.dart';
import 'package:padalpro/core/network/api_client.dart';
import 'package:padalpro/core/network/api_endpoints.dart';
import 'package:padalpro/data/models/user_model.dart';

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
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

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
    // Build form data for multipart request (handles file upload)
    final formData = FormData.fromMap({
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (gender != null && gender.isNotEmpty) 'gender': gender,
      if (profilePhoto != null)
        'photo': await MultipartFile.fromFile(
          profilePhoto.path,
          filename: 'profile_photo.jpg',
        ),
    });

    final response = await _apiClient.postMultipart(
      ApiEndpoints.register,
      data: formData,
    );

    // Backend wraps response in 'data' field
    final responseData = response.data as Map<String, dynamic>;
    return AuthResultModel.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  @override
  Future<AuthResultModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    // Backend wraps response in 'data' field
    final responseData = response.data as Map<String, dynamic>;
    return AuthResultModel.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    await _apiClient.post(ApiEndpoints.logout);
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get(ApiEndpoints.user);
    // Backend wraps response in 'data' -> 'user' field
    final responseData = response.data as Map<String, dynamic>;
    final userData = responseData['data'] as Map<String, dynamic>;
    return UserModel.fromJson(userData['user'] as Map<String, dynamic>);
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
    // Build form data for multipart request
    final formData = FormData.fromMap({
      'name': name,
      'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (gender != null && gender.isNotEmpty) 'gender': gender,
      if (profilePhoto != null)
        'photo': await MultipartFile.fromFile(
          profilePhoto.path,
          filename: 'profile_photo.jpg',
        ),
      if (removePhoto) 'remove_photo': '1',
    });

    final response = await _apiClient.postMultipart(
      ApiEndpoints.updateProfile,
      data: formData,
    );

    // Backend wraps response in 'data' -> 'user' field
    final responseData = response.data as Map<String, dynamic>;
    final userData = responseData['data'] as Map<String, dynamic>;
    return UserModel.fromJson(userData['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    await _apiClient.post(
      ApiEndpoints.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      },
    );
  }
}
