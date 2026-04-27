import 'package:equatable/equatable.dart';

/// Represents an authenticated user.
class UserModel extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
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
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [id, username, email, avatarUrl];
}
