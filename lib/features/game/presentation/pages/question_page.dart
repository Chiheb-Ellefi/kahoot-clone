import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import '../../../quiz/data/models/question_model.dart';
import '../../../quiz/data/models/answer_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_feedback_service.dart';
import '../../../../core/widgets/responsive_container.dart';

/// Displays the current active question with a countdown timer and
/// 4 Kahoot-style answer buttons.
class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _remaining = 30;
  bool _answered = false;
  bool _timerStarted = false;
  QuestionModel? _currentQuestion;
  DateTime? _endTime;

  // Guard: once we've pushed to answer-result, ignore any stale
  // GameLeaderboardLoaded emitted by submitAnswer() for the last player.
  bool _navigatedToResult = false;

  // Countdown animation controller
  late AnimationController _countdownCtrl;

  @override
  void initState() {
    super.initState();
    _countdownCtrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    AudioFeedbackService.instance.stopTimerSound();
    _countdownCtrl.dispose();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    _remaining = seconds;
    _endTime = DateTime.now().add(Duration(seconds: seconds));

    _countdownCtrl.duration = Duration(seconds: seconds);
    _countdownCtrl.forward(from: 0);

    AudioFeedbackService.instance.startTimerSound();

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      if (_endTime == null) return;

      final now = DateTime.now();
      final diff = _endTime!.difference(now).inSeconds;

      if (diff != _remaining) {
        setState(() => _remaining = diff >= 0 ? diff : 0);
      }

      if (_remaining <= 0) {
        _timer?.cancel();
        AudioFeedbackService.instance.stopTimerSound();
      }
    });
  }

  void _selectAnswer(BuildContext context, QuestionModel q, AnswerModel a) {
    if (_answered) return;
    setState(() => _answered = true);
    _timer?.cancel(); // Stop timer immediately on answer
    AudioFeedbackService.instance.stopTimerSound();
    final timeTaken = q.timeLimit - _remaining;
    context.read<GameCubit>().submitAnswer(
          questionId: q.id,
          answerId: a.id,
          timeTaken: timeTaken,
        );
  }

  void _applyNewQuestion(QuestionModel q) {
    setState(() {
      _answered = false;
      _navigatedToResult = false;
      _timerStarted = true;
      _currentQuestion = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _currentQuestion = q);
      _startTimer(q.timeLimit);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameCubit, GameState>(
      listener: (context, state) {
        if (state is GameQuestionActive) {
          // New question arrived (e.g. host pressed Next Question)
          _applyNewQuestion(state.question);
        } else if (state is GameAnswerResult) {
          // ALL players answered (or timer expired) — everyone goes to result page.
          // This fires for BOTH players AND the host.
          _timer?.cancel();
          AudioFeedbackService.instance.stopTimerSound();
          _navigatedToResult = true; // Block stale GameLeaderboardLoaded for last player
          context.push('/game/answer-result', extra: context.read<GameCubit>());
        } else if (state is GameLeaderboardLoaded) {
          // A player submitted their answer → navigate to leaderboard in waiting mode.
          // The host never calls submitAnswer so this never fires for the host.
          // Guard 1: only navigate if we actually answered.
          // Guard 2: skip if we already navigated to answer-result (last player case).
          if (!_answered || _navigatedToResult) return;
          context.pushReplacement(
            '/game/leaderboard',
            extra: context.read<GameCubit>(),
          );
        } else if (state is GameFinished) {
          context.pushReplacement('/game/leaderboard', extra: context.read<GameCubit>());
        } else if (state is GameError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error400,
            ),
          );
        }
      },
      builder: (context, state) {
        final q = _currentQuestion ??
            (state is GameQuestionActive ? state.question : null);

        // Fallback: start timer if the listener never handled it
        // (e.g. the page was rebuilt from scratch with an existing state).
        if (q != null && !_timerStarted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_timerStarted) {
              setState(() {
                _timerStarted = true;
                _currentQuestion = q;
              });
              _startTimer(q.timeLimit);
            }
          });
        }

        if (q == null) {
          return Scaffold(
            backgroundColor: AppColors.primary800,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.neutral50),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.primary800,
          body: SafeArea(
            child: ResponsiveContainer(
              maxWidth: 800,
              child: Column(
                children: [
                  // ── Timer + question card ────────────────────────────
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Countdown circle
                          _CountdownCircle(
                            remaining: _remaining,
                            total: q.timeLimit,
                            animation: _countdownCtrl,
                          ),
                          const SizedBox(height: 16),

                          // Optional question image
                          if (q.imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: q.imageUrl!,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          if (q.imageUrl != null) const SizedBox(height: 12),

                          // Question text
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.neutral50,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.neutral800.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  q.text,
                                  style: GoogleFonts.nunito(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── 2×2 answer grid ──────────────────────────────────
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: q.answers.length >= 4
                          ? Column(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      _AnswerButton(
                                        answer: q.answers[0],
                                        shape: Icons.change_history,
                                        isLocked: _answered,
                                        onTap: () =>
                                            _selectAnswer(context, q, q.answers[0]),
                                      ),
                                      const SizedBox(width: 8),
                                      _AnswerButton(
                                        answer: q.answers[1],
                                        shape: Icons.diamond_outlined,
                                        isLocked: _answered,
                                        onTap: () =>
                                            _selectAnswer(context, q, q.answers[1]),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Row(
                                    children: [
                                      _AnswerButton(
                                        answer: q.answers[2],
                                        shape: Icons.circle_outlined,
                                        isLocked: _answered,
                                        onTap: () =>
                                            _selectAnswer(context, q, q.answers[2]),
                                      ),
                                      const SizedBox(width: 8),
                                      _AnswerButton(
                                        answer: q.answers[3],
                                        shape: Icons.square_outlined,
                                        isLocked: _answered,
                                        onTap: () =>
                                            _selectAnswer(context, q, q.answers[3]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Countdown circle with animated arc
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownCircle extends StatelessWidget {
  final int remaining;
  final int total;
  final Animation<double> animation;

  const _CountdownCircle({
    required this.remaining,
    required this.total,
    required this.animation,
  });

  Color get _arcColor {
    final pct = total > 0 ? remaining / total : 0.0;
    if (pct > 0.6) return AppColors.success400;
    if (pct > 0.3) return AppColors.accent400;
    return AppColors.error400;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) {
          final progress =
              total > 0 ? 1.0 - (remaining / total).clamp(0.0, 1.0) : 1.0;
          return CustomPaint(
            painter: _ArcPainter(progress: progress, color: _arcColor),
            child: Center(
              child: Text(
                '$remaining',
                style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _arcColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.neutral50.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * (1 - progress),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Single answer button
// ─────────────────────────────────────────────────────────────────────────────

class _AnswerButton extends StatelessWidget {
  final AnswerModel answer;
  final IconData shape;
  final bool isLocked;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.answer,
    required this.shape,
    required this.isLocked,
    required this.onTap,
  });

  Color get _bg {
    final hex = answer.color.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: isLocked ? null : onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isLocked ? 0.55 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _bg.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(shape, color: AppColors.neutral50, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      answer.text,
                      style: GoogleFonts.nunito(
                        color: AppColors.neutral50,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
