import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/quiz_cubit.dart';
import '../cubit/quiz_state.dart';
import '../../data/models/quiz_model.dart';

/// Full-screen quiz list (used from the /quizzes route).
class QuizListPage extends StatelessWidget {
  const QuizListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D0A5E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF46178F),
        title: Text(
          'All Quizzes',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<QuizCubit, QuizState>(
        builder: (context, state) {
          if (state is QuizLoading || state is QuizInitial) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (state is QuizError) {
            return _CenteredError(
              message: state.message,
              onRetry: () =>
                  context.read<QuizCubit>().loadPublicQuizzes(),
            );
          }
          if (state is QuizListLoaded) {
            if (state.quizzes.isEmpty) {
              return Center(
                child: Text(
                  'No quizzes found.',
                  style: GoogleFonts.nunito(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<QuizCubit>().loadPublicQuizzes(),
              color: const Color(0xFF46178F),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.quizzes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _QuizListTile(quiz: state.quizzes[i]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _QuizListTile extends StatelessWidget {
  final QuizModel quiz;
  const _QuizListTile({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/quizzes/${quiz.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: 90,
                height: 90,
                child: quiz.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: quiz.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            _MiniPlaceholder(title: quiz.title),
                      )
                    : _MiniPlaceholder(title: quiz.title),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: const Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (quiz.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        quiz.description!,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.help_outline,
                          size: 14,
                          color: Color(0xFF46178F),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${quiz.questionCount} questions',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (quiz.authorName != null) ...[
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              quiz.authorName!,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: Color(0xFF46178F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPlaceholder extends StatelessWidget {
  final String title;
  const _MiniPlaceholder({required this.title});

  static const _colors = [
    Color(0xFF46178F),
    Color(0xFF1368CE),
    Color(0xFFE21B3C),
    Color(0xFF26890C),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[title.length % _colors.length];
    return Container(
      color: color,
      alignment: Alignment.center,
      child: Text(
        title.isNotEmpty ? title[0].toUpperCase() : 'Q',
        style: GoogleFonts.nunito(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CenteredError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CenteredError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFE21B3C),
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.nunito(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
