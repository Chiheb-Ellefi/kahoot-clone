import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/failures.dart';
import '../models/game_session_model.dart';
import '../models/leaderboard_model.dart';
import '../../../quiz/data/models/question_model.dart';

/// Holds the result of creating a game session.
class CreateGameResult {
  final String sessionId;
  final String gamePin;
  const CreateGameResult({required this.sessionId, required this.gamePin});
}

/// Holds the result of joining a game session.
class JoinGameResult {
  final String sessionId;
  final String playerId;
  const JoinGameResult({required this.sessionId, required this.playerId});
}

/// Handles all game-session API calls.
class GameRepository {
  final Dio _dio;

  GameRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  // ─── Create game session (host) ────────────────────────────────────────
  /// POST /api/games/create
  Future<CreateGameResult> createGame(String quizId) async {
    try {
      final response = await _dio.post(
        ApiConstants.createGame,
        data: {'quizId': quizId},
      );
      final data = response.data as Map<String, dynamic>;
      return CreateGameResult(
        sessionId: data['sessionId']?.toString() ?? '',
        gamePin: data['gamePin']?.toString() ?? '',
      );
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Join game session (player) ────────────────────────────────────────
  /// POST /api/games/join
  Future<JoinGameResult> joinGame({
    required String pin,
    required String nickname,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.joinGame,
        data: {'pin': pin, 'nickname': nickname},
      );
      final data = response.data as Map<String, dynamic>;
      return JoinGameResult(
        sessionId: data['sessionId']?.toString() ?? '',
        playerId: data['playerId']?.toString() ?? '',
      );
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Join game session anonymously (player) ──────────────────────────────
  /// POST /api/games/join-anonymous
  Future<JoinGameResult> joinAnonymousGame({
    required String pin,
    required String nickname,
    String? avatarUrl,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.joinAnonymousGame,
        data: {
          'pin': pin,
          'nickname': nickname,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return JoinGameResult(
        sessionId: data['sessionId']?.toString() ?? '',
        playerId: data['playerId']?.toString() ?? '',
      );
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Get session details ───────────────────────────────────────────────
  /// GET /api/games/{sessionId}
  Future<GameSessionModel> getSession(String sessionId) async {
    try {
      final response = await _dio.get(ApiConstants.gameSession(sessionId));
      return GameSessionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Start the game (host) ─────────────────────────────────────────────
  /// POST /api/games/{sessionId}/start
  Future<void> startGame(String sessionId) async {
    try {
      await _dio.post(ApiConstants.startGame(sessionId));
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Get current question ──────────────────────────────────────────────
  /// GET /api/games/{sessionId}/current-question
  Future<QuestionModel> getCurrentQuestion(String sessionId) async {
    try {
      final response = await _dio.get(
        ApiConstants.currentQuestion(sessionId),
      );
      return QuestionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Submit answer (player) ────────────────────────────────────────────
  /// POST /api/games/{sessionId}/answer
  /// Returns { isCorrect, pointsEarned }
  Future<Map<String, dynamic>> submitAnswer({
    required String sessionId,
    required String questionId,
    required String answerId,
    required String playerId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.submitAnswer(sessionId),
        data: {
          'questionId': questionId,
          'answerId': answerId,
          'playerId': playerId,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Advance to next question (host) ───────────────────────────────────
  /// POST /api/games/{sessionId}/next
  Future<void> nextQuestion(String sessionId) async {
    try {
      await _dio.post(ApiConstants.nextQuestion(sessionId));
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Get leaderboard ──────────────────────────────────────────────────
  /// GET /api/games/{sessionId}/leaderboard
  Future<LeaderboardModel> getLeaderboard(String sessionId) async {
    try {
      final response = await _dio.get(ApiConstants.leaderboard(sessionId));
      return LeaderboardModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }

  // ─── Get final results ─────────────────────────────────────────────────
  /// GET /api/games/{sessionId}/results
  Future<LeaderboardModel> getResults(String sessionId) async {
    try {
      final response = await _dio.get(ApiConstants.results(sessionId));
      return LeaderboardModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToFailure(e);
    }
  }
}
