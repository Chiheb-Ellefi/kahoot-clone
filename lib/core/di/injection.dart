import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/quiz/data/repositories/quiz_repository.dart';
import '../../features/quiz/presentation/cubit/quiz_cubit.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/game/data/repositories/game_repository.dart';
import '../../features/game/presentation/cubit/game_cubit.dart';
import '../../features/profile/data/repositories/profile_repository.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Registers all dependencies in the [GetIt] service locator.
/// Call this once in [main] before [runApp].
Future<void> setupDependencies() async {
  // ─── Network ────────────────────────────────────────────────────────────
  // Dio is managed as a singleton by DioClient
  sl.registerLazySingleton(() => DioClient.instance);

  // ─── Repositories ────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(dio: sl()),
  );
  sl.registerLazySingleton<QuizRepository>(
    () => QuizRepository(dio: sl()),
  );
  sl.registerLazySingleton<GameRepository>(
    () => GameRepository(dio: sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(dio: sl()),
  );

  // ─── Cubits (factories — new instance per screen) ────────────────────────
  sl.registerFactory<AuthCubit>(() => AuthCubit(sl()));
  sl.registerFactory<QuizCubit>(() => QuizCubit(sl()));
  sl.registerFactory<HomeCubit>(() => HomeCubit(sl()));
  sl.registerFactory<GameCubit>(() => GameCubit(sl()));
  sl.registerFactory<ProfileCubit>(() => ProfileCubit(sl()));
}
