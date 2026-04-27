import 'package:equatable/equatable.dart';

/// Represents a single answer choice within a question.
class AnswerModel extends Equatable {
  final String id;
  final String text;
  final bool isCorrect;
  final String color; // hex color e.g. '#E21B3C'

  const AnswerModel({
    required this.id,
    required this.text,
    required this.isCorrect,
    required this.color,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    // Jackson (Spring Boot) strips the 'is' prefix from boolean getters,
    // so the backend may send 'correct' instead of 'isCorrect'.
    // We try 'isCorrect' first (raw AI JSON), then fall back to 'correct' (DB response).
    final isCorrect =
        json['isCorrect'] as bool? ?? json['correct'] as bool? ?? false;
    return AnswerModel(
      id: json['id']?.toString() ?? '',
      text: json['text'] as String? ?? '',
      isCorrect: isCorrect,
      color: json['color'] as String? ?? '#E21B3C',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'correct': isCorrect,
        'color': color,
      };

  AnswerModel copyWith({
    String? id,
    String? text,
    bool? isCorrect,
    String? color,
  }) {
    return AnswerModel(
      id: id ?? this.id,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
      color: color ?? this.color,
    );
  }

  @override
  List<Object?> get props => [id, text, isCorrect, color];
}
