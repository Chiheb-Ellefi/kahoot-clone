import 'package:equatable/equatable.dart';

/// Represents a player participating in a game session.
class PlayerModel extends Equatable {
  final String id;
  final String nickname;
  final int score;
  final int rank;
  final String? avatarUrl;

  const PlayerModel({
    required this.id,
    required this.nickname,
    required this.score,
    required this.rank,
    this.avatarUrl,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id']?.toString() ?? '',
      nickname: json['nickname'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'score': score,
        'rank': rank,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };

  @override
  List<Object?> get props => [id, nickname, score, rank, avatarUrl];
}
