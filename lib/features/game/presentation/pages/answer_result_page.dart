import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_feedback_service.dart';

class AnswerResultPage extends StatefulWidget {
  const AnswerResultPage({super.key});

  @override
  State<AnswerResultPage> createState() => _AnswerResultPageState();
}

class _AnswerResultPageState extends State<AnswerResultPage>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late AnimationController _particleCtrl;
  late AnimationController _shakeCtrl;
  bool? _isCorrect;
  int _pointsEarned = 0;
  int _countdown = 5;
  Timer? _countdownTimer;
  bool _readyToNavigate = false;
  final math.Random _random = math.Random();

  void _playSound(bool isCorrect) {
    if (context.read<GameCubit>().isHost) return;
    if (isCorrect) {
      AudioFeedbackService.instance.playCorrectAnswer();
    } else {
      AudioFeedbackService.instance.playWrongAnswer();
    }
  }

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeIn);
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<GameCubit>().state;
      if (state is GameAnswerResult && _isCorrect == null) {
        setState(() {
          _isCorrect = state.isCorrect;
          _pointsEarned = state.pointsEarned;
        });
        _playSound(state.isCorrect);
        _kickOutcomeFx(state.isCorrect);
      }
      _startCountdown();
    });
  }

  void _kickOutcomeFx(bool isCorrect) {
    if (isCorrect) {
      _particleCtrl.forward(from: 0);
    } else {
      _shakeCtrl.forward(from: 0);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdown <= 1) {
        t.cancel();
        _readyToNavigate = true;
        context.read<GameCubit>().loadLeaderboard();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scaleCtrl.dispose();
    _particleCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameCubit, GameState>(
      listener: (context, state) {
        if (state is GameAnswerResult && _isCorrect == null) {
          setState(() {
            _isCorrect = state.isCorrect;
            _pointsEarned = state.pointsEarned;
          });
          _playSound(state.isCorrect);
          _kickOutcomeFx(state.isCorrect);
        }
        if ((state is GameLeaderboardLoaded || state is GameFinished) &&
            _readyToNavigate) {
          _countdownTimer?.cancel();
          context.pushReplacement('/game/leaderboard',
              extra: context.read<GameCubit>());
        }
        if (state is GameQuestionActive) {
          _countdownTimer?.cancel();
          context.pushReplacement('/game/question', extra: context.read<GameCubit>());
        }
        if (state is GameError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error400,
            ),
          );
        }
      },
      builder: (context, state) {
        final isCorrect = _isCorrect ?? false;
        final bgColor = isCorrect ? AppColors.success600 : AppColors.error600;
        final icon = isCorrect ? Icons.check_circle : Icons.cancel;
        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Stack(
                children: [
                  if (isCorrect)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _ParticleBurstLayer(
                          controller: _particleCtrl,
                          random: _random,
                        ),
                      ),
                    ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StaggerSlideIn(
                          delayMs: 0,
                          child: ScaleTransition(
                            scale: _scaleAnim,
                            child: AnimatedBuilder(
                              animation: _shakeCtrl,
                              builder: (_, child) {
                                final shakeT = _shakeCtrl.value;
                                final dx = isCorrect
                                    ? 0.0
                                    : TweenSequence<double>([
                                        TweenSequenceItem(
                                            tween: Tween(begin: 0, end: -12),
                                            weight: 1),
                                        TweenSequenceItem(
                                            tween: Tween(begin: -12, end: 12),
                                            weight: 2),
                                        TweenSequenceItem(
                                            tween: Tween(begin: 12, end: -8),
                                            weight: 1),
                                        TweenSequenceItem(
                                            tween: Tween(begin: -8, end: 8),
                                            weight: 1),
                                        TweenSequenceItem(
                                            tween: Tween(begin: 8, end: 0),
                                            weight: 1),
                                      ]).transform(shakeT);
                                return Transform.translate(
                                  offset: Offset(dx, 0),
                                  child: child,
                                );
                              },
                              child:
                                  Icon(icon, color: AppColors.neutral50, size: 120),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _StaggerSlideIn(
                          delayMs: 100,
                          child: Text(
                            isCorrect ? 'Correct!' : 'Wrong!',
                            style: GoogleFonts.nunito(
                              color: AppColors.neutral50,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_pointsEarned > 0)
                          _StaggerSlideIn(
                            delayMs: 200,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.neutral50.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Text(
                                '+$_pointsEarned points',
                                style: GoogleFonts.nunito(
                                  color: AppColors.neutral50,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 48),
                        _StaggerSlideIn(
                          delayMs: 280,
                          child: _CountdownRing(seconds: _countdown),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Leaderboard in $_countdown s',
                          style: GoogleFonts.nunito(
                            color: AppColors.neutral200,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

class _ParticleBurstLayer extends StatelessWidget {
  final AnimationController controller;
  final math.Random random;
  const _ParticleBurstLayer({required this.controller, required this.random});

  @override
  Widget build(BuildContext context) {
    final particles = List.generate(14, (i) {
      final angle = (2 * math.pi / 14) * i + random.nextDouble() * 0.2;
      final distance = 90.0 + random.nextDouble() * 60;
      final size = 6.0 + random.nextDouble() * 6;
      final color = [
        AppColors.accent400,
        AppColors.neutral50,
        AppColors.success200,
        AppColors.primary400
      ][i % 4];
      return _ParticleSpec(
        offset: Offset(math.cos(angle) * distance, math.sin(angle) * distance),
        size: size,
        color: color,
      );
    });

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = Curves.easeOut.transform(controller.value);
        final opacity = 1 - Curves.easeIn.transform(controller.value);
        return Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: particles
                .map((p) => Transform.translate(
                      offset: Offset(p.offset.dx * t, p.offset.dy * t),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: p.size,
                          height: p.size,
                          decoration: BoxDecoration(
                            color: p.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

class _ParticleSpec {
  final Offset offset;
  final double size;
  final Color color;
  const _ParticleSpec({
    required this.offset,
    required this.size,
    required this.color,
  });
}

class _CountdownRing extends StatelessWidget {
  final int seconds;
  const _CountdownRing({required this.seconds});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: seconds / 5,
            strokeWidth: 4,
            backgroundColor: AppColors.neutral50.withOpacity(0.2),
            color: AppColors.neutral50,
          ),
          Text(
            '$seconds',
            style: GoogleFonts.nunito(
              color: AppColors.neutral50,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
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
        return Transform.translate(
          offset: Offset(0, lerpDouble(30, 0, v) ?? 0),
          child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
        );
      },
      child: widget.child,
    );
  }
}
