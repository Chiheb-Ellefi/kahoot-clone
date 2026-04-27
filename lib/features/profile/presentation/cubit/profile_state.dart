import 'package:equatable/equatable.dart';
import '../../../auth/data/models/user_model.dart';

/// States for the Profile feature.
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final UserModel user;
  const ProfileLoaded(this.user);
  @override
  List<Object?> get props => [user];
}

class ProfileUpdated extends ProfileState {
  final UserModel user;
  const ProfileUpdated(this.user);
  @override
  List<Object?> get props => [user];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}
