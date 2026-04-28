/// App-wide constants for QuizBlitz
class AppConstants {
  AppConstants._();

  // App name
  static const String appName = 'Quizzo';

  // Shared Preferences keys
  static const String tokenKey = 'jwt_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';

  // Supabase storage bucket names
  static const String quizCoversBucket = 'quiz-covers';
  static const String questionImagesBucket = 'question-images';
  static const String avatarsBucket = 'avatars';
  static const String documentsBucket = 'documents';

  // Game defaults
  static const int defaultTimeLimit = 30; // seconds
  static const int defaultPoints = 1000;

  // Polling interval for game state (ms)
  static const int pollIntervalMs = 2000;

  // Answer-result auto-advance delay (ms)
  static const int answerResultDelayMs = 2000;

  // Quizzo answer colors
  static const List<String> answerColors = [
    '#5DCAA5', // Success (Turbo Teal)
    '#534AB7', // Primary (Electric Violet)
    '#F0997B', // Error (Fiesta Coral)
    '#FAC775', // Accent (Zest Amber)
  ];
}
