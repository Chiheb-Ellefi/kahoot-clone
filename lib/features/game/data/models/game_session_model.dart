import 'package:equatable/equatable.dart';
import 'player_model.dart';

/// Represents a complete game session.
class GameSessionModel extends Equatable {
  final String sessionId;
  final String gamePin;
  final String quizId;
  final String status; // 'WAITING' | 'ACTIVE' | 'FINISHED'
  final List<PlayerModel> players;
  final int currentQuestionIndex;

  const GameSessionModel({
    required this.sessionId,
    required this.gamePin,
    required this.quizId,
    required this.status,
    required this.players,
    required this.currentQuestionIndex,
  });

  factory GameSessionModel.fromJson(Map<String, dynamic> json) {
    return GameSessionModel(
      sessionId: json['sessionId']?.toString() ?? '',
      gamePin: json['gamePin']?.toString() ?? '',
      quizId: json['quizId']?.toString() ?? '',
      status: json['status'] as String? ?? 'WAITING',
      players:
          (json['players'] as List<dynamic>?)
              ?.map((p) => PlayerModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      currentQuestionIndex:
          (json['currentQuestionIndex'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isWaiting => status == 'WAITING';
  bool get isActive => status == 'ACTIVE';
  bool get isFinished => status == 'FINISHED';

  @override
  List<Object?> get props => [
        sessionId,
        gamePin,
        quizId,
        status,
        players,
        currentQuestionIndex,
      ];
}
