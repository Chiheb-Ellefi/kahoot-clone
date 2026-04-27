import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/data/models/user_model.dart';

/// Handles user profile API calls.
class ProfileRepository {
  final Dio _dio;

  ProfileRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  // ─── Get profile ────────────────────────────────────────────────────────
  /// GET /api/users/profile
  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.profile);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Update profile ─────────────────────────────────────────────────────
  /// PUT /api/users/profile
  Future<UserModel> updateProfile({
    required String username,
    String? avatarUrl,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.profile,
        data: {
          'username': username,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        },
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }
}
