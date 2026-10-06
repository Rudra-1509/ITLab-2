class AttemptRecord {
  final String id;
  final String attemptId;
  final String examId;
  final String examTitle;
  final String userId;
  final String userEmail;
  final String userName;
  final int score;
  final double percentage;
  final int correctCount;
  final int incorrectCount;
  final int totalQuestions;
  final DateTime submittedAt;
  final String status;

  AttemptRecord({
    required this.id,
    required this.attemptId,
    required this.examId,
    required this.examTitle,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.score,
    required this.percentage,
    required this.correctCount,
    required this.incorrectCount,
    required this.totalQuestions,
    required this.submittedAt,
    required this.status,
  });

  bool get isPassed => percentage >= 50.0;

  factory AttemptRecord.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      try {
        return DateTime.parse(d.toString()).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }

    final scoreVal = int.tryParse(json['score']?.toString() ?? '0') ?? 0;
    final pctVal = double.tryParse(json['percentage']?.toString() ?? '0.0') ?? 0.0;
    final correctVal = int.tryParse(json['correctCount']?.toString() ?? '0') ?? 0;
    final incorrectVal = int.tryParse(json['incorrectCount']?.toString() ?? '0') ?? 0;
    final totalVal = int.tryParse(json['totalQuestions']?.toString() ?? '') ?? (correctVal + incorrectVal);

    return AttemptRecord(
      id: (json['id'] ?? json['_id'] ?? json['attemptId'] ?? '').toString(),
      attemptId: (json['attemptId'] ?? json['id'] ?? '').toString(),
      examId: (json['examId'] ?? '').toString(),
      examTitle: (json['examTitle'] ?? 'Exam').toString(),
      userId: (json['userId'] ?? '').toString(),
      userEmail: (json['userEmail'] ?? '').toString(),
      userName: (json['userName'] ?? json['userEmail'] ?? 'Student').toString(),
      score: scoreVal,
      percentage: pctVal,
      correctCount: correctVal,
      incorrectCount: incorrectVal,
      totalQuestions: totalVal > 0 ? totalVal : (correctVal + incorrectVal),
      submittedAt: parseDate(json['submittedAt'] ?? json['createdAt']),
      status: (json['status'] ?? (pctVal >= 50.0 ? 'PASSED' : 'FAILED')).toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'attemptId': attemptId,
        'examId': examId,
        'examTitle': examTitle,
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'score': score,
        'percentage': percentage,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'totalQuestions': totalQuestions,
        'submittedAt': submittedAt.toIso8601String(),
        'status': status,
      };

  AttemptRecord copyWith({
    String? id,
    String? attemptId,
    String? examId,
    String? examTitle,
    String? userId,
    String? userEmail,
    String? userName,
    int? score,
    double? percentage,
    int? correctCount,
    int? incorrectCount,
    int? totalQuestions,
    DateTime? submittedAt,
    String? status,
  }) {
    return AttemptRecord(
      id: id ?? this.id,
      attemptId: attemptId ?? this.attemptId,
      examId: examId ?? this.examId,
      examTitle: examTitle ?? this.examTitle,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      score: score ?? this.score,
      percentage: percentage ?? this.percentage,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
    );
  }
}
