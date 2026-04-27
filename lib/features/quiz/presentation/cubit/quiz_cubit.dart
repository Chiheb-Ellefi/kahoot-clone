import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/models/quiz_model.dart';
import 'quiz_state.dart';

/// Cubit for quiz CRUD operations (list, detail, create, update, delete).
class QuizCubit extends Cubit<QuizState> {
  final QuizRepository _repo;

  QuizCubit(this._repo) : super(const QuizInitial());

  // ─── Load all public quizzes ───────────────────────────────────────────
  Future<void> loadPublicQuizzes() async {
    emit(const QuizLoading());
    try {
      final quizzes = await _repo.getPublicQuizzes();
      emit(QuizListLoaded(quizzes));
    } catch (e) {
      emit(QuizError(e.toString()));
    }
  }

  // ─── Load user's own quizzes ───────────────────────────────────────────
  Future<void> loadMyQuizzes() async {
    emit(const QuizLoading());
    try {
      final quizzes = await _repo.getMyQuizzes();
      emit(QuizListLoaded(quizzes));
    } catch (e) {
      emit(QuizError(e.toString()));
    }
  }

  // ─── Load single quiz detail ───────────────────────────────────────────
  Future<void> loadQuizDetail(String id) async {
    emit(const QuizLoading());
    try {
      final quiz = await _repo.getQuizById(id);
      emit(QuizDetailLoaded(quiz));
    } catch (e) {
      emit(QuizError(e.toString()));
    }
  }

  // ─── Create quiz ───────────────────────────────────────────────────────
  Future<void> createQuiz(QuizModel quiz) async {
    emit(const QuizLoading());
    try {
      final created = await _repo.createQuiz(quiz);
      emit(QuizSaved(created));
    } catch (e) {
      emit(QuizError(e.toString()));
    }
  }

  // ─── Update quiz ───────────────────────────────────────────────────────
  Future<void> updateQuiz(QuizModel quiz) async {
    emit(const QuizLoading());
    try {
      final updated = await _repo.updateQuiz(quiz);
      emit(QuizSaved(updated));
    } catch (e) {
      emit(QuizError(e.toString()));
    }
  }

  // ─── Delete quiz ───────────────────────────────────────────────────────
  Future<void> deleteQuiz(String id) async {
    emit(const QuizLoading());
    try {
      await _repo.deleteQuiz(id);
      emit(const QuizDeleted());
    } catch (e) {
      emit(QuizError(e.toString()));
    }
  }
}
