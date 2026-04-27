import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import '../../../../core/constants/app_constants.dart';

/// Displays a full-screen correct/wrong result after an answer is submitted,
/// then auto-advances to the leaderboard after [AppConstants.answerResultDelayMs].
class AnswerResultPage extends StatefulWidget {
  const AnswerResultPage({super.key});

  @override
  State<AnswerResultPage> createState() => _AnswerResultPageState();
}

class _AnswerResultPageState extends State<AnswerResultPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

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
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameCubit, GameState>(
      listener: (context, state) {
        if (state is GameLeaderboardLoaded || state is GameFinished) {
          context.pushReplacement('/game/leaderboard', extra: context.read<GameCubit>());
        } else if (state is GameQuestionActive) {
          context.pushReplacement('/game/question', extra: context.read<GameCubit>());
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
        // Persist the result values — state may have changed to Loading
        final isCorrect = state is GameAnswerResult ? state.isCorrect : null;
        final points =
            state is GameAnswerResult ? state.pointsEarned : null;

        final bgColor = (isCorrect ?? true)
            ? const Color(0xFF26890C)
            : const Color(0xFFE21B3C);

        final icon =
            (isCorrect ?? true) ? Icons.check_circle : Icons.cancel;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Icon ────────────────────────────────────────
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 120,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Result text ──────────────────────────────────
                    Text(
                      (isCorrect ?? true) ? 'Correct!' : 'Wrong!',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Points earned ────────────────────────────────
                    if (points != null && points > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Text(
                          '+$points points',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                    const SizedBox(height: 48),

                    // ── Waiting indicator ───────────────────────────
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Waiting for others...',
                      style: GoogleFonts.nunito(
                        color: Colors.white70,
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

