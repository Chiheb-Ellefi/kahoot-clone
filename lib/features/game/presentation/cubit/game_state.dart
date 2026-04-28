import 'package:equatable/equatable.dart';
import '../../../game/data/models/game_session_model.dart';
import '../../../game/data/models/leaderboard_model.dart';
import '../../../quiz/data/models/question_model.dart';

/// States for the Game feature.
abstract class GameState extends Equatable {
  const GameState();
  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {
  const GameInitial();
}

class GameLoading extends GameState {
  const GameLoading();
}

/// Host has created the game — show the PIN lobby.
class GameCreated extends GameState {
  final String sessionId;
  final String gamePin;
  const GameCreated({required this.sessionId, required this.gamePin});
  @override
  List<Object?> get props => [sessionId, gamePin];
}

/// Player has joined — waiting in lobby.
class GameJoined extends GameState {
  final String sessionId;
  final String playerId;
  const GameJoined({required this.sessionId, required this.playerId});
  @override
  List<Object?> get props => [sessionId, playerId];
}

/// Session details updated (used for polling the lobby player list).
class GameSessionUpdated extends GameState {
  final GameSessionModel session;
  const GameSessionUpdated(this.session);
  @override
  List<Object?> get props => [session];
}

/// A question is now active.
class GameQuestionActive extends GameState {
  final QuestionModel question;
  final String sessionId;
  const GameQuestionActive({required this.question, required this.sessionId});
  @override
  List<Object?> get props => [question, sessionId];
}

/// An answer was submitted and the result is back.
class GameAnswerResult extends GameState {
  final bool isCorrect;
  final int pointsEarned;
  const GameAnswerResult({required this.isCorrect, required this.pointsEarned});
  @override
  List<Object?> get props => [isCorrect, pointsEarned];
}
class GameRoundComplete extends GameState {
  const GameRoundComplete();
}
class GameShowLeaderboard extends GameState {
  final LeaderboardModel leaderboard;
  const GameShowLeaderboard(this.leaderboard);
  @override List<Object?> get props => [leaderboard];
}

/// Leaderboard data is available (between questions or final).
class GameLeaderboardLoaded extends GameState {
  final LeaderboardModel leaderboard;
  const GameLeaderboardLoaded(this.leaderboard);
  @override
  List<Object?> get props => [leaderboard];
}

/// Game has finished — final results available.
class GameFinished extends GameState {
  final LeaderboardModel results;
  const GameFinished(this.results);
  @override
  List<Object?> get props => [results];
}

class GameError extends GameState {
  final String message;
  const GameError(this.message);
  @override
  List<Object?> get props => [message];
}
