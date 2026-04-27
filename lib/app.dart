import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/di/injection.dart';
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

/// Kahoot brand colours.
const _kPrimary = Color(0xFF46178F);
const _kBackground = Color(0xFF2D0A5E);

class QuizBlitzApp extends StatelessWidget {
  QuizBlitzApp({super.key});

  // ─── Auth cubit kept at app level so the redirect guard can react ──────
  final _authCubit = sl<AuthCubit>();

  late final GoRouter _router = GoRouter(
    initialLocation: '/join',
    refreshListenable: _GoRouterAuthNotifier(_authCubit),
    redirect: (context, state) {
      final authState = _authCubit.state;
      
      // Do not force redirects while we're still checking if there is a token.
      if (authState is AuthInitial || authState is AuthLoading) return null;

      final isLoggedIn = authState is AuthAuthenticated;
      
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
      child: MaterialApp.router(
        title: 'QuizBlitz',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        routerConfig: _router,
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _kPrimary,
        brightness: Brightness.dark,
        primary: _kPrimary,
        surface: _kBackground,
      ),
      scaffoldBackgroundColor: _kBackground,
      textTheme: GoogleFonts.nunitoTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF864CBF),
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white54, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
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
