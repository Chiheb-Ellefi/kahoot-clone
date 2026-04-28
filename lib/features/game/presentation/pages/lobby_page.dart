import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../../core/constants/app_constants.dart';

/// Handles both the Host lobby (show PIN + player list) and the
/// Player lobby (enter PIN + nickname and join).
class LobbyPage extends StatefulWidget {
  final String? quizId;  // non-null when hosting
  final bool isHost;
  final String? pin;
  final String? nickname;
  final String? avatarUrl;

  const LobbyPage({
    super.key,
    this.quizId,
    required this.isHost,
    this.pin,
    this.nickname,
    this.avatarUrl,
  });

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final _pinCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.pin != null) {
      _pinCtrl.text = widget.pin!;
    }
    if (widget.nickname != null) {
      _nicknameCtrl.text = widget.nickname!;
    }

    // If hosting, immediately create the game session
    if (widget.isHost && widget.quizId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<GameCubit>().createGame(widget.quizId!);
      });
    } else if (!widget.isHost && widget.pin != null && widget.nickname != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<GameCubit>().joinAnonymousGame(
              pin: widget.pin!,
              nickname: widget.nickname!,
              avatarUrl: widget.avatarUrl,
            );
      });
    }
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameCubit, GameState>(
      listener: (context, state) {
        if (state is GameQuestionActive) {
          // Game started — navigate to the question page passing the cubit
          context.push(
            '/game/question',
            extra: context.read<GameCubit>(),
          );
        } else if (state is GameLeaderboardLoaded) {
          context.push(
            '/game/leaderboard',
            extra: context.read<GameCubit>(),
          );
        } else if (state is GameError) {
          String msg = state.message;
          if (msg.toLowerCase().contains('not found') || 
              msg.toLowerCase().contains('invalid pin')) {
            msg = 'No game found with this PIN.';
          }
          // ✅ FIXED: Added missing 'title' parameter
          DialogUtils.showError(
            context,
            'Error',  // ✅ Added this parameter
            msg,
            onClose: () {
              if (!widget.isHost) {
                context.go('/join');
              }
            },
          );
        }
      },
      builder: (context, state) {
        if (widget.isHost) {
          return _HostLobby(state: state);
        } else {
          return _PlayerLobby(
            state: state,
          );
        }
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────[...]
// Host Lobby — displays PIN and live player list
// ────────────────────────────────────────────────────────────────[...]

class _HostLobby extends StatelessWidget {
  final GameState state;
  const _HostLobby({required this.state});

  @override
  Widget build(BuildContext context) {
    final pin = state is GameCreated
        ? (state as GameCreated).gamePin
        : state is GameSessionUpdated
            ? (state as GameSessionUpdated).session.gamePin
            : '------';

    final players = state is GameSessionUpdated
        ? (state as GameSessionUpdated).session.players
        : [];

    final isLoading =
        state is GameLoading || state is GameInitial;

    return Scaffold(
      backgroundColor: AppColors.primary600,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.neutral50),
          onPressed: () {
            context.read<GameCubit>().reset();
            context.go('/home');
          },
        ),
        title: Text('${AppConstants.gameName} — Lobby',
          style: GoogleFonts.nunito(
            color: AppColors.neutral50,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.neutral50),
            )
          : ResponsiveContainer(
              maxWidth: 600,
              child: Column(
              children: [
                const SizedBox(height: 24),

                // ── PIN display ──────────────────────────────────────────
                Text(
                  'Game PIN',
                  style: GoogleFonts.nunito(
                    color: AppColors.neutral200.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neutral800.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    pin,
                    style: GoogleFonts.nunito(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary800,
                      letterSpacing: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share this PIN with players',
                  style: GoogleFonts.nunito(
                    color: AppColors.neutral200.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Player list ──────────────────────────────────────────
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: players.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _PulsingDot(),
                                const SizedBox(height: 16),
                                Text(
                                  'Waiting for players…',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.neutral200,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${players.length} player${players.length == 1 ? '' : 's'} joined',
                                style: GoogleFonts.nunito(
                                  color: AppColors.neutral200,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: players
                                      .map((p) => _PlayerChip(
                                            nickname: p.nickname,
                                          ))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                // ── Start game button ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: state is GameLoading
                          ? null
                          : () => context.read<GameCubit>().startGame(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Start Game!',
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.neutral50,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

// ────────────────────────────────────────────────────────────────[...]
// Player Lobby — enter PIN + nickname to join
// ────────────────────────────────────────────────────────────────[...]

class _PlayerLobby extends StatelessWidget {
  final GameState state;

  const _PlayerLobby({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final hasJoined = state is GameJoined || state is GameSessionUpdated;
    final isLoading = state is GameLoading;

    return Scaffold(
      backgroundColor: AppColors.primary600,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.neutral50),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Join Game',
          style: GoogleFonts.nunito(
            color: AppColors.neutral50,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ResponsiveContainer(
        maxWidth: 600,
        child: hasJoined
            ? _WaitingForHost()
            : const Center(child: CircularProgressIndicator(color: AppColors.neutral50)),
      ),
    );
  }
}

class _WaitingForHost extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulsingDot(size: 60),
          const SizedBox(height: 24),
          Text(
            'You\'re in!',
            style: GoogleFonts.nunito(
              color: AppColors.neutral50,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Waiting for the host to start…',
            style: GoogleFonts.nunito(
              color: AppColors.neutral200,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────[...]
// Shared small widgets
// ────────────────────────────────────────────────────────────────[...]

class _PlayerChip extends StatelessWidget {
  final String nickname;
  const _PlayerChip({required this.nickname});

  static const _colors = [
  AppColors.primary400,
  AppColors.error400,
  AppColors.success400,
  AppColors.accent400,
];

  @override
  Widget build(BuildContext context) {
    final color = _colors[nickname.length % _colors.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        nickname,
        style: GoogleFonts.nunito(
          color: AppColors.neutral50,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Animated pulsing dot that indicates a "waiting" state.
class _PulsingDot extends StatefulWidget {
  final double size;
  const _PulsingDot({this.size = 24});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: AppColors.neutral50,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.neutral50.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}