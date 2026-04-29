import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/models/leaderboard_model.dart';
import '../../../quiz/data/models/question_model.dart';
import 'game_state.dart';

/// Cubit that orchestrates the entire game session lifecycle.
class GameCubit extends Cubit<GameState> {
  final GameRepository _repo;
  WebSocketChannel? _wsChannel;

  /// The current session ID (persisted across state transitions).
  String? sessionId;

  /// Tracks the current question index to detect transitions
  int? _currentQuestionIndex;

  /// The current player ID (set after joining).
  String? playerId;

  /// Whether this client is the host.
  bool isHost = false;

  /// Stored locally after submitAnswer so ALL_PLAYERS_ANSWERED can use it.
  bool? _lastAnswerCorrect;
  int _lastPointsEarned = 0;

  bool _isSubmittingAnswer = false;
  bool _pendingAllPlayersAnswered = false;

  GameCubit(this._repo) : super(const GameInitial());

  // ─── Host: Create game ─────────────────────────────────────────────────
  Future<void> createGame(String quizId) async {
    emit(const GameLoading());
    try {
      final result = await _repo.createGame(quizId);
      sessionId = result.sessionId;
      isHost = true;
      emit(GameCreated(sessionId: result.sessionId, gamePin: result.gamePin));
      _connectWebSocket();
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
      _connectWebSocket();
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
      _connectWebSocket();
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
        if (_currentQuestionIndex != session.currentQuestionIndex) {
          _currentQuestionIndex = session.currentQuestionIndex;
          await loadCurrentQuestion();
        }
      } else if (session.isFinished) {
        _disconnectWebSocket();
        await loadResults();
      } else {
        emit(GameSessionUpdated(session));
      }
    } catch (e) {
      print('Refresh Session Error: $e');
      // Silently ignore polling errors to avoid flickering
    }
  }

  // ─── Host: Start game ──────────────────────────────────────────────────
  Future<void> startGame() async {
    if (sessionId == null) return;
    try {
      _sendWsMessage({'action': 'START_GAME'});
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }

  // ─── Load the current active question ─────────────────────────────────
  Future<void> loadCurrentQuestion() async {
    if (sessionId == null) return;
    emit(const GameLoading());
    try {
      _lastAnswerCorrect = null;
      _lastPointsEarned = 0;
      final question = await _repo.getCurrentQuestion(sessionId!);
      emit(GameQuestionActive(question: question, sessionId: sessionId!));
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }

  // ─── Player: Submit answer ─────────────────────────────────────────────
  // Flow:
  //   1. Fetch old-scores snapshot BEFORE submitting
  //   2. Submit answer
  //   3. Store isCorrect + pointsEarned locally
  //   4. Emit GameLeaderboardLoaded(oldSnapshot) → question_page navigates
  //      to leaderboard_page in "waiting" mode
  Future<void> submitAnswer({
    required String questionId,
    required String answerId,
    required int timeTaken,
  }) async {
    if (sessionId == null || playerId == null) return;
    try {
      _isSubmittingAnswer = true;
      
      // 1. Grab the snapshot BEFORE the answer is counted
      LeaderboardModel? snapshot;
      try {
        snapshot = await _repo.getLeaderboard(sessionId!);
      } catch (_) {}

      // 2. Submit
      final result = await _repo.submitAnswer(
        sessionId: sessionId!,
        questionId: questionId,
        answerId: answerId,
        playerId: playerId!,
        timeTaken: timeTaken,
      );

      // 3. Store locally — used when ALL_PLAYERS_ANSWERED fires
      _lastAnswerCorrect =
          (result['isCorrect'] as bool?) ?? (result['correct'] as bool?) ?? false;
      _lastPointsEarned = (result['pointsEarned'] as num?)?.toInt() ?? 0;

      _isSubmittingAnswer = false;

      // If the WS event arrived while we were submitting, process it now
      // so we don't go to the leaderboard and skip the result screen.
      if (_pendingAllPlayersAnswered) {
        _pendingAllPlayersAnswered = false;
        emit(GameAnswerResult(
          isCorrect: _lastAnswerCorrect ?? false,
          pointsEarned: _lastPointsEarned,
        ));
      } else {
        // 4. Emit old-scores snapshot → triggers navigation to leaderboard (waiting)
        if (snapshot != null) {
          emit(GameLeaderboardLoaded(snapshot));
        }
      }
    } catch (e) {
      _isSubmittingAnswer = false;
      _pendingAllPlayersAnswered = false;
      emit(GameError(e.toString()));
    }
  }

  // ─── Load leaderboard (updated scores, called by answer_result_page) ───
  Future<void> loadLeaderboard() async {
    if (sessionId == null) return;
    if (state is GameFinished) return;
    emit(const GameLoading());
    try {
      final leaderboard = await _repo.getLeaderboard(sessionId!);
      emit(GameLeaderboardLoaded(leaderboard));
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }

  void requestShowLeaderboard() {
    if (isHost) _sendWsMessage({'action': 'SHOW_LEADERBOARD'});
  }

  // ─── Host: Advance to next question ───────────────────────────────────
  // No GameLoading emitted — the WS QUESTION_ACTIVE event drives the transition.
  Future<void> goToNextQuestion() async {
    if (sessionId == null) return;
    try {
      _sendWsMessage({'action': 'NEXT_QUESTION'});
    } catch (e) {
      emit(GameError(e.toString()));
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
    _disconnectWebSocket();
    sessionId = null;
    playerId = null;
    _currentQuestionIndex = null;
    _lastAnswerCorrect = null;
    _lastPointsEarned = 0;
    isHost = false;
    emit(const GameInitial());
  }

  // ─── WebSocket Logic ──────────────────────────────────────────────────
  void _connectWebSocket() {
    _disconnectWebSocket();
    if (sessionId == null) return;

    final wsBase = ApiConstants.baseUrl.replaceFirst('http', 'ws');
    final url = '$wsBase/api/games/ws/$sessionId';
    final uriStr = playerId != null ? '$url?playerId=$playerId' : '$url?host=true';

    try {
      _wsChannel = WebSocketChannel.connect(Uri.parse(uriStr));
      _wsChannel!.stream.listen(
        (message) {
          if (message is String) {
            try {
              final data = jsonDecode(message);
              _handleWsMessage(data);
            } catch (e) {
              print('WS Decode Error: $e');
            }
          }
        },
        onError: (e) => print('WS Error: $e'),
        onDone: () => print('WS Closed'),
      );
    } catch (e) {
      print('WebSocket connection failed: $e');
    }
  }

  void _disconnectWebSocket() {
    _wsChannel?.sink.close();
    _wsChannel = null;
  }

  void _sendWsMessage(Map<String, dynamic> data) {
    if (_wsChannel != null) {
      _wsChannel!.sink.add(jsonEncode(data));
    }
  }

  Future<void> _handleWsMessage(Map<String, dynamic> data) async {
    final type = data['type'] ?? data['action'];
    print('Received WS Message: $data');
    switch (type) {
      case 'SESSION_UPDATED':
      case 'PLAYER_JOINED':
        await refreshSession();
        break;

      case 'GAME_STARTED':
        await loadCurrentQuestion();
        break;

      // ── New question started ──────────────────────────────────────────
      // Reset per-round tracking. The question data in the payload is used
      // directly so we avoid an extra HTTP round-trip.
      // IMPORTANT: do NOT call loadLeaderboard here — the LEADERBOARD_UPDATED
      // that follows is ignored during active questions (see below).
      case 'QUESTION_ACTIVE':
        _lastAnswerCorrect = null;
        _lastPointsEarned = 0;
        if (data['question'] != null) {
          emit(GameQuestionActive(
            question: QuestionModel.fromJson(data['question']),
            sessionId: sessionId!,
          ));
        } else {
          await loadCurrentQuestion();
        }
        break;

      // ── All players answered — emit result for EVERYONE (host included) ─
      // The host's _lastAnswerCorrect is null → treated as wrong (0 pts),
      // which is fine since the host does not score.
      case 'ALL_PLAYERS_ANSWERED':
      case 'ROUND_COMPLETE':
        if (_isSubmittingAnswer) {
          _pendingAllPlayersAnswered = true;
        } else {
          emit(GameAnswerResult(
            isCorrect: _lastAnswerCorrect ?? false,
            pointsEarned: _lastPointsEarned,
          ));
        }
        break;

      // ── Leaderboard updated by server ─────────────────────────────────
      // This fires right after QUESTION_ACTIVE in the observed log.
      // We IGNORE it here — the answer_result_page calls loadLeaderboard()
      // itself after its 5-second countdown. Reacting here would clobber
      // the question_page with a leaderboard navigation.
      case 'LEADERBOARD_UPDATED':
        // Intentionally ignored — answer_result_page drives this transition.
        break;

      case 'SHOW_LEADERBOARD':
        if (state is! GameFinished) {
          await loadLeaderboard();
        }
        break;

      case 'GAME_FINISHED':
        _disconnectWebSocket();
        await loadResults();
        break;

      default:
        await refreshSession();
    }
  }

  @override
  Future<void> close() {
    _disconnectWebSocket();
    return super.close();
  }
}
