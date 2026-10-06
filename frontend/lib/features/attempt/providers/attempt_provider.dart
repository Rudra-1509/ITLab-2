import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/attempt.dart';
import '../models/attempt_record.dart';
import '../models/result.dart';
import '../services/attempt_history_service.dart';

final attemptRepositoryProvider = Provider<AttemptRepository>(
  (ref) => AttemptRepository(ref.watch(dioProvider)),
);

class AttemptRepository {
  final Dio _dio;

  AttemptRepository(this._dio);

  /// Start a timed exam attempt (must have >= 10 questions)
  Future<Attempt> startExam(String examId) async {
    final res = await _dio.post('/api/exams/$examId/start');
    final data = res.data is Map<String, dynamic>
        ? res.data as Map<String, dynamic>
        : <String, dynamic>{};
    return Attempt.fromJson(data);
  }

  /// Get active attempt details and remaining time
  Future<Attempt> getAttempt(String attemptId) async {
    final res = await _dio.get('/api/attempts/$attemptId');
    final data = res.data is Map<String, dynamic>
        ? res.data as Map<String, dynamic>
        : <String, dynamic>{};
    return Attempt.fromJson(data);
  }

  /// Submit answers for an attempt
  Future<void> submitExam(
    String attemptId,
    List<Map<String, dynamic>> answers,
  ) async {
    await _dio.post(
      '/api/attempts/$attemptId/submit',
      data: {'answers': answers},
    );
  }

  /// Get final scored result
  Future<Result> getResult(String attemptId) async {
    final res = await _dio.get('/api/attempts/$attemptId/result');
    final data = res.data is Map<String, dynamic>
        ? res.data as Map<String, dynamic>
        : <String, dynamic>{};
    return Result.fromJson(data);
  }
}

final attemptResultProvider =
    FutureProvider.autoDispose.family<Result, String>((ref, attemptId) async {
  return ref.watch(attemptRepositoryProvider).getResult(attemptId);
});

final attemptHistoryServiceProvider = Provider<AttemptHistoryService>((ref) {
  final storage = ref.watch(storageProvider);
  return AttemptHistoryService(storage.prefs);
});

class AttemptHistoryNotifier extends Notifier<List<AttemptRecord>> {
  @override
  List<AttemptRecord> build() {
    final service = ref.watch(attemptHistoryServiceProvider);
    return service.getAllAttempts();
  }

  Future<void> recordAttempt(AttemptRecord record) async {
    final service = ref.read(attemptHistoryServiceProvider);
    await service.saveAttempt(record);
    state = service.getAllAttempts();
  }

  void refresh() {
    final service = ref.read(attemptHistoryServiceProvider);
    state = service.getAllAttempts();
  }
}

final attemptHistoryProvider =
    NotifierProvider<AttemptHistoryNotifier, List<AttemptRecord>>(
  AttemptHistoryNotifier.new,
);

/// List of previous attempts for the logged-in student
final studentAttemptsProvider = Provider<List<AttemptRecord>>((ref) {
  final allAttempts = ref.watch(attemptHistoryProvider);
  final user = ref.watch(authProvider).value;
  if (user == null) return [];

  return allAttempts.where((a) {
    final matchId = user.id.isNotEmpty && a.userId == user.id;
    final matchEmail = user.email.isNotEmpty &&
        a.userEmail.toLowerCase() == user.email.toLowerCase();
    return matchId || matchEmail;
  }).toList();
});

/// Check whether a specific exam has been attempted by the current student
final isExamAttemptedProvider = Provider.family<bool, String>((ref, examId) {
  final studentAttempts = ref.watch(studentAttemptsProvider);
  return studentAttempts.any((a) => a.examId == examId);
});

/// Get latest attempt record for a specific exam by the current student
final latestExamAttemptProvider =
    Provider.family<AttemptRecord?, String>((ref, examId) {
  final studentAttempts = ref.watch(studentAttemptsProvider);
  final matching = studentAttempts.where((a) => a.examId == examId).toList();
  if (matching.isEmpty) return null;
  return matching.first;
});
