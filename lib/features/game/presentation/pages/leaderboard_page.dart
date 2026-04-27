import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import '../../data/models/player_model.dart';
import '../../data/models/leaderboard_model.dart';

/// Shows the ranked leaderboard between questions or as the final results.
/// Host sees "Next Question" button; players see their rank only.
class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameCubit, GameState>(
      listener: (context, state) {
        if (state is GameQuestionActive) {
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
        if (state is GameLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF2D0A5E),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final LeaderboardModel? lb;
        final bool isFinal;
        if (state is GameLeaderboardLoaded) {
          lb = state.leaderboard;
          isFinal = state.leaderboard.isFinal;
        } else if (state is GameFinished) {
          lb = state.results;
          isFinal = true;
        } else {
          lb = null;
          isFinal = false;
        }

        final gameCubit = context.read<GameCubit>();
        final isHost = gameCubit.isHost;

        return Scaffold(
          backgroundColor: const Color(0xFF2D0A5E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF46178F),
            automaticallyImplyLeading: false,
            title: Text(
              isFinal ? '🏆 Final Results' : '⚡ Leaderboard',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            actions: [
              if (isFinal)
                TextButton(
                  onPressed: () {
                    gameCubit.reset();
                    context.go('/home');
                  },
                  child: Text(
                    'Exit',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          body: lb == null
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : SlideTransition(
                  position: _slideAnim,
                  child: CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),

                      // ── Podium top 3 ─────────────────────────────────
                      if (lb.topThree.isNotEmpty)
                        SliverToBoxAdapter(child: _Podium(top3: lb.topThree)),

                      const SliverToBoxAdapter(child: SizedBox(height: 16)),

                      // ── Full ranked list ─────────────────────────────
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) {
                              if (i.isOdd) return const SizedBox(height: 8);
                              final index = i ~/ 2;
                              return _RankRow(player: lb!.players[index], index: index);
                            },
                            childCount: lb.players.length * 2 - 1,
                          ),
                        ),
                      ),

                      // ── Next question / host controls ─────────────────
                      if (!isFinal && isHost)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    gameCubit.goToNextQuestion(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF46178F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.navigate_next,
                                    color: Colors.white),
                                label: Text(
                                  'Next Question',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ),
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
// Podium widget (top 3)
// ─────────────────────────────────────────────────────────────────────────────

class _Podium extends StatefulWidget {
  final List<PlayerModel> top3;
  const _Podium({required this.top3});

  @override
  State<_Podium> createState() => _PodiumState();
}

class _PodiumState extends State<_Podium> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _heights;

  static const _podiumMaxH = 90.0;
  static const _podiumColors = [
    Color(0xFFFFD700), // gold — 1st
    Color(0xFFC0C0C0), // silver — 2nd
    Color(0xFFCD7F32), // bronze — 3rd
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    // Podium order: 2nd | 1st | 3rd for visual effect
    final fractions = [0.65, 1.0, 0.45];
    _heights = fractions
        .map(
          (f) => Tween<double>(begin: 0, end: _podiumMaxH * f).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
          ),
        )
        .toList();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reorder: display as [2nd, 1st, 3rd]
    final displayOrder = <int>[];
    if (widget.top3.length >= 2) displayOrder.add(1);
    if (widget.top3.isNotEmpty) displayOrder.add(0);
    if (widget.top3.length >= 3) displayOrder.add(2);

    return SizedBox(
      height: 180,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: displayOrder.map((rankIdx) {
          final player = widget.top3[rankIdx];
          final displayRankIdx = [1, 0, 2].indexOf(rankIdx); // for heights
          return _PodiumColumn(
            player: player,
            rank: rankIdx + 1,
            color: _podiumColors[rankIdx],
            heightAnim: _heights[displayRankIdx],
          );
        }).toList(),
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final PlayerModel player;
  final int rank;
  final Color color;
  final Animation<double> heightAnim;

  const _PodiumColumn({
    required this.player,
    required this.rank,
    required this.color,
    required this.heightAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            ['🥇', '🥈', '🥉'][rank - 1],
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            player.nickname,
            style: GoogleFonts.nunito(
              color: Colors.white,
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
            animation: heightAnim,
            builder: (_, __) => Container(
              width: 70,
              height: heightAnim.value,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '#$rank',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single rank row in the full list
// ─────────────────────────────────────────────────────────────────────────────

class _RankRow extends StatelessWidget {
  final PlayerModel player;
  final int index;

  const _RankRow({required this.player, required this.index});

  @override
  Widget build(BuildContext context) {
    final rankColors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];
    final rankColor =
        index < 3 ? rankColors[index] : Colors.white38;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: index == 0
            ? Border.all(color: const Color(0xFFFFD700), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#${index + 1}',
              style: GoogleFonts.nunito(
                color: rankColor,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.nickname,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${player.score} pts',
            style: GoogleFonts.nunito(
              color: rankColor,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
