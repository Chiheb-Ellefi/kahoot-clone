import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/profile_repository.dart';
import 'profile_state.dart';

/// Cubit for viewing and editing the user's profile.
class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _repo;

  ProfileCubit(this._repo) : super(const ProfileInitial());

  // ─── Load profile ──────────────────────────────────────────────────────
  Future<void> loadProfile() async {
    emit(const ProfileLoading());
    try {
      final user = await _repo.getProfile();
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  // ─── Update profile ────────────────────────────────────────────────────
  Future<void> updateProfile({
    required String username,
    String? avatarUrl,
  }) async {
    emit(const ProfileLoading());
    try {
      final user = await _repo.updateProfile(
        username: username,
        avatarUrl: avatarUrl,
      );
      emit(ProfileUpdated(user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
