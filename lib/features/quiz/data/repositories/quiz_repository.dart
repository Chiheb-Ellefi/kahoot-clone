import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/quiz_model.dart';

/// Handles all quiz-related API calls.
class QuizRepository {
  final Dio _dio;

  QuizRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  // ─── Get all public quizzes ────────────────────────────────────────────
  /// GET /api/quizzes
  Future<List<QuizModel>> getPublicQuizzes() async {
    try {
      final response = await _dio.get(ApiConstants.quizzes);
      final list = response.data as List<dynamic>;
      return list
          .map((q) => QuizModel.fromJson(q as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Get my quizzes ────────────────────────────────────────────────────
  /// GET /api/quizzes/mine
  Future<List<QuizModel>> getMyQuizzes() async {
    try {
      final response = await _dio.get(ApiConstants.myQuizzes);
      final list = response.data as List<dynamic>;
      return list
          .map((q) => QuizModel.fromJson(q as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Get quiz by ID ────────────────────────────────────────────────────
  /// GET /api/quizzes/{id}
  Future<QuizModel> getQuizById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.quizById(id));
      return QuizModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Create quiz ───────────────────────────────────────────────────────
  /// POST /api/quizzes
  Future<QuizModel> createQuiz(QuizModel quiz) async {
    try {
      final response = await _dio.post(
        ApiConstants.quizzes,
        data: quiz.toCreateJson(),
      );
      return QuizModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Update quiz ───────────────────────────────────────────────────────
  /// PUT /api/quizzes/{id}
  Future<QuizModel> updateQuiz(QuizModel quiz) async {
    try {
      final response = await _dio.put(
        ApiConstants.quizById(quiz.id),
        data: quiz.toCreateJson(),
      );
      return QuizModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Delete quiz ───────────────────────────────────────────────────────
  /// DELETE /api/quizzes/{id}
  Future<void> deleteQuiz(String id) async {
    try {
      await _dio.delete(ApiConstants.quizById(id));
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Generate from PDF ─────────────────────────────────────────────────
  /// POST /api/quizzes/generate/pdf
  /// Uses [PlatformFile.bytes] so it works on Flutter Web (no dart:io needed).
  Future<QuizModel> generateFromPdf(PlatformFile file) async {
    try {
      final bytes = file.bytes;
      if (bytes == null) throw Exception('Could not read file bytes');
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: file.name),
      });
      final response = await _dio.post(ApiConstants.generatePdf, data: formData);
      return QuizModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Generate from Presentation (PPTX) ─────────────────────────────────
  /// POST /api/quizzes/generate/presentation
  /// Uses [PlatformFile.bytes] so it works on Flutter Web (no dart:io needed).
  Future<QuizModel> generateFromPptx(PlatformFile file) async {
    try {
      final bytes = file.bytes;
      if (bytes == null) throw Exception('Could not read file bytes');
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: file.name),
      });
      final response = await _dio.post(ApiConstants.generatePresentation, data: formData);
      return QuizModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Generate from AI Text Prompt ──────────────────────────────────────
  /// POST /api/quizzes/generate/ai
  Future<QuizModel> generateFromAi(String prompt) async {
    try {
      final response = await _dio.post(
        ApiConstants.generateAi,
        queryParameters: {'prompt': prompt, 'topic': prompt},
        data: {'prompt': prompt, 'topic': prompt},
      );
      return QuizModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }
}
