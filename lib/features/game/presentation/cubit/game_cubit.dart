import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/constants/app_constants.dart';
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
  bool? _lastAnswerCorrect;
  int _lastPointsEarned = 0;

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
    emit(const GameLoading());
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
  Future<void> submitAnswer({
    required String questionId,
    required String answerId,
    required int timeTaken,
  }) async {
    if (sessionId == null || playerId == null) return;
    try {
      final result = await _repo.submitAnswer(
        sessionId: sessionId!,
        questionId: questionId,
        answerId: answerId,
        playerId: playerId!,
        timeTaken: timeTaken,
      );
      final isCorrect = (result['isCorrect'] as bool?) ?? (result['correct'] as bool?) ?? false;
      final pointsEarned = (result['pointsEarned'] as num?)?.toInt() ?? 0;
      _lastAnswerCorrect = isCorrect;
      _lastPointsEarned = pointsEarned;
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

  


Future<void> _loadAndShowLeaderboard() async {
    if (sessionId == null) return;
    try {
      final leaderboard = await _repo.getLeaderboard(sessionId!);
      emit(GameShowLeaderboard(leaderboard));
    } catch (e) {
      // Fallback: still show whatever we can
      emit(GameError(e.toString()));
    }
  }

  void requestShowLeaderboard() {
    if (isHost) _sendWsMessage({'action': 'SHOW_LEADERBOARD'});
  }


  // ─── Host: Advance to next question ───────────────────────────────────
  Future<void> goToNextQuestion() async {
    if (sessionId == null) return;
    emit(const GameLoading());
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
      case 'ALL_PLAYERS_ANSWERED':
      case 'ROUND_COMPLETE':
        emit(GameAnswerResult(
          isCorrect: _lastAnswerCorrect ?? false,
          pointsEarned: _lastPointsEarned,
        ));
        await Future<void>.delayed(
          const Duration(milliseconds: AppConstants.answerResultDelayMs),
        );
        await _loadAndShowLeaderboard();
        break;
      case 'SHOW_LEADERBOARD':
        await loadLeaderboard();
        break;
      case 'LEADERBOARD_UPDATED':
        if (data['leaderboard'] != null) {
          emit(GameLeaderboardLoaded(LeaderboardModel.fromJson(data['leaderboard'])));
        } else {
          await loadLeaderboard();
        }
        break;
      case 'GAME_FINISHED':
        _disconnectWebSocket();
        await loadResults();
        break;
      default:
        // fallback
        await refreshSession();
    }
  }

  @override
  Future<void> close() {
    _disconnectWebSocket();
    return super.close();
  }
}
