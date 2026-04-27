import 'package:equatable/equatable.dart';
import 'player_model.dart';

/// Represents the leaderboard snapshot at any point during or after a game.
class LeaderboardModel extends Equatable {
  final List<PlayerModel> players;
  final bool isFinal; // true when the game is over

  const LeaderboardModel({
    required this.players,
    this.isFinal = false,
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardModel(
      players:
          (json['players'] as List<dynamic>?)
              ?.map((p) => PlayerModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      isFinal: json['isFinal'] as bool? ?? false,
    );
  }

  /// Top 3 players for podium display.
  List<PlayerModel> get topThree => players.take(3).toList();

  @override
  List<Object?> get props => [players, isFinal];
}
