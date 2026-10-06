import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/exam.dart';
import '../models/question.dart';
import '../../admin/models/admin_summary.dart';

final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => ExamRepository(ref.watch(dioProvider)),
);

class ExamRepository {
  final Dio _dio;

  ExamRepository(this._dio);

  /// Fetch list of available exams for students
  Future<List<Exam>> getExams() async {
    final res = await _dio.get('/api/exams');

    if (res.data is Map<String, dynamic>) {
      final List dynamicList =
          res.data['exams'] ?? res.data['data'] ?? res.data['results'] ?? [];
      return dynamicList.map((e) => Exam.fromJson(e as Map<String, dynamic>)).toList();
    }

    if (res.data is List) {
      return (res.data as List)
          .map((e) => Exam.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Fetch list of all exams for admin (including drafts & question lists)
  Future<List<Exam>> getAdminExams() async {
    final res = await _dio.get('/api/admin/exams');

    if (res.data is Map<String, dynamic>) {
      final List dynamicList =
          res.data['exams'] ?? res.data['data'] ?? res.data['results'] ?? [];
      return dynamicList.map((e) => Exam.fromJson(e as Map<String, dynamic>)).toList();
    }

    if (res.data is List) {
      return (res.data as List)
          .map((e) => Exam.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Fetch single exam detail by ID
  Future<Exam> getExamById(String id) async {
    final res = await _dio.get('/api/exams/$id');
    final data = res.data is Map<String, dynamic>
        ? (res.data['exam'] ?? res.data['data'] ?? res.data)
        : res.data;
    return Exam.fromJson(data as Map<String, dynamic>);
  }

  /// Create a new exam (ADMIN/EXAMINER)
  Future<Exam> createExam(Map<String, dynamic> data) async {
    final res = await _dio.post('/api/exams', data: data);
    final resData = res.data is Map<String, dynamic>
        ? (res.data['exam'] ?? res.data['data'] ?? res.data)
        : res.data;
    return Exam.fromJson(resData as Map<String, dynamic>);
  }

  /// Update existing exam fields (e.g. title, durationMinutes timer, isAvailable)
  Future<void> updateExam(String id, Map<String, dynamic> data) async {
    await _dio.put('/api/exams/$id', data: data);
  }

  /// Delete exam and its questions
  Future<void> deleteExam(String id) async {
    await _dio.delete('/api/exams/$id');
  }

  /// Add question to an exam (ADMIN/EXAMINER)
  Future<Question> addQuestion(String examId, Map<String, dynamic> data) async {
    final res = await _dio.post('/api/exams/$examId/questions', data: data);
    final resData = res.data is Map<String, dynamic>
        ? (res.data['question'] ?? res.data['data'] ?? res.data)
        : res.data;
    return Question.fromJson(resData as Map<String, dynamic>);
  }

  /// Update existing question
  Future<void> updateQuestion(String questionId, Map<String, dynamic> data) async {
    await _dio.put('/api/questions/$questionId', data: data);
  }

  /// Delete question
  Future<void> deleteQuestion(String questionId) async {
    await _dio.delete('/api/questions/$questionId');
  }

  /// Get admin dashboard counts
  Future<AdminSummary> getAdminSummary() async {
    final res = await _dio.get('/api/admin/summary');
    return AdminSummary.fromJson(res.data as Map<String, dynamic>);
  }
}

/// Provider for student exam list
final examsProvider = FutureProvider.autoDispose<List<Exam>>((ref) async {
  return ref.watch(examRepositoryProvider).getExams();
});

/// Provider for admin exam list
final adminExamsProvider = FutureProvider.autoDispose<List<Exam>>((ref) async {
  return ref.watch(examRepositoryProvider).getAdminExams();
});

/// Provider for admin summary dashboard stats
final adminSummaryProvider = FutureProvider.autoDispose<AdminSummary>((ref) async {
  return ref.watch(examRepositoryProvider).getAdminSummary();
});

/// Provider for specific exam detail
final examDetailProvider =
    FutureProvider.autoDispose.family<Exam, String>((ref, id) async {
  return ref.watch(examRepositoryProvider).getExamById(id);
});
