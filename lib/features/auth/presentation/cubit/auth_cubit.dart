import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/constants/app_constants.dart';
import 'auth_state.dart';

/// Cubit that manages authentication state throughout the app.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo;

  AuthCubit(this._repo) : super(const AuthInitial());

  // ─── Check current auth status ─────────────────────────────────────────
  Future<void> checkAuthStatus() async {
    final isAuth = await _repo.isAuthenticated();
    if (!isAuth) {
      emit(const AuthUnauthenticated());
      return;
    }
    // Try to fetch the current user from the server
    try {
      emit(const AuthLoading());
      final user = await _repo.getCurrentUser();
      emit(AuthAuthenticated(user));
    } catch (_) {
      // Token may be expired — clear and redirect to login
      await _repo.logout();
      emit(const AuthUnauthenticated());
    }
  }

  // ─── Login ─────────────────────────────────────────────────────────────
  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.login(email: email, password: password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ─── Register ──────────────────────────────────────────────────────────
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.register(
        username: username,
        email: email,
        password: password,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ─── Logout ────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _repo.logout();
    emit(const AuthUnauthenticated());
  }

  // ─── Get stored username (for UI) ─────────────────────────────────────
  Future<String?> getStoredUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.usernameKey);
  }
}
