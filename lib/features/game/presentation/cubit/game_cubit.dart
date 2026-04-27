import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/game_repository.dart';
import '../../../../core/constants/app_constants.dart';
import 'game_state.dart';

/// Cubit that orchestrates the entire game session lifecycle.
class GameCubit extends Cubit<GameState> {
  final GameRepository _repo;
  Timer? _pollingTimer;

  /// The current session ID (persisted across state transitions).
  String? sessionId;

  /// The current player ID (set after joining).
  String? playerId;

  /// Whether this client is the host.
  bool isHost = false;

  GameCubit(this._repo) : super(const GameInitial());

  // ─── Host: Create game ─────────────────────────────────────────────────
  Future<void> createGame(String quizId) async {
    emit(const GameLoading());
    try {
      final result = await _repo.createGame(quizId);
      sessionId = result.sessionId;
      isHost = true;
      emit(GameCreated(sessionId: result.sessionId, gamePin: result.gamePin));
      // Start polling the lobby to refresh the player list
      _startPolling();
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }

  // ─── Player: Join game (Authenticated) ─────────────────────────────────
  Future<void> joinGame({required String pin, required String nickname}) async {
    emit(const GameLoading());
    try {
      final result = await _repo.joinGame(pin: pin, nickname: nickname);
      sessionId = result.sessionId;
      playerId = result.playerId;
      isHost = false;
      emit(GameJoined(sessionId: result.sessionId, playerId: result.playerId));
      // Player also polls to detect when the game starts
      _startPolling();
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }

  // ─── Player: Join game (Anonymous) ─────────────────────────────────────
  Future<void> joinAnonymousGame({
    required String pin,
    required String nickname,
    String? avatarUrl,
  }) async {
    emit(const GameLoading());
    try {
      final result = await _repo.joinAnonymousGame(
        pin: pin,
        nickname: nickname,
        avatarUrl: avatarUrl,
      );
      sessionId = result.sessionId;
      playerId = result.playerId;
      isHost = false;
      emit(GameJoined(sessionId: result.sessionId, playerId: result.playerId));
      _startPolling();
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }

  // ─── Refresh session (for lobby player list) ───────────────────────────
  Future<void> refreshSession() async {
    if (sessionId == null) return;
    try {
      final session = await _repo.getSession(sessionId!);
      if (session.isActive) {
        _stopPolling();
        await loadCurrentQuestion();
      } else if (session.isFinished) {
        _stopPolling();
        await loadResults();
      } else {
        emit(GameSessionUpdated(session));
      }
    } catch (_) {
      // Silently ignore polling errors to avoid flickering
    }
  }

  // ─── Host: Start game ──────────────────────────────────────────────────
  Future<void> startGame() async {
    if (sessionId == null) return;
    try {
      await _repo.startGame(sessionId!);
      _stopPolling();
      await loadCurrentQuestion();
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }

  // ─── Load the current active question ─────────────────────────────────
  Future<void> loadCurrentQuestion() async {
    if (sessionId == null) return;
    emit(const GameLoading());
    try {
      final question = await _repo.getCurrentQuestion(sessionId!);
      emit(GameQuestionActive(question: question, sessionId: sessionId!));
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }

  // ─── Player: Submit answer ─────────────────────────────────────────────
  Future<void> submitAnswer({
    required String questionId,
    required String answerId,
  }) async {
    if (sessionId == null || playerId == null) return;
    try {
      final result = await _repo.submitAnswer(
        sessionId: sessionId!,
        questionId: questionId,
        answerId: answerId,
        playerId: playerId!,
      );
      final isCorrect = result['isCorrect'] as bool? ?? false;
      final pointsEarned = (result['pointsEarned'] as num?)?.toInt() ?? 0;
      emit(GameAnswerResult(isCorrect: isCorrect, pointsEarned: pointsEarned));
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }

  // ─── Load leaderboard (between questions) ─────────────────────────────
  Future<void> loadLeaderboard() async {
    if (sessionId == null) return;
    emit(const GameLoading());
    try {
      final leaderboard = await _repo.getLeaderboard(sessionId!);
      emit(GameLeaderboardLoaded(leaderboard));
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }

  // ─── Host: Advance to next question ───────────────────────────────────
  Future<void> goToNextQuestion() async {
    if (sessionId == null) return;
    try {
      await _repo.nextQuestion(sessionId!);
      await loadCurrentQuestion();
    } catch (e) {
      // If no more questions, load the final results
      await loadResults();
    }
  }

  // ─── Load final results ────────────────────────────────────────────────
  Future<void> loadResults() async {
    if (sessionId == null) return;
    emit(const GameLoading());
    try {
      final results = await _repo.getResults(sessionId!);
      emit(GameFinished(results));
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }

  // ─── Reset game state ──────────────────────────────────────────────────
  void reset() {
    _stopPolling();
    sessionId = null;
    playerId = null;
    isHost = false;
    emit(const GameInitial());
  }

  // ─── Internal polling ──────────────────────────────────────────────────
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(milliseconds: AppConstants.pollIntervalMs),
      (_) => refreshSession(),
    );
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
