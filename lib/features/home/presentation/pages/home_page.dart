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
import '../../../auth/presentation/cubit/auth_state.dart' as auth_state;
import '../../../quiz/data/models/quiz_model.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/utils/supabase_storage.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.primary800,
        appBar: _buildAppBar(context),
        body: const _HomeBody(),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'create_quiz_fab',
          onPressed: () async {
            final result = await context.push('/quizzes/create');
            if (result == true && context.mounted) {
              context.read<HomeCubit>().loadQuizzes();
            }
          },
          backgroundColor: AppColors.error400,
          icon: const Icon(Icons.add, color: AppColors.neutral50),
          label: Text(
            context.l10n.t('createQuiz'),
            style: GoogleFonts.nunito(
              color: AppColors.neutral50,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary600,
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.quiz_rounded, color: AppColors.neutral50, size: 28),
          const SizedBox(width: 8),
          Text(
            AppConstants.appName,
            style: GoogleFonts.nunito(
              color: AppColors.neutral50,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      actions: [
        // Join game button
        IconButton(
          tooltip: context.l10n.t('joinGame'),
          icon: const Icon(Icons.gamepad_outlined, color: AppColors.neutral50),
          onPressed: () => context.push('/join'),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.tune, color: AppColors.neutral50),
          onSelected: (value) {
            switch (value) {
              case 'theme_system':
                AppSettingsService.instance.setThemeMode(ThemeMode.system);
                break;
              case 'theme_light':
                AppSettingsService.instance.setThemeMode(ThemeMode.light);
                break;
              case 'theme_dark':
                AppSettingsService.instance.setThemeMode(ThemeMode.dark);
                break;
              case 'lang_en':
                AppSettingsService.instance.setLocale(const Locale('en'));
                break;
              case 'lang_fr':
                AppSettingsService.instance.setLocale(const Locale('fr'));
                break;
              case 'lang_ar':
                AppSettingsService.instance.setLocale(const Locale('ar'));
                break;
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'theme_system',
              child: Text('${context.l10n.t('theme')}: ${context.l10n.t('system')}'),
            ),
            PopupMenuItem(
              value: 'theme_light',
              child: Text('${context.l10n.t('theme')}: ${context.l10n.t('light')}'),
            ),
            PopupMenuItem(
              value: 'theme_dark',
              child: Text('${context.l10n.t('theme')}: ${context.l10n.t('dark')}'),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'lang_en',
              child: Text('${context.l10n.t('language')}: ${context.l10n.t('english')}'),
            ),
            PopupMenuItem(
              value: 'lang_fr',
              child: Text('${context.l10n.t('language')}: ${context.l10n.t('french')}'),
            ),
            PopupMenuItem(
              value: 'lang_ar',
              child: Text('${context.l10n.t('language')}: ${context.l10n.t('arabic')}'),
            ),
          ],
        ),
        // ✅ Profile avatar with AvatarWidget
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: BlocBuilder<AuthCubit, auth_state.AuthState>(
              builder: (context, authState) {
                String? avatarUrl;
                String username = context.l10n.t('player');

                if (authState is auth_state.AuthAuthenticated) {
                  avatarUrl = authState.user.avatarUrl;
                  username = authState.user.username;
                }

                return AvatarWidget(
                  avatarUrl: avatarUrl,
                  username: username,
                  radius: 18,
                  showBorder: false,
                );
              },
            ),
          ),
        ),
      ],
      // ✅ FIXED: Clear visible tab labels
      bottom: TabBar(
        indicatorColor: AppColors.accent400,
        indicatorWeight: 4,
        labelColor: AppColors.neutral50,
        unselectedLabelColor: AppColors.neutral200,
        labelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: [
          Tab(
            icon: Icon(Icons.add_circle_outline, size: 24),
            text: context.l10n.t('make'),
          ),
          Tab(
            icon: Icon(Icons.library_books_outlined, size: 24),
            text: context.l10n.t('myQuizzes'),
          ),
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
            child: CircularProgressIndicator(color: AppColors.neutral50),
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
            Icon(Icons.quiz_outlined, color: AppColors.neutral200.withOpacity(0.35), size: 64),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: GoogleFonts.nunito(
                color: AppColors.neutral200.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<HomeCubit>().loadQuizzes(),
      color: AppColors.primary800,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width >= 1300
              ? 4
              : width >= 950
                  ? 3
                  : width >= 620
                      ? 2
                      : 1;
          final spacing = width >= 950 ? 16.0 : 12.0;
          final aspectRatio = width >= 950 ? 0.95 : 0.85;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
            ),
            itemCount: quizzes.length,
            itemBuilder: (context, i) => _QuizCard(
              quiz: quizzes[i],
              showOwnerActions: showOwnerActions,
            ),
          );
        },
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
    return _HoverLift(
      child: GestureDetector(
        onTap: () => context.push('/quizzes/${quiz.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.neutral800.withOpacity(0.2),
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
              Expanded(
                flex: 3,
                child: quiz.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: quiz.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.primary50,
                          child: const Icon(
                            Icons.image_outlined,
                            color: AppColors.primary800,
                            size: 36,
                          ),
                        ),
                        errorWidget: (_, __, ___) =>
                            _PlaceholderCover(title: quiz.title),
                      )
                    : _PlaceholderCover(title: quiz.title),
              ),
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
                          color: AppColors.neutral800,
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
                            color:AppColors.primary800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${quiz.questionCount} questions',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: AppColors.neutral600,
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
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  final String title;
  const _PlaceholderCover({required this.title});

  static const _colors = [
    AppColors.primary600,
    AppColors.primary400,
    AppColors.error400,
    AppColors.success400,
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
          color: AppColors.neutral50,
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
      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.neutral400),
      onSelected: (value) async {
        if (value == 'edit') {
          final result = await context.push('/quizzes/${quiz.id}/edit');
          if (result == true && context.mounted) {
            context.read<HomeCubit>().loadQuizzes();
          }
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
          child: Text('Delete', style: TextStyle(color: AppColors.error400)),
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
                const Text('Delete', style: TextStyle(color: AppColors.error400)),
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
            const Icon(Icons.error_outline, color: AppColors.error400, size: 56),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.nunito(color: AppColors.neutral200, fontSize: 14),
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
              color: AppColors.neutral50,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 800
                  ? 4
                  : (constraints.maxWidth > 400 ? 2 : 1);
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
                    color: AppColors.error400,
                    onTap: () async {
                      final result = await context.push('/quizzes/create');
                      if (result == true && context.mounted) {
                        context.read<HomeCubit>().loadQuizzes();
                      }
                    },
                  ),
                  _ActionCard(
                    title: 'Save time! Create with AI',
                    icon: Icons.auto_awesome,
                    color: AppColors.primary400,
                    onTap: () => _showAiDialog(context),
                  ),
                  _ActionCard(
                    title: 'Quickly create from study notes',
                    icon: Icons.picture_as_pdf,
                    color: AppColors.error400,
                    onTap: () => _uploadPdf(context),
                  ),
                  _ActionCard(
                    title: 'Turn presentations into engaging experiences',
                    icon: Icons.slideshow,
                    color:  AppColors.primary400,
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
        backgroundColor: AppColors.primary800,
        title: Text(
          'Generate with AI',
          style: GoogleFonts.nunito(
              color: AppColors.neutral50, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.neutral50),
          decoration: InputDecoration(
            hintText: 'Enter a topic (e.g. History of Rome)',
            hintStyle: TextStyle(color: AppColors.neutral200.withOpacity(0.7)),
            filled: true,
            fillColor: AppColors.neutral50.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.neutral200)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor:AppColors.success400),
            onPressed: () {
              final prompt = ctrl.text.trim();
              if (prompt.isNotEmpty) {
                Navigator.pop(ctx);
                _generateFromAi(context, prompt);
              }
            },
            child: const Text('Generate',
                style: TextStyle(color: AppColors.neutral50)),
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
        Navigator.pop(context);
        final result = await context.push('/quizzes/${quiz.id}/edit');
        if (result == true && context.mounted) {
          context.read<HomeCubit>().loadQuizzes();
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

    Future<void> _uploadPdf(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
 
    final file = result.files.first;
    if (file.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read file data.')),
      );
      return;
    }
 
    _showLoadingDialog(context, 'Uploading PDF...');
    try {
      // Upload to Supabase Storage and get the public URL
      final fileUrl = await SupabaseStorageHelper.uploadDocument(file);
 
      final repo = sl<QuizRepository>();
      final quiz = await repo.generateFromPdf(
          fileUrl: fileUrl, questionCount: 10);
 
      if (context.mounted) {
        Navigator.pop(context);
        final reload = await context.push('/quizzes/${quiz.id}/edit');
        if (reload == true && context.mounted) {
          context.read<HomeCubit>().loadQuizzes();
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }


   Future<void> _uploadPpt(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ppt', 'pptx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
 
    final file = result.files.first;
    if (file.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read file data.')),
      );
      return;
    }
 
    _showLoadingDialog(context, 'Uploading Presentation...');
    try {
      // Upload to Supabase Storage and get the public URL
      final fileUrl = await SupabaseStorageHelper.uploadDocument(file);
 
      final repo = sl<QuizRepository>();
      final quiz = await repo.generateFromPptx(
          fileUrl: fileUrl, questionCount: 10);
 
      if (context.mounted) {
        Navigator.pop(context);
        final reload = await context.push('/quizzes/${quiz.id}/edit');
        if (reload == true && context.mounted) {
          context.read<HomeCubit>().loadQuizzes();
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
 


  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.primary800,
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppColors.neutral50),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.nunito(color: AppColors.neutral50),
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
    return _HoverLift(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.neutral800.withOpacity(0.1),
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
                color: AppColors.neutral50.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.neutral50, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.nunito(
                color: AppColors.neutral50,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                height: 1.2,
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverLift extends StatefulWidget {
  final Widget child;
  const _HoverLift({required this.child});

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _hovered ? 1.015 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          child: widget.child,
        ),
      ),
    );
  }
}