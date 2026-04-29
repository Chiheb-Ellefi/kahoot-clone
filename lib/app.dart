import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_colors.dart';
import 'core/di/injection.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/app_settings_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/home/presentation/cubit/home_cubit.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/quiz/presentation/cubit/quiz_cubit.dart';
import 'features/quiz/presentation/pages/quiz_list_page.dart';
import 'features/quiz/presentation/pages/quiz_detail_page.dart';
import 'features/quiz/presentation/pages/create_quiz_page.dart';
import 'features/quiz/presentation/pages/edit_quiz_page.dart';
import 'features/quiz/data/models/quiz_model.dart';
import 'features/game/presentation/cubit/game_cubit.dart';
import 'features/game/presentation/pages/lobby_page.dart';
import 'features/game/presentation/pages/question_page.dart';
import 'features/game/presentation/pages/answer_result_page.dart';
import 'features/game/presentation/pages/leaderboard_page.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/game/presentation/pages/join_page.dart';

class QuizzoApp extends StatelessWidget {
  QuizzoApp({super.key});

  // ─── Auth cubit kept at app level so the redirect guard can react ──────
  final _authCubit = sl<AuthCubit>();

  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    refreshListenable: _GoRouterAuthNotifier(_authCubit),
    redirect: (context, state) {
      final authState = _authCubit.state;
      
      // Do not force redirects while we're still checking if there is a token.
      if (authState is AuthInitial || authState is AuthLoading) return null;

      final isLoggedIn = authState is AuthAuthenticated;

      // Handle the initial root route
      if (state.matchedLocation == '/') {
        return isLoggedIn ? '/home' : '/join';
      }
      
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      
      // Anonymous routes that anyone can access
      final isAnonymousRoute = state.matchedLocation == '/join' || 
          state.matchedLocation.startsWith('/game');

      // If not logged in and not on an allowed route, go to join page
      if (!isLoggedIn && !isAuthRoute && !isAnonymousRoute) return '/join';
      
      // If logged in and trying to access auth pages, go home
      if (isLoggedIn && isAuthRoute) return '/home';
      
      return null;
    },
    routes: [
      // ── Splash / Root ────────────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          backgroundColor: AppColors.primary800,
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.neutral50),
          ),
        ),
      ),
      // ── Anonymous / Player ───────────────────────────────────────────
      GoRoute(
        path: '/join',
        builder: (_, __) => const JoinPage(),
      ),
      // ── Auth ─────────────────────────────────────────────────────────
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),

      // ── Home ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        builder: (_, __) => BlocProvider(
          create: (_) => sl<HomeCubit>()..loadQuizzes(),
          child: const HomePage(),
        ),
      ),

      // ── Quiz ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/quizzes',
        builder: (_, __) => BlocProvider(
          create: (_) => sl<QuizCubit>()..loadPublicQuizzes(),
          child: const QuizListPage(),
        ),
      ),
      GoRoute(
        path: '/quizzes/create',
        builder: (_, __) => BlocProvider(
          create: (_) => sl<QuizCubit>(),
          child: const CreateQuizPage(),
        ),
      ),
      GoRoute(
        path: '/quizzes/:id',
        builder: (_, state) => BlocProvider(
          create: (_) =>
              sl<QuizCubit>()..loadQuizDetail(state.pathParameters['id']!),
          child: QuizDetailPage(quizId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/quizzes/:id/edit',
        builder: (_, state) {
          final quizId = state.pathParameters['id']!;
          return BlocProvider(
            create: (_) => sl<QuizCubit>()..loadQuizDetail(quizId),
            child: EditQuizPage(quizId: quizId),
          );
        },
      ),

      // ── Game ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/game/lobby',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return BlocProvider(
            create: (_) => sl<GameCubit>(),
            child: LobbyPage(
              quizId: extra['quizId'] as String?,
              isHost: extra['isHost'] as bool? ?? false,
              pin: extra['pin'] as String?,
              nickname: extra['nickname'] as String?,
              avatarUrl: extra['avatarUrl'] as String?,
            ),
          );
        },
      ),
      GoRoute(
        path: '/game/question',
        redirect: (context, state) => state.extra == null ? '/home' : null,
        builder: (_, state) {
          final gameCubit = state.extra as GameCubit;
          return BlocProvider.value(
            value: gameCubit,
            child: const QuestionPage(),
          );
        },
      ),
      GoRoute(
        path: '/game/answer-result',
        redirect: (context, state) => state.extra == null ? '/home' : null,
        builder: (_, state) {
          final gameCubit = state.extra as GameCubit;
          return BlocProvider.value(
            value: gameCubit,
            child: const AnswerResultPage(),
          );
        },
      ),
      GoRoute(
        path: '/game/leaderboard',
        redirect: (context, state) => state.extra == null ? '/home' : null,
        builder: (_, state) {
          final gameCubit = state.extra as GameCubit;
          return BlocProvider.value(
            value: gameCubit,
            child: const LeaderboardPage(),
          );
        },
      ),

      // ── Profile ───────────────────────────────────────────────────────
      GoRoute(
        path: '/profile',
        builder: (_, __) => BlocProvider(
          create: (_) => sl<ProfileCubit>()..loadProfile(),
          child: const ProfilePage(),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authCubit..checkAuthStatus(),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          AppSettingsService.instance.themeMode,
          AppSettingsService.instance.locale,
        ]),
        builder: (_, __) => MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: AppSettingsService.instance.themeMode.value,
          locale: AppSettingsService.instance.locale.value,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: _router,
        ),
      ),
    );
  }
}

/// Bridges [AuthCubit] state changes into [GoRouter]'s [Listenable] interface
/// so that the redirect guard re-evaluates on every auth state change.
class _GoRouterAuthNotifier extends ChangeNotifier {
  _GoRouterAuthNotifier(AuthCubit cubit) {
    cubit.stream.listen((_) => notifyListeners());
  }
}
