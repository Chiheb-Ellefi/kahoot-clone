import 'package:equatable/equatable.dart';
import 'answer_model.dart';

/// Represents a single question within a quiz.
class QuestionModel extends Equatable {
  final String id;
  final String text;
  final String? imageUrl;
  final int timeLimit; // seconds
  final int points;
  final List<AnswerModel> answers;

  const QuestionModel({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.timeLimit,
    required this.points,
    required this.answers,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id']?.toString() ?? '',
      text: json['text'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      timeLimit: (json['timeLimit'] as num?)?.toInt() ?? 30,
      points: (json['points'] as num?)?.toInt() ?? 1000,
      answers:
          (json['answers'] as List<dynamic>?)
              ?.map((a) => AnswerModel.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'timeLimit': timeLimit,
        'points': points,
        'answers': answers.map((a) => a.toJson()).toList(),
      };

  QuestionModel copyWith({
    String? id,
    String? text,
    String? imageUrl,
    int? timeLimit,
    int? points,
    List<AnswerModel>? answers,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      timeLimit: timeLimit ?? this.timeLimit,
      points: points ?? this.points,
      answers: answers ?? this.answers,
    );
  }

  @override
  List<Object?> get props => [id, text, imageUrl, timeLimit, points, answers];
}
