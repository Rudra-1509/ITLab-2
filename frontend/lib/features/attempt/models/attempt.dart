import '../../exam/models/question.dart';

class Attempt {
  final String id;
  final String examId;
  final List<Question> questions;
  final DateTime startedAt;
  final DateTime endsAt;
  final String? status;

  Attempt({
    required this.id,
    this.examId = '',
    required this.questions,
    required this.startedAt,
    required this.endsAt,
    this.status,
  });

  bool get isExpired => DateTime.now().isAfter(endsAt);

  Duration get remainingTime {
    final diff = endsAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  factory Attempt.fromJson(Map<String, dynamic> json) {
    // Check if attempt is nested in 'attempt' or 'data'
    final data = json['attempt'] is Map<String, dynamic>
        ? json['attempt']
        : (json['data'] is Map<String, dynamic> ? json['data'] : json);

    List<Question> parsedQuestions = [];
    final questionsList = data['questions'] ?? json['questions'];
    if (questionsList is List) {
      parsedQuestions = questionsList
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList();
    }

    DateTime parseDate(dynamic dateVal, DateTime fallback) {
      if (dateVal == null) return fallback;
      try {
        return DateTime.parse(dateVal.toString()).toLocal();
      } catch (_) {
        return fallback;
      }
    }

    final now = DateTime.now();
    final started = parseDate(data['startedAt'] ?? json['startedAt'], now);
    final ended = parseDate(
      data['endsAt'] ?? json['endsAt'],
      started.add(const Duration(minutes: 30)),
    );

    return Attempt(
      id: (data['_id'] ?? data['id'] ?? data['attemptId'] ?? json['_id'] ?? json['id'] ?? json['attemptId'] ?? '').toString(),
      examId: (data['examId'] ?? json['examId'] ?? '').toString(),
      questions: parsedQuestions,
      startedAt: started,
      endsAt: ended,
      status: (data['status'] ?? json['status'])?.toString(),
    );
  }
}
