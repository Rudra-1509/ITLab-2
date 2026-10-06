class AdminSummary {
  final int users;
  final int exams;
  final int attempts;

  AdminSummary({
    required this.users,
    required this.exams,
    required this.attempts,
  });

  factory AdminSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;

    return AdminSummary(
      users: int.tryParse(data['users']?.toString() ?? data['usersCount']?.toString() ?? '0') ?? 0,
      exams: int.tryParse(data['exams']?.toString() ?? data['examsCount']?.toString() ?? '0') ?? 0,
      attempts: int.tryParse(data['attempts']?.toString() ?? data['attemptsCount']?.toString() ?? '0') ?? 0,
    );
  }
}
