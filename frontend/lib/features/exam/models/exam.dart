import 'question.dart';

class Exam {
  final String id;
  final String title;
  final int durationMinutes;
  final bool isAvailable;
  final List<Question> questions;
  final int? questionCount;

  Exam({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.isAvailable,
    this.questions = const [],
    this.questionCount,
  });

  int get totalQuestions =>
      questions.isNotEmpty ? questions.length : (questionCount ?? 0);

  bool get hasMinimumQuestions => totalQuestions >= 10;

  factory Exam.fromJson(Map<String, dynamic> json) {
    List<Question> parsedQuestions = [];
    if (json['questions'] is List) {
      parsedQuestions = (json['questions'] as List)
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList();
    }

    final duration = json['durationMinutes'] ?? json['duration'] ?? 30;

    return Exam(
      id: (json['_id'] ?? json['id'] ?? json['examId'] ?? '').toString(),
      title: (json['title'] ?? 'Untitled Exam').toString(),
      durationMinutes: duration is int ? duration : (int.tryParse(duration.toString()) ?? 30),
      isAvailable: json['isAvailable'] == true || json['isAvailable'] == 'true',
      questions: parsedQuestions,
      questionCount: json['questionCount'] is int
          ? json['questionCount'] as int
          : (parsedQuestions.isNotEmpty ? parsedQuestions.length : null),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'durationMinutes': durationMinutes,
    'isAvailable': isAvailable,
  };

  Exam copyWith({
    String? id,
    String? title,
    int? durationMinutes,
    bool? isAvailable,
    List<Question>? questions,
    int? questionCount,
  }) {
    return Exam(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isAvailable: isAvailable ?? this.isAvailable,
      questions: questions ?? this.questions,
      questionCount: questionCount ?? this.questionCount,
    );
  }
}
