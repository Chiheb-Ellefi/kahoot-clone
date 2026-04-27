/// API Constants — all endpoint definitions for the QuizBlitz backend
class ApiConstants {
  ApiConstants._();

  // Base URL for the Spring Boot backend
  static const String baseUrl = 'http://localhost:8080';

  // ─── Auth ────────────────────────────────────────────────────────────────
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String me = '/api/auth/me';

  // ─── Quizzes ─────────────────────────────────────────────────────────────
  static const String quizzes = '/api/quizzes';
  static const String myQuizzes = '/api/quizzes/mine';
  static String quizById(String id) => '/api/quizzes/$id';

  static const String generatePdf = '/api/quizzes/generate/pdf';
  static const String generatePresentation = '/api/quizzes/generate/presentation';
  static const String generateAi = '/api/quizzes/generate/ai';

  // ─── Game Sessions ────────────────────────────────────────────────────────
  static const String createGame = '/api/games/create';
  static const String joinGame = '/api/games/join';
  static const String joinAnonymousGame = '/api/games/join-anonymous';
  static String gameSession(String sessionId) => '/api/games/$sessionId';
  static String startGame(String sessionId) => '/api/games/$sessionId/start';
  static String currentQuestion(String sessionId) =>
      '/api/games/$sessionId/current-question';
  static String submitAnswer(String sessionId) =>
      '/api/games/$sessionId/answer';
  static String nextQuestion(String sessionId) => '/api/games/$sessionId/next';
  static String leaderboard(String sessionId) =>
      '/api/games/$sessionId/leaderboard';
  static String results(String sessionId) => '/api/games/$sessionId/results';

  // ─── Profile ──────────────────────────────────────────────────────────────
  static const String profile = '/api/users/profile';
}
