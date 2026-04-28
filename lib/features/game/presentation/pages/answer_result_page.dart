import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

class AnswerResultPage extends StatefulWidget {
  const AnswerResultPage({super.key});

  @override
  State<AnswerResultPage> createState() => _AnswerResultPageState();
}

class _AnswerResultPageState extends State<AnswerResultPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double>   _scaleAnim;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeIn);
    _scaleCtrl.forward();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _goToLeaderboard(BuildContext context) {
    if (!mounted) return;
    context.pushReplacement('/game/leaderboard', extra: context.read<GameCubit>());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameCubit, GameState>(
      listener: (context, state) {
        // ── Navigate to leaderboard on any round-complete/leaderboard state ──
        if (state is GameShowLeaderboard ||
            state is GameLeaderboardLoaded ||
            state is GameFinished) {
          _goToLeaderboard(context);
        } else if (state is GameRoundComplete) {
          // Brief pulse state — leaderboard data will follow immediately
          // No navigation yet; wait for GameShowLeaderboard
        } else if (state is GameQuestionActive) {
          context.pushReplacement('/game/question', extra: context.read<GameCubit>());
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
        final isCorrect  = state is GameAnswerResult ? state.isCorrect   : null;
        final points     = state is GameAnswerResult ? state.pointsEarned : null;
        final bgColor    = (isCorrect ?? true) ? AppColors.success600 : AppColors.error600;
        final icon       = (isCorrect ?? true) ? Icons.check_circle   : Icons.cancel;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Icon(icon, color: AppColors.neutral50, size: 120),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      (isCorrect ?? true)
                          ? context.l10n.t('correct')
                          : context.l10n.t('wrong'),
                      style: GoogleFonts.nunito(
                        color: AppColors.neutral50, fontSize: 40, fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (points != null && points > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.neutral50.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Text(
                          '+$points points',
                          style: GoogleFonts.nunito(
                            color: AppColors.neutral50, fontSize: 24, fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    const SizedBox(height: 48),
                    const CircularProgressIndicator(color: AppColors.neutral50),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.t('waitingForOthers'),
                      style: GoogleFonts.nunito(
                        color: AppColors.neutral200, fontSize: 16, fontWeight: FontWeight.bold,
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