import 'package:equatable/equatable.dart';

/// Represents an authenticated user.
class UserModel extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final int quizzesCreated;
  final int gamesPlayed;
  final int? bestRank;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.quizzesCreated = 0,
    this.gamesPlayed = 0,
    this.bestRank,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      quizzesCreated: (json['quizzesCreated'] as num?)?.toInt() ?? 0,
      gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
      bestRank: (json['bestRank'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
    int? quizzesCreated,
    int? gamesPlayed,
    int? bestRank,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      quizzesCreated: quizzesCreated ?? this.quizzesCreated,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      bestRank: bestRank ?? this.bestRank,
    );
  }

  @override
  List<Object?> get props => [id, username, email, avatarUrl, quizzesCreated, gamesPlayed, bestRank];
}
