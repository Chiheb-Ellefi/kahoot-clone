import 'package:equatable/equatable.dart';
import 'question_model.dart';

/// Represents a full quiz with metadata and its list of questions.
class QuizModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final List<QuestionModel> questions;
  final String? authorId;
  final String? authorName;
  final bool isPublic;
  final int? _questionCount;

  const QuizModel({
    required this.id,
    required this.title,
    this.description,
    this.coverImageUrl,
    required this.questions,
    this.authorId,
    this.authorName,
    this.isPublic = true,
    int? questionCount,
  }) : _questionCount = questionCount;

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      authorId: json['authorId']?.toString(),
      authorName: json['authorName'] as String?,
      isPublic: json['isPublic'] as bool? ?? true,
      questionCount: json['questionCount'] as int? ?? json['numberOfQuestions'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (description != null) 'description': description,
        if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
        'questions': questions.map((q) => q.toJson()).toList(),
        if (authorId != null) 'authorId': authorId,
        'isPublic': isPublic,
      };

  /// Used when creating/updating — strips the server-assigned fields.
  Map<String, dynamic> toCreateJson() => {
        'title': title,
        if (description != null) 'description': description,
        if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
        'questions': questions.map((q) => q.toJson()).toList(),
        'isPublic': isPublic,
      };

  int get questionCount => _questionCount ?? questions.length;

  QuizModel copyWith({
    String? id,
    String? title,
    String? description,
    String? coverImageUrl,
    List<QuestionModel>? questions,
    String? authorId,
    String? authorName,
    bool? isPublic,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      questions: questions ?? this.questions,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        coverImageUrl,
        questions,
        authorId,
        authorName,
        isPublic,
      ];
}
