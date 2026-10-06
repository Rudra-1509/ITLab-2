import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attempt_record.dart';

class AttemptHistoryService {
  final SharedPreferences _prefs;
  static const String _key = 'mcq_student_attempt_records_v1';

  AttemptHistoryService(this._prefs) {
    _ensureInitialDataSeeded();
  }

  void _ensureInitialDataSeeded() {
    final existingJson = _prefs.getString(_key);
    if (existingJson == null || existingJson.trim().isEmpty || existingJson == '[]') {
      final sampleRecords = [
        AttemptRecord(
          id: 'seed_att_1',
          attemptId: 'seed_att_1',
          examId: '6a841e130dcb40fe5bfbe0d7',
          examTitle: 'Quiz 1',
          userId: '6a84182845a53bcf678b018b',
          userEmail: 'student@example.com',
          userName: 'student',
          score: 8,
          percentage: 80.0,
          correctCount: 8,
          incorrectCount: 2,
          totalQuestions: 10,
          submittedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
          status: 'PASSED',
        ),
        AttemptRecord(
          id: 'seed_att_2',
          attemptId: 'seed_att_2',
          examId: '6a841e130dcb40fe5bfbe0d7',
          examTitle: 'Quiz 1',
          userId: '6a84182845a53bcf678b018c',
          userEmail: 'student2@example.com',
          userName: 'student2',
          score: 4,
          percentage: 40.0,
          correctCount: 4,
          incorrectCount: 6,
          totalQuestions: 10,
          submittedAt: DateTime.now().subtract(const Duration(hours: 5)),
          status: 'FAILED',
        ),
      ];

      final rawList = sampleRecords.map((e) => e.toJson()).toList();
      _prefs.setString(_key, jsonEncode(rawList));
    }
  }

  List<AttemptRecord> getAllAttempts() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List decoded = jsonDecode(raw);
      final list = decoded
          .map((item) => AttemptRecord.fromJson(item as Map<String, dynamic>))
          .toList();
      // Sort newest first
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  List<AttemptRecord> getAttemptsForUser(String userId, [String? userEmail]) {
    final all = getAllAttempts();
    return all.where((a) {
      final matchId = userId.isNotEmpty && a.userId == userId;
      final matchEmail = userEmail != null &&
          userEmail.isNotEmpty &&
          a.userEmail.toLowerCase() == userEmail.toLowerCase();
      return matchId || matchEmail;
    }).toList();
  }

  List<AttemptRecord> getAttemptsForExam(String examId) {
    final all = getAllAttempts();
    return all.where((a) => a.examId == examId).toList();
  }

  AttemptRecord? getLatestAttemptForUserAndExam(
    String userId,
    String examId, [
    String? userEmail,
  ]) {
    final userAttempts = getAttemptsForUser(userId, userEmail);
    final examAttempts = userAttempts.where((a) => a.examId == examId).toList();
    if (examAttempts.isEmpty) return null;
    return examAttempts.first; // Already sorted newest first
  }

  bool isExamAttempted(String userId, String examId, [String? userEmail]) {
    return getLatestAttemptForUserAndExam(userId, examId, userEmail) != null;
  }

  Future<void> saveAttempt(AttemptRecord record) async {
    final all = getAllAttempts();
    final index = all.indexWhere(
      (a) => a.attemptId == record.attemptId || (a.id == record.id && record.id.isNotEmpty),
    );

    if (index >= 0) {
      all[index] = record;
    } else {
      all.insert(0, record);
    }

    final rawList = all.map((e) => e.toJson()).toList();
    await _prefs.setString(_key, jsonEncode(rawList));
  }

  Future<void> clearAll() async {
    await _prefs.remove(_key);
  }
}
