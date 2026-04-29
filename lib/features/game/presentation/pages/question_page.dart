import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
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
  bool _timerPulse = false;
  String? _selectedAnswerId;
  QuestionModel? _currentQuestion;
  DateTime? _endTime;
  bool _navigatedToResult = false;
  late AnimationController _countdownCtrl;
  late AnimationController _bgFloatCtrl;

  @override
  void initState() {
    super.initState();
    _countdownCtrl = AnimationController(vsync: this);
    _bgFloatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    AudioFeedbackService.instance.stopTimerSound();
    _countdownCtrl.dispose();
    _bgFloatCtrl.dispose();
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
      if (!mounted || _endTime == null) return;
      final diff = _endTime!.difference(DateTime.now()).inSeconds;
      if (diff != _remaining) {
        final next = diff >= 0 ? diff : 0;
        setState(() {
          _remaining = next;
          if (_remaining <= 5 && _remaining > 0) {
            _timerPulse = !_timerPulse;
          } else if (_remaining > 5) {
            _timerPulse = false;
          }
        });
      }
      if (_remaining <= 0) {
        _timer?.cancel();
        AudioFeedbackService.instance.stopTimerSound();
      }
    });
  }

  void _selectAnswer(BuildContext context, QuestionModel q, AnswerModel a) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selectedAnswerId = a.id;
    });
    _timer?.cancel();
    AudioFeedbackService.instance.stopTimerSound();
    context.read<GameCubit>().submitAnswer(
          questionId: q.id,
          answerId: a.id,
          timeTaken: q.timeLimit - _remaining,
        );
  }

  void _applyNewQuestion(QuestionModel q) {
    setState(() {
      _answered = false;
      _selectedAnswerId = null;
      _navigatedToResult = false;
      _timerStarted = true;
      _timerPulse = false;
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
        final isHost = context.read<GameCubit>().isHost;
        if (state is GameQuestionActive) {
          _applyNewQuestion(state.question);
        } else if (state is GameAnswerResult) {
          _timer?.cancel();
          AudioFeedbackService.instance.stopTimerSound();
          if (isHost) {
            context.read<GameCubit>().loadLeaderboard();
            context.pushReplacement('/game/leaderboard',
                extra: context.read<GameCubit>());
          } else {
            _navigatedToResult = true;
            context.push('/game/answer-result', extra: context.read<GameCubit>());
          }
        } else if (state is GameLeaderboardLoaded) {
          if (!_answered || _navigatedToResult) return;
          context.pushReplacement('/game/leaderboard',
              extra: context.read<GameCubit>());
        } else if (state is GameFinished) {
          context.pushReplacement('/game/leaderboard',
              extra: context.read<GameCubit>());
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
        final isHost = context.read<GameCubit>().isHost;
        final q =
            _currentQuestion ?? (state is GameQuestionActive ? state.question : null);
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
            child: Stack(
              children: [
                _FloatingParallaxBackground(animation: _bgFloatCtrl),
                ResponsiveContainer(
                  maxWidth: 800,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _StaggerSlideIn(
                                delayMs: 0,
                                child: _CountdownCircle(
                                  remaining: _remaining,
                                  total: q.timeLimit,
                                  animation: _countdownCtrl,
                                  pulseOn: _timerPulse && _remaining <= 5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (q.imageUrl != null)
                                _StaggerSlideIn(
                                  delayMs: 100,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: q.imageUrl!,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              if (q.imageUrl != null) const SizedBox(height: 12),
                              Expanded(
                                child: _StaggerSlideIn(
                                  delayMs: 180,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppColors.neutral50,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              AppColors.neutral800.withOpacity(0.16),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
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
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                            isSelected:
                                                _selectedAnswerId == q.answers[0].id,
                                            isHost: isHost,
                                            highlightAsCorrect:
                                                isHost && q.answers[0].isCorrect,
                                            tiltX: -0.05,
                                            tiltY: -0.08,
                                            delayMs: 260,
                                            onTap: isHost
                                                ? null
                                                : () => _selectAnswer(
                                                    context, q, q.answers[0]),
                                          ),
                                          const SizedBox(width: 14),
                                          _AnswerButton(
                                            answer: q.answers[1],
                                            shape: Icons.diamond_outlined,
                                            isLocked: _answered,
                                            isSelected:
                                                _selectedAnswerId == q.answers[1].id,
                                            isHost: isHost,
                                            highlightAsCorrect:
                                                isHost && q.answers[1].isCorrect,
                                            tiltX: -0.05,
                                            tiltY: 0.08,
                                            delayMs: 340,
                                            onTap: isHost
                                                ? null
                                                : () => _selectAnswer(
                                                    context, q, q.answers[1]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          _AnswerButton(
                                            answer: q.answers[2],
                                            shape: Icons.circle_outlined,
                                            isLocked: _answered,
                                            isSelected:
                                                _selectedAnswerId == q.answers[2].id,
                                            isHost: isHost,
                                            highlightAsCorrect:
                                                isHost && q.answers[2].isCorrect,
                                            tiltX: 0.05,
                                            tiltY: -0.08,
                                            delayMs: 420,
                                            onTap: isHost
                                                ? null
                                                : () => _selectAnswer(
                                                    context, q, q.answers[2]),
                                          ),
                                          const SizedBox(width: 14),
                                          _AnswerButton(
                                            answer: q.answers[3],
                                            shape: Icons.square_outlined,
                                            isLocked: _answered,
                                            isSelected:
                                                _selectedAnswerId == q.answers[3].id,
                                            isHost: isHost,
                                            highlightAsCorrect:
                                                isHost && q.answers[3].isCorrect,
                                            tiltX: 0.05,
                                            tiltY: 0.08,
                                            delayMs: 500,
                                            onTap: isHost
                                                ? null
                                                : () => _selectAnswer(
                                                    context, q, q.answers[3]),
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
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CountdownCircle extends StatelessWidget {
  final int remaining;
  final int total;
  final Animation<double> animation;
  final bool pulseOn;
  const _CountdownCircle({
    required this.remaining,
    required this.total,
    required this.animation,
    required this.pulseOn,
  });

  Color get _arcColor {
    final pct = total > 0 ? remaining / total : 0.0;
    if (pct > 0.6) return AppColors.success400;
    if (pct > 0.3) return AppColors.accent400;
    return AppColors.error400;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: pulseOn
            ? [
                BoxShadow(
                  color: AppColors.error400.withOpacity(0.7),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ]
            : const [],
      ),
      child: SizedBox(
        width: 90,
        height: 90,
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
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.neutral50.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
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

class _AnswerButton extends StatefulWidget {
  final AnswerModel answer;
  final IconData shape;
  final bool isLocked;
  final bool isSelected;
  final double tiltX;
  final double tiltY;
  final int delayMs;
  final VoidCallback? onTap;
  final bool isHost;
  final bool highlightAsCorrect;
  const _AnswerButton({
    required this.answer,
    required this.shape,
    required this.isLocked,
    required this.isSelected,
    required this.tiltX,
    required this.tiltY,
    required this.delayMs,
    required this.isHost,
    required this.highlightAsCorrect,
    required this.onTap,
  });

  @override
  State<_AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<_AnswerButton>
    with TickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _entryCurve;
  bool _didInvokeTap = false;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..addListener(() {
        if (!_didInvokeTap && _flipCtrl.value > 0.52) {
          _didInvokeTap = true;
          widget.onTap?.call();
        }
      });
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _entryCurve = CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut);
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void didUpdateWidget(covariant _AnswerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSelected && widget.isSelected) {
      _flipCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Color get _bg {
    final hex = widget.answer.color.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipCtrl, _entryCtrl]),
        builder: (_, __) {
          final entry = _entryCurve.value;
          final slideY = lerpDouble(40, 0, entry) ?? 0;
          final flip = _flipCtrl.value * math.pi;
          return Transform.translate(
            offset: Offset(0, slideY),
            child: Opacity(
              opacity: entry.clamp(0.0, 1.0),
              child: GestureDetector(
                onTap: widget.isLocked || widget.onTap == null
                    ? null
                    : () {
                        if (!_flipCtrl.isAnimating && !widget.isSelected) {
                          _didInvokeTap = false;
                          _flipCtrl.forward(from: 0);
                        }
                      },
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: widget.isHost
                      ? 1.0
                      : (widget.isLocked && !widget.isSelected ? 0.55 : 1.0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0014)
                      ..rotateX(widget.tiltX)
                      ..rotateY(widget.tiltY)
                      ..rotateY(flip),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(14),
                        border: widget.highlightAsCorrect
                            ? Border.all(
                                color: Colors.greenAccent,
                                width: 3,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: _bg.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                          if (widget.highlightAsCorrect)
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.35),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          if (widget.highlightAsCorrect)
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 16,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Icon(
                                    widget.shape,
                                    color: AppColors.neutral50,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.isSelected && _flipCtrl.value > 0.5
                                        ? 'Locked'
                                        : widget.answer.text,
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
                          if (widget.highlightAsCorrect)
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F8F53),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '✓ Correct Answer',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.neutral50,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FloatingParallaxBackground extends StatelessWidget {
  final Animation<double> animation;
  const _FloatingParallaxBackground({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(animation.value);
        final drift = lerpDouble(-18, 18, t) ?? 0;
        return Stack(
          children: [
            Positioned(
              left: -40 + drift,
              top: 90,
              child: _blob(140, AppColors.primary400.withOpacity(0.12)),
            ),
            Positioned(
              right: -30 - drift,
              top: 240,
              child: _blob(120, AppColors.accent400.withOpacity(0.12)),
            ),
            Positioned(
              left: 80 - drift,
              bottom: 110,
              child: _blob(100, AppColors.success400.withOpacity(0.1)),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _StaggerSlideIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _StaggerSlideIn({required this.child, required this.delayMs});

  @override
  State<_StaggerSlideIn> createState() => _StaggerSlideInState();
}

class _StaggerSlideInState extends State<_StaggerSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _curve = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (_, child) {
        final v = _curve.value;
        final slideY = lerpDouble(28, 0, v) ?? 0;
        return Transform.translate(
          offset: Offset(0, slideY),
          child: Opacity(opacity: v.clamp(0, 1), child: child),
        );
      },
      child: widget.child,
    );
  }
}
