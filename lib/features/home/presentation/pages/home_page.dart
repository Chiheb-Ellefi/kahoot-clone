import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../quiz/data/models/quiz_model.dart';
import '../../../../core/di/injection.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF2D0A5E),
        appBar: _buildAppBar(context),
        body: const _HomeBody(),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'create_quiz_fab',
          onPressed: () => context.push('/quizzes/create'),
          backgroundColor: const Color(0xFFE21B3C),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Create Quiz',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF46178F),
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.quiz_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 8),
          Text(
            'Kaboot',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      actions: [
        // Join game button
        IconButton(
          tooltip: 'Join a game',
          icon: const Icon(Icons.gamepad_outlined, color: Colors.white),
          onPressed: () => context.push('/game/lobby', extra: {'isHost': false}),
        ),
        // Profile avatar
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
      bottom: TabBar(
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Make'),
          Tab(text: 'My Quizzes'),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading || state is HomeInitial) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        if (state is HomeError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<HomeCubit>().loadQuizzes(),
          );
        }
        if (state is HomeLoaded) {
          return TabBarView(
            children: [
              const _MakeDashboard(),
              _QuizGrid(
                quizzes: state.myQuizzes,
                emptyMessage: 'You haven\'t created any quizzes yet.',
                showOwnerActions: true,
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _QuizGrid extends StatelessWidget {
  final List<QuizModel> quizzes;
  final String emptyMessage;
  final bool showOwnerActions;

  const _QuizGrid({
    required this.quizzes,
    required this.emptyMessage,
    this.showOwnerActions = false,
  });

  @override
  Widget build(BuildContext context) {
    if (quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, color: Colors.white30, size: 64),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: GoogleFonts.nunito(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<HomeCubit>().loadQuizzes(),
      color: const Color(0xFF46178F),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: quizzes.length,
        itemBuilder: (context, i) => _QuizCard(
          quiz: quizzes[i],
          showOwnerActions: showOwnerActions,
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final bool showOwnerActions;

  const _QuizCard({required this.quiz, required this.showOwnerActions});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/quizzes/${quiz.id}'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover image
              Expanded(
                flex: 3,
                child: quiz.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: quiz.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFFEDE7F6),
                          child: const Icon(
                            Icons.image_outlined,
                            color: Color(0xFF46178F),
                            size: 36,
                          ),
                        ),
                        errorWidget: (_, __, ___) =>
                            _PlaceholderCover(title: quiz.title),
                      )
                    : _PlaceholderCover(title: quiz.title),
              ),

              // Info row
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: const Color(0xFF1A1A2E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.help_outline,
                            size: 13,
                            color: Color(0xFF46178F),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${quiz.questionCount} questions',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (showOwnerActions) ...[
                            const Spacer(),
                            _OwnerMenu(quiz: quiz),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  final String title;
  const _PlaceholderCover({required this.title});

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
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _OwnerMenu extends StatelessWidget {
  final QuizModel quiz;
  const _OwnerMenu({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
      onSelected: (value) async {
        if (value == 'edit') {
          context.push('/quizzes/${quiz.id}/edit', extra: quiz);
        } else if (value == 'delete') {
          final confirmed = await _confirmDelete(context);
          if (confirmed == true && context.mounted) {
            context.read<HomeCubit>().deleteQuiz(quiz.id);
          }
        } else if (value == 'host') {
          context.push(
            '/game/lobby',
            extra: {'quizId': quiz.id, 'isHost': true},
          );
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'host', child: Text('Host Game')),
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Delete "${quiz.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE21B3C), size: 56),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14),
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

class _MakeDashboard extends StatelessWidget {
  const _MakeDashboard();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create your own: quick tools to get started',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 400 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                childAspectRatio: 1.2,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _ActionCard(
                    title: 'Create content from scratch',
                    icon: Icons.add_box_rounded,
                    color: const Color(0xFFF05D22), // Orange-Red
                    onTap: () => context.push('/quizzes/create'),
                  ),
                  _ActionCard(
                    title: 'Save time! Create with AI',
                    icon: Icons.auto_awesome,
                    color: const Color(0xFF864CBF), // Purple
                    onTap: () => _showAiDialog(context),
                  ),
                  _ActionCard(
                    title: 'Quickly create from study notes',
                    icon: Icons.picture_as_pdf,
                    color: const Color(0xFFE21B3C), // Red
                    onTap: () => _uploadPdf(context),
                  ),
                  _ActionCard(
                    title: 'Turn presentations into engaging experiences',
                    icon: Icons.slideshow,
                    color: const Color(0xFF1368CE), // Blue
                    onTap: () => _uploadPpt(context),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAiDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D0A5E),
        title: Text(
          'Generate with AI',
          style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter a topic (e.g. History of Rome)',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26890C)),
            onPressed: () {
              final prompt = ctrl.text.trim();
              if (prompt.isNotEmpty) {
                Navigator.pop(ctx);
                _generateFromAi(context, prompt);
              }
            },
            child: const Text('Generate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _generateFromAi(BuildContext context, String prompt) async {
    _showLoadingDialog(context, 'Generating quiz with AI...');
    try {
      final repo = sl<QuizRepository>();
      final quiz = await repo.generateFromAi(prompt);
      if (context.mounted) {
        Navigator.pop(context); // hide loading
        context.push('/quizzes/${quiz.id}/edit', extra: quiz);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // hide loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _uploadPdf(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // required on Flutter Web to populate file.bytes
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      _showLoadingDialog(context, 'Generating quiz from PDF...');
      try {
        final repo = sl<QuizRepository>();
        final quiz = await repo.generateFromPdf(file);
        if (context.mounted) {
          Navigator.pop(context);
          context.push('/quizzes/${quiz.id}/edit', extra: quiz);
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _uploadPpt(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ppt', 'pptx'],
      withData: true, // required on Flutter Web to populate file.bytes
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      _showLoadingDialog(context, 'Generating quiz from Presentation...');
      try {
        final repo = sl<QuizRepository>();
        final quiz = await repo.generateFromPptx(file);
        if (context.mounted) {
          Navigator.pop(context);
          context.push('/quizzes/${quiz.id}/edit', extra: quiz);
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D0A5E),
        content: Row(
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.nunito(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
