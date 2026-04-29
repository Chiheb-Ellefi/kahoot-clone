import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import '../../data/models/player_model.dart';
import '../../data/models/leaderboard_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/audio_feedback_service.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../../core/widgets/avatar_widget.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});
  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset>   _slideAnim;
  bool _hasShownResult = false;
  Map<String, int> _previousRanks = <String, int>{};
  String? _overtakePulsePlayerId;

  @override
  void initState() {
    super.initState();
    AudioFeedbackService.instance.playLeaderboardOpen();
    _slideCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _maybeShowResultDialog(BuildContext context, GameState state) {
    if (_hasShownResult) return;
    final LeaderboardModel? lb;
    final bool isFinal;
    if (state is GameShowLeaderboard) {
      lb = state.leaderboard; isFinal = lb.isFinal;
    } else if (state is GameLeaderboardLoaded) {
      lb = state.leaderboard; isFinal = lb.isFinal;
    } else if (state is GameFinished) {
      lb = state.results; isFinal = true;
    } else { return; }

    final cubit = context.read<GameCubit>();
    if (!isFinal || cubit.isHost || lb == null) return;
    _hasShownResult = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final myRank = lb!.players.indexWhere((p) => p.id == cubit.playerId);
      if (myRank == 0) {
        AudioFeedbackService.instance.playWin();
        DialogUtils.showSuccess(context, '🎉 Congratulations!',
            'You won the game! Amazing performance!');
      } else if (myRank >= 0) {
        AudioFeedbackService.instance.playLose();
        DialogUtils.showError(context, '😢 Good luck next time!',
            'You finished at #${myRank + 1}. Keep practicing!');
      }
    });
  }

  void _trackOvertakes(LeaderboardModel leaderboard) {
    final currentRanks = <String, int>{};
    String? overtakerId;

    for (var i = 0; i < leaderboard.players.length; i++) {
      final player = leaderboard.players[i];
      final newRank = i + 1;
      currentRanks[player.id] = newRank;
      final oldRank = _previousRanks[player.id];
      if (oldRank != null && newRank < oldRank) {
        overtakerId = player.id;
      }
    }

    if (overtakerId != null && mounted) {
      AudioFeedbackService.instance.playOvertake();
      setState(() {
        _overtakePulsePlayerId = overtakerId;
      });
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        setState(() {
          if (_overtakePulsePlayerId == overtakerId) {
            _overtakePulsePlayerId = null;
          }
        });
      });
    }

    _previousRanks = currentRanks;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameCubit, GameState>(
      listener: (context, state) {
        if (state is GameShowLeaderboard) {
          _trackOvertakes(state.leaderboard);
        } else if (state is GameLeaderboardLoaded) {
          _trackOvertakes(state.leaderboard);
        } else if (state is GameFinished) {
          _trackOvertakes(state.results);
        }

        // ALL_PLAYERS_ANSWERED fired while a player is already on leaderboard
        // (waiting mode). This is the normal path for all players EXCEPT the
        // last one whose submitAnswer races with the WS event.
        // The host is excluded: isHost never lands here during a round.
        if (state is GameAnswerResult) {
          context.pushReplacement(
            '/game/answer-result',
            extra: context.read<GameCubit>(),
          );
        } else if (state is GameQuestionActive) {
          // Host pressed Next Question → WS emitted QUESTION_ACTIVE
          context.pushReplacement('/game/question', extra: context.read<GameCubit>());
        } else if (state is GameError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error400),
          );
        }
        _maybeShowResultDialog(context, state);
      },
      builder: (context, state) {
        if (state is GameLoading || state is GameRoundComplete) {
          return Scaffold(
            backgroundColor: AppColors.primary800,
            body: const Center(child: CircularProgressIndicator(color: AppColors.neutral50)),
          );
        }

        final LeaderboardModel? lb;
        final bool isFinal;
        final bool isRoundEnd; // true = post-round pause mode

        if (state is GameShowLeaderboard) {
          lb = state.leaderboard; isFinal = lb.isFinal; isRoundEnd = true;
        } else if (state is GameLeaderboardLoaded) {
          lb = state.leaderboard; isFinal = lb.isFinal; isRoundEnd = false;
        } else if (state is GameFinished) {
          lb = state.results; isFinal = true; isRoundEnd = false;
        } else {
          lb = null; isFinal = false; isRoundEnd = false;
        }

        final cubit  = context.read<GameCubit>();
        final isHost = cubit.isHost;

        return Scaffold(
          backgroundColor: AppColors.primary800,
          appBar: AppBar(
            backgroundColor: AppColors.primary600,
            automaticallyImplyLeading: false,
            title: Text(
              isFinal ? '🏆 Final Results' : '⚡ ${AppConstants.gameName}',
              style: GoogleFonts.nunito(color: AppColors.neutral50, fontWeight: FontWeight.w900),
            ),
            actions: [
              if (isFinal)
                TextButton(
                  onPressed: () { cubit.reset(); context.go('/home'); },
                  child: Text('Exit',
                    style: GoogleFonts.nunito(color: AppColors.neutral50, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          body: lb == null
              ? const Center(child: CircularProgressIndicator(color: AppColors.neutral50))
              : SlideTransition(
                  position: _slideAnim,
                  child: ResponsiveContainer(
                    maxWidth: 800,
                    child: CustomScrollView(
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        if (lb.topThree.isNotEmpty)
                          SliverToBoxAdapter(child: _Podium(top3: lb.topThree)),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) {
                                if (i.isOdd) return const SizedBox(height: 8);
                                return _RankRow(
                                  player: lb!.players[i ~/ 2],
                                  index:  i ~/ 2,
                                  isOvertakePulse:
                                      _overtakePulsePlayerId == lb.players[i ~/ 2].id,
                                );
                              },
                              childCount: lb.players.length * 2 - 1,
                            ),
                          ),
                        ),

                        // ── Bottom action area ─────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: !isFinal && isHost
                                // HOST: manual "Next Question" button
                                ? SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      onPressed: () => cubit.goToNextQuestion(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary400,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14)),
                                      ),
                                      icon: const Icon(Icons.navigate_next, color: AppColors.neutral50),
                                      label: Text('Next Question',
                                        style: GoogleFonts.nunito(
                                          color: AppColors.neutral50, fontWeight: FontWeight.w900, fontSize: 17)),
                                    ),
                                  )
                                // PLAYERS (or final): show a waiting pill
                                : !isFinal
                                    ? _WaitingPill(isRoundEnd: isRoundEnd)
                                    : const SizedBox.shrink(),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

// ── Waiting pill shown to non-host players ────────────────────────────────────
class _WaitingPill extends StatelessWidget {
  final bool isRoundEnd;
  const _WaitingPill({required this.isRoundEnd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.neutral50.withOpacity(0.08),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.neutral200.withOpacity(0.7)),
          ),
          const SizedBox(width: 12),
          Text(
            isRoundEnd ? 'Waiting for host…' : 'Standby…',
            style: GoogleFonts.nunito(
              color: AppColors.neutral200, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Podium (unchanged logic, colour tokens applied) ───────────────────────────
class _Podium extends StatefulWidget {
  final List<PlayerModel> top3;
  const _Podium({required this.top3});
  @override
  State<_Podium> createState() => _PodiumState();
}

class _PodiumState extends State<_Podium> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _heights;
  static const _podiumMaxH  = 90.0;
  static const _podiumColors = [
    Color(0xFFFFD700), Color(0xFFC0C0C0), Color(0xFFCD7F32),
  ];
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _heights = [0.65, 1.0, 0.45].map((f) =>
      Tween<double>(begin: 0, end: _podiumMaxH * f)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut))
    ).toList();
    _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final order = <int>[
      if (widget.top3.length >= 2) 1,
      if (widget.top3.isNotEmpty)  0,
      if (widget.top3.length >= 3) 2,
    ];
    return SizedBox(
      height: 250,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: order.map((rankIdx) => _PodiumColumn(
          player:     widget.top3[rankIdx],
          rank:       rankIdx + 1,
          color:      _podiumColors[rankIdx],
          heightAnim: _heights[[1, 0, 2].indexOf(rankIdx)],
        )).toList(),
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final PlayerModel player;
  final int rank;
  final Color color;
  final Animation<double> heightAnim;
  const _PodiumColumn({required this.player, required this.rank,
      required this.color, required this.heightAnim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(['🥇','🥈','🥉'][rank-1], style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          AvatarWidget(
            avatarUrl: player.avatarUrl, username: player.nickname,
            radius: 24, showBorder: true, borderColor: color,
          ),
          const SizedBox(height: 4),
          Text(player.nickname,
            style: GoogleFonts.nunito(
              color: AppColors.neutral50, fontWeight: FontWeight.w900, fontSize: 12),
            overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${player.score}',
            style: GoogleFonts.nunito(
              color: color, fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: heightAnim,
            builder: (_, __) => Container(
              width: 70, height: heightAnim.value,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              alignment: Alignment.center,
              child: Text('#$rank',
                style: GoogleFonts.nunito(
                  color: AppColors.neutral50, fontWeight: FontWeight.w900, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rank row ──────────────────────────────────────────────────────────────────
class _RankRow extends StatelessWidget {
  final PlayerModel player;
  final int index;
  final bool isOvertakePulse;
  const _RankRow({
    required this.player,
    required this.index,
    this.isOvertakePulse = false,
  });

  static const _rankColors = [
    Color(0xFFFFD700), Color(0xFFC0C0C0), Color(0xFFCD7F32),
  ];

  @override
  Widget build(BuildContext context) {
    final rankColor = index < 3 ? _rankColors[index] : AppColors.neutral200.withOpacity(0.5);
    return Container(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isOvertakePulse
              ? AppColors.success200.withOpacity(0.25)
              : AppColors.neutral50.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: index == 0
              ? Border.all(color: const Color(0xFFFFD700), width: 2)
              : (isOvertakePulse
                  ? Border.all(color: AppColors.success400, width: 1.6)
                  : null),
        ),
        child: Row(
          children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color:  rankColor.withOpacity(0.25),
              shape:  BoxShape.circle,
              border: Border.all(color: rankColor, width: 1.5),
            ),
            child: Center(
              child: Text('#${index+1}',
                style: GoogleFonts.nunito(
                  color: rankColor, fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          AvatarWidget(
            avatarUrl: player.avatarUrl, username: player.nickname,
            radius: 22, showBorder: index == 0, borderColor: rankColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.nickname,
                  style: GoogleFonts.nunito(
                    color: AppColors.neutral50, fontWeight: FontWeight.w700, fontSize: 15),
                  overflow: TextOverflow.ellipsis),
                if (index < 3)
                  Text(['🥇 Winner','🥈 Runner-up','🥉 3rd Place'][index],
                    style: GoogleFonts.nunito(
                      color: rankColor, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
          Text('${player.score} pts',
            style: GoogleFonts.nunito(
              color: rankColor, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}