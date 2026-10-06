class Result {
  final int score;
  final double percentage;
  final int correctCount;
  final int incorrectCount;
  final int? totalQuestions;
  final String? attemptId;
  final String? status;

  Result({
    required this.score,
    required this.percentage,
    required this.correctCount,
    required this.incorrectCount,
    this.totalQuestions,
    this.attemptId,
    this.status,
  });

  bool get isPassed => percentage >= 50.0;

  factory Result.fromJson(Map<String, dynamic> json) {
    // If wrapped in result or data
    final data = json['result'] is Map<String, dynamic>
        ? json['result']
        : (json['data'] is Map<String, dynamic> ? json['data'] : json);

    final scoreVal = int.tryParse(data['score']?.toString() ?? '0') ?? 0;

    double pctVal = 0.0;
    if (data['percentage'] != null) {
      pctVal = double.tryParse(data['percentage'].toString()) ?? 0.0;
    }

    final correct = int.tryParse(data['correctCount']?.toString() ?? '0') ?? 0;
    final incorrect = int.tryParse(data['incorrectCount']?.toString() ?? '0') ?? 0;
    final total = int.tryParse(data['totalQuestions']?.toString() ?? '') ?? (correct + incorrect);

    return Result(
      score: scoreVal,
      percentage: pctVal,
      correctCount: correct,
      incorrectCount: incorrect,
      totalQuestions: total > 0 ? total : null,
      attemptId: data['attemptId']?.toString(),
      status: data['status']?.toString(),
    );
  }
}
