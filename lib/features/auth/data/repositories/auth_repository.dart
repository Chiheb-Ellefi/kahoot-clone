import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/failures.dart';
import '../models/user_model.dart';

/// Handles all authentication API calls and local token persistence.
class AuthRepository {
  final Dio _dio;

  AuthRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  // ─── Register ──────────────────────────────────────────────────────────
  /// POST /api/auth/register
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {'username': username, 'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      final user = UserModel.fromJson(
        data['user'] as Map<String, dynamic>? ?? data,
      );
      if (token != null) await _saveToken(token, user);
      return user;
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Login ─────────────────────────────────────────────────────────────
  /// POST /api/auth/login
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      final user = UserModel.fromJson(
        data['user'] as Map<String, dynamic>? ?? data,
      );
      if (token != null) await _saveToken(token, user);
      return user;
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Get current user ──────────────────────────────────────────────────
  /// GET /api/auth/me — requires Bearer token
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Logout ────────────────────────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.usernameKey);
  }

  // ─── Check authentication ──────────────────────────────────────────────
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  // ─── Persist token + user info locally ────────────────────────────────
  Future<void> _saveToken(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.userIdKey, user.id);
    await prefs.setString(AppConstants.usernameKey, user.username);
  }
}
