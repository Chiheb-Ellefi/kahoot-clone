import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

/// States for the Auth feature.
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Initial state — no action has been taken.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// A request is in flight.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated successfully — carries the user data.
class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

/// User is definitively logged out.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An error occurred during authentication.
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
