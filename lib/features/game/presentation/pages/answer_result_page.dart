import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import '../../../../core/constants/app_colors.dart';

/// Shown for EVERY client (players + host) after ALL_PLAYERS_ANSWERED.
/// Displays correct/wrong feedback + points, then after 5 seconds fetches
/// the updated leaderboard and navigates there.
class AnswerResultPage extends StatefulWidget {
  const AnswerResultPage({super.key});

  @override
  State<AnswerResultPage> createState() => _AnswerResultPageState();
}

class _AnswerResultPageState extends State<AnswerResultPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  // Captured from the first GameAnswerResult state seen
  bool? _isCorrect;
  int _pointsEarned = 0;

  // 5-second countdown before auto-navigating to leaderboard
  int _countdown = 5;
  Timer? _countdownTimer;

  // Guard: only true AFTER the 5s countdown fires loadLeaderboard().
  // Prevents the stale GameLeaderboardLoaded from submitAnswer() (old-scores
  // snapshot) from instantly skipping the result screen for the last player.
  bool _readyToNavigate = false;

  @override
  void initState() {
    super.initState();

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeIn);
    _scaleCtrl.forward();

    // Try to capture result from current state immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<GameCubit>().state;
      if (state is GameAnswerResult && _isCorrect == null) {
        setState(() {
          _isCorrect = state.isCorrect;
          _pointsEarned = state.pointsEarned;
        });
      }
      _startCountdown();
    });
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
        // Mark ready BEFORE fetching — so the listener knows this
        // GameLeaderboardLoaded is the real updated one, not the old snapshot.
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameCubit, GameState>(
      listener: (context, state) {
        // Capture result data if we land here before initState's postFrame runs
        if (state is GameAnswerResult && _isCorrect == null) {
          setState(() {
            _isCorrect = state.isCorrect;
            _pointsEarned = state.pointsEarned;
          });
        }

        // After 5s the cubit calls loadLeaderboard() → GameLeaderboardLoaded.
        // We guard with _readyToNavigate so the old-snapshot emission from
        // submitAnswer() doesn't skip the countdown for the last player.
        if ((state is GameLeaderboardLoaded || state is GameFinished) &&
            _readyToNavigate) {
          _countdownTimer?.cancel();
          context.pushReplacement(
            '/game/leaderboard',
            extra: context.read<GameCubit>(),
          );
        }

        // Next question started before the countdown finished (edge case)
        if (state is GameQuestionActive) {
          _countdownTimer?.cancel();
          context.pushReplacement(
            '/game/question',
            extra: context.read<GameCubit>(),
          );
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
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Result icon ─────────────────────────────────────
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Icon(icon, color: AppColors.neutral50, size: 120),
                    ),
                    const SizedBox(height: 24),

                    // ── Correct / Wrong label ───────────────────────────
                    Text(
                      isCorrect ? 'Correct!' : 'Wrong!',
                      style: GoogleFonts.nunito(
                        color: AppColors.neutral50,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Points earned (only when > 0) ───────────────────
                    if (_pointsEarned > 0)
                      Container(
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
                    const SizedBox(height: 48),

                    // ── Countdown ring ──────────────────────────────────
                    _CountdownRing(seconds: _countdown),
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
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simple animated countdown ring
// ─────────────────────────────────────────────────────────────────────────────
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