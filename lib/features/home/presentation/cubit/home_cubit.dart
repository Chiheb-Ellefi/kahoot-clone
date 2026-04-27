import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../quiz/data/repositories/quiz_repository.dart';
import 'home_state.dart';

/// Cubit that manages the home screen — fetches public and personal quizzes.
class HomeCubit extends Cubit<HomeState> {
  final QuizRepository _repo;

  HomeCubit(this._repo) : super(const HomeInitial());

  /// Fetch both the public quizzes and the user's own quizzes in parallel.
  Future<void> loadQuizzes() async {
    emit(const HomeLoading());
    try {
      final results = await Future.wait([
        _repo.getPublicQuizzes(),
        _repo.getMyQuizzes(),
      ]);
      emit(HomeLoaded(
        publicQuizzes: results[0],
        myQuizzes: results[1],
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  /// Delete a quiz and reload the list.
  Future<void> deleteQuiz(String quizId) async {
    try {
      await _repo.deleteQuiz(quizId);
      await loadQuizzes();
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
