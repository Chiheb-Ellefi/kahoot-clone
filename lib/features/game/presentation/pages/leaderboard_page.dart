import 'dart:ui';
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
import '../../../../core/localization/app_localizations.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _bgFloatCtrl;
  bool _hasShownResult = false;
  Map<String, int> _previousRanks = <String, int>{};
  String? _overtakePulsePlayerId;
  bool _gameIsFinished = false;

  @override
  void initState() {
    super.initState();
    AudioFeedbackService.instance.consumeLeaderboardSoundIfPending();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _bgFloatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _bgFloatCtrl.dispose();
    super.dispose();
  }

  void _maybeShowResultDialog(BuildContext context, GameState state) {
    if (_hasShownResult) return;
    final LeaderboardModel? lb;
    final bool isFinal;
    if (state is GameShowLeaderboard) {
      lb = state.leaderboard;
      isFinal = lb.isFinal;
    } else if (state is GameLeaderboardLoaded) {
      lb = state.leaderboard;
      isFinal = lb.isFinal;
    } else if (state is GameFinished) {
      lb = state.results;
      isFinal = true;
    } else {
      return;
    }
    final cubit = context.read<GameCubit>();
    if (!isFinal || cubit.isHost || lb == null) return;
    _hasShownResult = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final myRank = lb!.players.indexWhere((p) => p.id == cubit.playerId);
      if (myRank == 0) {
        AudioFeedbackService.instance.playWin();
        DialogUtils.showSuccess(
          context,
          '🎉 ${context.l10n.t('congratulations')}',
          context.l10n.t('youWonTheGame'),
        );
      } else if (myRank >= 0) {
        AudioFeedbackService.instance.playLose();
        DialogUtils.showError(
          context,
          '😢 ${context.l10n.t('goodLuckNextTime')}',
          context.l10n.t(
            'youFinishedRank',
            params: {'rank': '${myRank + 1}'},
          ),
        );
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
      setState(() => _overtakePulsePlayerId = overtakerId);
      Future<void>.delayed(const Duration(milliseconds: 750), () {
        if (!mounted) return;
        setState(() {
          if (_overtakePulsePlayerId == overtakerId) _overtakePulsePlayerId = null;
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
          _gameIsFinished = true;
          _trackOvertakes(state.results);
        }
        if (state is GameAnswerResult) {
          context.pushReplacement('/game/answer-result',
              extra: context.read<GameCubit>());
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
        _maybeShowResultDialog(context, state);
      },
      builder: (context, state) {
        if (state is GameLoading || state is GameRoundComplete) {
          return Scaffold(
            backgroundColor: AppColors.primary800,
            body: const Center(
                child: CircularProgressIndicator(color: AppColors.neutral50)),
          );
        }

        final LeaderboardModel? lb;
        final bool isFinal;
        final bool isRoundEnd;
        if (state is GameShowLeaderboard) {
          lb = state.leaderboard;
          isFinal = lb.isFinal;
          isRoundEnd = true;
        } else if (state is GameLeaderboardLoaded) {
          lb = state.leaderboard;
          isFinal = lb.isFinal;
          isRoundEnd = false;
        } else if (state is GameFinished) {
          lb = state.results;
          isFinal = true;
          isRoundEnd = false;
        } else {
          lb = null;
          isFinal = false;
          isRoundEnd = false;
        }

        final cubit = context.read<GameCubit>();
        final isHost = cubit.isHost;
        return Scaffold(
          backgroundColor: AppColors.primary800,
          appBar: AppBar(
            backgroundColor: AppColors.primary600,
            automaticallyImplyLeading: false,
            title: Text(
              isFinal
                  ? '🏆 ${context.l10n.t('finalResults')}'
                  : '⚡ ${AppConstants.gameName}',
              style: GoogleFonts.nunito(
                  color: AppColors.neutral50, fontWeight: FontWeight.w900),
            ),
            actions: [
              if (isFinal)
                TextButton(
                  onPressed: () {
                    cubit.reset();
                    context.go('/home');
                  },
                  child: Text(context.l10n.t('exit'),
                      style: GoogleFonts.nunito(
                          color: AppColors.neutral50,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          body: lb == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.neutral50))
              : Stack(
                  children: [
                    _FloatingParallaxBackground(animation: _bgFloatCtrl),
                    SlideTransition(
                      position: _slideAnim,
                      child: ResponsiveContainer(
                        maxWidth: 800,
                        child: CustomScrollView(
                          slivers: [
                            const SliverToBoxAdapter(child: SizedBox(height: 16)),
                            if (lb.topThree.isNotEmpty)
                              SliverToBoxAdapter(
                                child: _StaggerSlideIn(
                                  delayMs: 0,
                                  child: _Podium(top3: lb.topThree),
                                ),
                              ),
                            const SliverToBoxAdapter(child: SizedBox(height: 16)),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) {
                                    if (i.isOdd) return const SizedBox(height: 8);
                                    final idx = i ~/ 2;
                                    return _StaggerSlideIn(
                                      delayMs: 100 + (idx * 90),
                                      child: _RankRow(
                                        key: ValueKey(lb!.players[idx].id),
                                        player: lb.players[idx],
                                        index: idx,
                                        isOvertakePulse:
                                            _overtakePulsePlayerId ==
                                                lb.players[idx].id,
                                      ),
                                    );
                                  },
                                  childCount: lb.players.length * 2 - 1,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: isFinal
                                    ? SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            cubit.reset();
                                            context.go('/home');
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary400,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          icon: const Icon(Icons.exit_to_app,
                                              color: AppColors.neutral50),
                                          label: Text(
                                            context.l10n.t('exit'),
                                            style: GoogleFonts.nunito(
                                              color: AppColors.neutral50,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ),
                                      )
                                    : !isFinal && isHost
                                        ? SizedBox(
                                            width: double.infinity,
                                            height: 52,
                                            child: ElevatedButton.icon(
                                              onPressed: () =>
                                                  cubit.goToNextQuestion(),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primary400,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                              ),
                                              icon: const Icon(
                                                  Icons.navigate_next,
                                                  color: AppColors.neutral50),
                                              label: Text(
                                                context.l10n.t('nextQuestion'),
                                                style: GoogleFonts.nunito(
                                                  color: AppColors.neutral50,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 17,
                                                ),
                                              ),
                                            ),
                                          )
                                        : !isFinal && !_gameIsFinished
                                            ? _WaitingPill(isRoundEnd: isRoundEnd)
                                            : isFinal || _gameIsFinished
                                                ? SizedBox(
                                                    width: double.infinity,
                                                    height: 52,
                                                    child: ElevatedButton.icon(
                                                      onPressed: () {
                                                        cubit.reset();
                                                        context.go('/home');
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: AppColors.primary400,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(14),
                                                        ),
                                                      ),
                                                      icon: const Icon(Icons.exit_to_app,
                                                          color: AppColors.neutral50),
                                                      label: Text(
                                                        context.l10n.t('exit'),
                                                        style: GoogleFonts.nunito(
                                                          color: AppColors.neutral50,
                                                          fontWeight: FontWeight.w900,
                                                          fontSize: 17,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),
                              ),
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: 16)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

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
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.neutral200.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isRoundEnd
                ? context.l10n.t('waitingForHost')
                : context.l10n.t('standby'),
            style: GoogleFonts.nunito(
              color: AppColors.neutral200,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatefulWidget {
  final List<PlayerModel> top3;
  const _Podium({required this.top3});
  @override
  State<_Podium> createState() => _PodiumState();
}

class _PodiumState extends State<_Podium> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late AnimationController _shimmerCtrl;
  late List<Animation<double>> _scales;
  static const _podiumColors = [
    Color(0xFFFFD700),
    Color(0xFFC0C0C0),
    Color(0xFFCD7F32),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _scales = [0.65, 1.0, 0.45]
        .map((_) => CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut))
        .toList();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = <int>[
      if (widget.top3.length >= 2) 1,
      if (widget.top3.isNotEmpty) 0,
      if (widget.top3.length >= 3) 2,
    ];
    return SizedBox(
      height: 250,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: order
            .map((rankIdx) => _PodiumColumn(
                  player: widget.top3[rankIdx],
                  rank: rankIdx + 1,
                  color: _podiumColors[rankIdx],
                  scaleAnim: _scales[[1, 0, 2].indexOf(rankIdx)],
                  shimmer: _shimmerCtrl,
                ))
            .toList(),
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final PlayerModel player;
  final int rank;
  final Color color;
  final Animation<double> scaleAnim;
  final Animation<double> shimmer;
  const _PodiumColumn({
    required this.player,
    required this.rank,
    required this.color,
    required this.scaleAnim,
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    final heightFactor = rank == 1 ? 1.0 : (rank == 2 ? 0.65 : 0.45);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(['🥇', '🥈', '🥉'][rank - 1], style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          AvatarWidget(
            avatarUrl: player.avatarUrl,
            username: player.nickname,
            radius: 24,
            showBorder: true,
            borderColor: color,
          ),
          const SizedBox(height: 4),
          Text(
            player.nickname,
            style: GoogleFonts.nunito(
              color: AppColors.neutral50,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${player.score}',
            style: GoogleFonts.nunito(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: Listenable.merge([scaleAnim, shimmer]),
            builder: (_, __) {
              final s = scaleAnim.value;
              final h = (90 * heightFactor) * s;
              final shimmerX = lerpDouble(-80, 80, shimmer.value) ?? 0;
              return Transform.scale(
                scaleY: s.clamp(0.0, 1.0),
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 70,
                  height: h,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      Positioned(
                        left: shimmerX,
                        top: 0,
                        bottom: 0,
                        child: Transform.rotate(
                          angle: 0.3,
                          child: Container(
                            width: 18,
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                      ),
                      Align(
                        child: Text(
                          '#$rank',
                          style: GoogleFonts.nunito(
                            color: AppColors.neutral50,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatefulWidget {
  final PlayerModel player;
  final int index;
  final bool isOvertakePulse;
  const _RankRow({
    super.key,
    required this.player,
    required this.index,
    this.isOvertakePulse = false,
  });

  @override
  State<_RankRow> createState() => _RankRowState();
}

class _RankRowState extends State<_RankRow> with SingleTickerProviderStateMixin {
  static const _rankColors = [
    Color(0xFFFFD700),
    Color(0xFFC0C0C0),
    Color(0xFFCD7F32),
  ];
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
  }

  @override
  void didUpdateWidget(covariant _RankRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isOvertakePulse && widget.isOvertakePulse) {
      _pulseCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = widget.index < 3
        ? _rankColors[widget.index]
        : AppColors.neutral200.withOpacity(0.5);
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final pulse = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1, end: 1.15), weight: 45),
          TweenSequenceItem(tween: Tween(begin: 1.15, end: 1), weight: 55),
        ]).transform(Curves.easeOut.transform(_pulseCtrl.value));
        return Transform.scale(
          scale: widget.isOvertakePulse ? pulse : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isOvertakePulse
                  ? Color.lerp(AppColors.success200.withOpacity(0.3),
                      AppColors.neutral50.withOpacity(0.08), _pulseCtrl.value)
                  : AppColors.neutral50.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: widget.index == 0
                  ? Border.all(color: const Color(0xFFFFD700), width: 2)
                  : (widget.isOvertakePulse
                      ? Border.all(color: AppColors.success400, width: 1.6)
                      : null),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: rankColor.withOpacity(0.25),
                    shape: BoxShape.circle,
                    border: Border.all(color: rankColor, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '#${widget.index + 1}',
                      style: GoogleFonts.nunito(
                        color: rankColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                AvatarWidget(
                  avatarUrl: widget.player.avatarUrl,
                  username: widget.player.nickname,
                  radius: 22,
                  showBorder: widget.index == 0,
                  borderColor: rankColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.player.nickname,
                        style: GoogleFonts.nunito(
                          color: AppColors.neutral50,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.index < 3)
                        Text(
                          [
                            '🥇 ${context.l10n.t('winner')}',
                            '🥈 ${context.l10n.t('runnerUp')}',
                            '🥉 ${context.l10n.t('thirdPlace')}',
                          ][widget.index],
                          style: GoogleFonts.nunito(
                            color: rankColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  context.l10n.t(
                    'pointsShort',
                    params: {'points': '${widget.player.score}'},
                  ),
                  style: GoogleFonts.nunito(
                    color: rankColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
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

class _FloatingParallaxBackground extends StatelessWidget {
  final Animation<double> animation;
  const _FloatingParallaxBackground({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(animation.value);
        final drift = lerpDouble(-20, 20, t) ?? 0;
        return Stack(
          children: [
            Positioned(
              left: -55 + drift,
              top: 85,
              child: _blob(170, AppColors.primary400.withOpacity(0.1)),
            ),
            Positioned(
              right: -40 - drift,
              top: 220,
              child: _blob(130, AppColors.accent400.withOpacity(0.1)),
            ),
            Positioned(
              left: 70 - drift,
              bottom: 120,
              child: _blob(110, AppColors.success400.withOpacity(0.09)),
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
        return Transform.translate(
          offset: Offset(0, lerpDouble(28, 0, v) ?? 0),
          child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
        );
      },
      child: widget.child,
    );
  }
}
