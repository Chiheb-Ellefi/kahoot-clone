import 'package:equatable/equatable.dart';
import '../../../quiz/data/models/quiz_model.dart';

/// States for Quiz CRUD operations.
abstract class QuizState extends Equatable {
  const QuizState();
  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {
  const QuizInitial();
}

class QuizLoading extends QuizState {
  const QuizLoading();
}

/// Carries a list of quizzes (for the quiz list screen).
class QuizListLoaded extends QuizState {
  final List<QuizModel> quizzes;
  const QuizListLoaded(this.quizzes);
  @override
  List<Object?> get props => [quizzes];
}

/// Carries a single quiz (for detail / edit screens).
class QuizDetailLoaded extends QuizState {
  final QuizModel quiz;
  const QuizDetailLoaded(this.quiz);
  @override
  List<Object?> get props => [quiz];
}

/// Quiz was successfully saved (created or updated).
class QuizSaved extends QuizState {
  final QuizModel quiz;
  const QuizSaved(this.quiz);
  @override
  List<Object?> get props => [quiz];
}

/// Quiz was successfully deleted.
class QuizDeleted extends QuizState {
  const QuizDeleted();
}

class QuizError extends QuizState {
  final String message;
  const QuizError(this.message);
  @override
  List<Object?> get props => [message];
}
