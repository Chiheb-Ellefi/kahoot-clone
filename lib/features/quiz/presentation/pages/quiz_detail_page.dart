import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/quiz_cubit.dart';
import '../cubit/quiz_state.dart';
import '../../data/models/quiz_model.dart';

class QuizDetailPage extends StatelessWidget {
  final String quizId;
  const QuizDetailPage({super.key, required this.quizId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D0A5E),
      body: BlocBuilder<QuizCubit, QuizState>(
        builder: (context, state) {
          if (state is QuizLoading || state is QuizInitial) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (state is QuizError) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: const Color(0xFF46178F),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF2D0A5E),
              body: Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }
          if (state is QuizDetailLoaded) {
            return _QuizDetailView(quiz: state.quiz);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _QuizDetailView extends StatelessWidget {
  final QuizModel quiz;
  const _QuizDetailView({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Hero cover image app bar ───────────────────────────────────
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: const Color(0xFF46178F),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: context.l10n.t('edit'),
              onPressed: () =>
                  context.push('/quizzes/${quiz.id}/edit', extra: quiz),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              quiz.title,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            background: quiz.coverImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: quiz.coverImageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFF46178F),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF46178F), Color(0xFF7B2FBE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.quiz_rounded,
                        color: Colors.white38,
                        size: 80,
                      ),
                    ),
                  ),
          ),
        ),

        // ── Body ───────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats row
                Row(
                  children: [
                    Flexible(
                      child: _StatChip(
                        icon: Icons.help_outline,
                        label: context.l10n.t(
                          'questionsCount',
                          params: {'count': '${quiz.questionCount}'},
                        ),
                        color: const Color(0xFF1368CE),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: _StatChip(
                        icon: Icons.public,
                        label: quiz.isPublic
                            ? context.l10n.t('public')
                            : context.l10n.t('private'),
                        color: quiz.isPublic
                            ? const Color(0xFF26890C)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (quiz.description != null && quiz.description!.isNotEmpty)
                  Text(
                    quiz.description!,
                    style: GoogleFonts.nunito(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Host Game button ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(
                      '/game/lobby',
                      extra: {'quizId': quiz.id, 'isHost': true},
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE21B3C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.play_circle_outline,
                        color: Colors.white),
                    label: Text(
                      context.l10n.t('hostThisQuiz'),
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Questions list ─────────────────────────────────
                Text(
                  context.l10n.t('questions'),
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // Question cards
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final q = quiz.questions[i];
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFF46178F),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              q.text,
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: q.answers.map((a) {
                          final color = _hexToColor(a.color);
                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width - 72,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: a.isCorrect ? color : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (a.isCorrect)
                                    Icon(Icons.check_circle,
                                        size: 13, color: color),
                                  if (a.isCorrect) const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      a.text,
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        color: const Color(0xFF1A1A2E),
                                        fontWeight: a.isCorrect
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${q.timeLimit}s  •  ${context.l10n.t('pointsShort', params: {'points': '${q.points}'})}',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: quiz.questions.length,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
