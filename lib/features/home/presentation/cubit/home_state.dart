import 'package:equatable/equatable.dart';
import '../../../quiz/data/models/quiz_model.dart';

/// States for the Home feature.
abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final List<QuizModel> publicQuizzes;
  final List<QuizModel> myQuizzes;
  const HomeLoaded({required this.publicQuizzes, required this.myQuizzes});
  @override
  List<Object?> get props => [publicQuizzes, myQuizzes];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}
