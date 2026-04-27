import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import '../../data/models/game_session_model.dart';
import '../../../quiz/data/models/question_model.dart';
import '../../../quiz/data/models/answer_model.dart';

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
  QuestionModel? _currentQuestion;

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
    _countdownCtrl.dispose();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    _remaining = seconds;
    _countdownCtrl.duration = Duration(seconds: seconds);
    _countdownCtrl.forward(from: 0);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        _timer?.cancel();
        // Time's up — show leaderboard
        if (!_answered) {
          context.read<GameCubit>().loadLeaderboard();
        }
      }
    });
  }

  void _selectAnswer(BuildContext context, QuestionModel q, AnswerModel a) {
    if (_answered) return;
    setState(() => _answered = true);
    _timer?.cancel();
    context.read<GameCubit>().submitAnswer(
          questionId: q.id,
          answerId: a.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameCubit, GameState>(
      listener: (context, state) {
        if (state is GameQuestionActive) {
          setState(() {
            _answered = false;
            _currentQuestion = state.question;
          });
          _startTimer(state.question.timeLimit);
        } else if (state is GameAnswerResult) {
          _timer?.cancel();
          context.push('/game/answer-result', extra: context.read<GameCubit>());
        } else if (state is GameLeaderboardLoaded) {
          context.push('/game/leaderboard', extra: context.read<GameCubit>());
        } else if (state is GameFinished) {
          context.push('/game/leaderboard', extra: context.read<GameCubit>());
        } else if (state is GameError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFE21B3C),
            ),
          );
        }
      },
      builder: (context, state) {
        final q = _currentQuestion ??
            (state is GameQuestionActive ? state.question : null);

        if (q == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF2D0A5E),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF2D0A5E),
          body: SafeArea(
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
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
                                  color: const Color(0xFF1A1A2E),
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
                    padding:
                        const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
    final pct = remaining / total;
    if (pct > 0.6) return const Color(0xFF26890C);
    if (pct > 0.3) return const Color(0xFFE6820B);
    return const Color(0xFFE21B3C);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) {
          final progress = 1.0 - (remaining / total).clamp(0.0, 1.0);
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
        ..color = Colors.white12
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
                  Icon(shape, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      answer.text,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
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
