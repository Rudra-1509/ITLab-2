import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mcq_app/core/storage/storage_service.dart';
import 'package:mcq_app/main.dart';
import 'package:mcq_app/features/exam/models/exam.dart';
import 'package:mcq_app/features/exam/models/question.dart';
import 'package:mcq_app/features/auth/models/user.dart';
import 'package:mcq_app/features/attempt/models/result.dart';
import 'package:mcq_app/features/attempt/models/attempt_record.dart';
import 'package:mcq_app/features/attempt/services/attempt_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Model Unit Tests', () {
    test('User model parses ADMIN and STUDENT correctly', () {
      final admin = User.fromJson({
        'id': '1',
        'email': 'admin@example.com',
        'role': 'ADMIN',
      });
      expect(admin.isAdmin, isTrue);
      expect(admin.isStudent, isFalse);

      final student = User.fromJson({
        'id': '2',
        'email': 'student@example.com',
        'role': 'STUDENT',
      });
      expect(student.isAdmin, isFalse);
      expect(student.isStudent, isTrue);
    });

    test('Question model parses and serializes correctly', () {
      final q = Question.fromJson({
        '_id': 'q1',
        'text': 'What is Flutter?',
        'options': ['UI Toolkit', 'Database', 'Operating System', 'Hardware'],
        'correctAnswer': 0,
        'marks': 2,
      });

      expect(q.id, 'q1');
      expect(q.text, 'What is Flutter?');
      expect(q.options.length, 4);
      expect(q.correctAnswer, 0);
      expect(q.marks, 2);
    });

    test('Exam model calculates 10-question requirement accurately', () {
      final examWithFew = Exam(
        id: 'e1',
        title: 'Short Quiz',
        durationMinutes: 15,
        isAvailable: true,
        questionCount: 4,
      );
      expect(examWithFew.hasMinimumQuestions, isFalse);

      final examWithEnough = Exam(
        id: 'e2',
        title: 'Midterm Exam',
        durationMinutes: 60,
        isAvailable: true,
        questionCount: 10,
      );
      expect(examWithEnough.hasMinimumQuestions, isTrue);
    });

    test('Result model handles percentage and score correctly', () {
      final res = Result.fromJson({
        'score': 8,
        'percentage': 80.0,
        'correctCount': 8,
        'incorrectCount': 2,
      });

      expect(res.score, 8);
      expect(res.percentage, 80.0);
      expect(res.correctCount, 8);
      expect(res.incorrectCount, 2);
      expect(res.isPassed, isTrue);
    });

    test('AttemptRecord parses, evaluates pass/fail status, and serializes correctly', () {
      final record = AttemptRecord.fromJson({
        'id': 'att_123',
        'attemptId': 'att_123',
        'examId': 'exam_1',
        'examTitle': 'Data Structures',
        'userId': 'student_1',
        'userEmail': 'student@example.com',
        'userName': 'Student One',
        'score': 9,
        'percentage': 90.0,
        'correctCount': 9,
        'incorrectCount': 1,
        'totalQuestions': 10,
        'submittedAt': DateTime.now().toIso8601String(),
        'status': 'PASSED',
      });

      expect(record.attemptId, 'att_123');
      expect(record.examTitle, 'Data Structures');
      expect(record.score, 9);
      expect(record.percentage, 90.0);
      expect(record.isPassed, isTrue);
      expect(record.totalQuestions, 10);
    });
  });

  group('AttemptHistoryService Unit Tests', () {
    test('AttemptHistoryService saves, filters, and retrieves attempts correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = AttemptHistoryService(prefs);

      // Verify sample data seeded
      final initialAttempts = service.getAllAttempts();
      expect(initialAttempts.isNotEmpty, isTrue);

      final newAttempt = AttemptRecord(
        id: 'new_test_att',
        attemptId: 'new_test_att',
        examId: 'test_exam_99',
        examTitle: 'Algorithms Final',
        userId: 'u_100',
        userEmail: 'alice@example.com',
        userName: 'Alice',
        score: 10,
        percentage: 100.0,
        correctCount: 10,
        incorrectCount: 0,
        totalQuestions: 10,
        submittedAt: DateTime.now(),
        status: 'PASSED',
      );

      await service.saveAttempt(newAttempt);

      final updatedAll = service.getAllAttempts();
      expect(updatedAll.any((a) => a.attemptId == 'new_test_att'), isTrue);

      // Test filtering by user
      final userAttempts = service.getAttemptsForUser('u_100', 'alice@example.com');
      expect(userAttempts.length, 1);
      expect(userAttempts.first.examTitle, 'Algorithms Final');

      // Test check isExamAttempted
      expect(service.isExamAttempted('u_100', 'test_exam_99'), isTrue);
      expect(service.isExamAttempted('u_100', 'non_existent_exam'), isFalse);
    });
  });

  group('Widget UI Tests', () {
    testWidgets('App renders LoginScreen with header, inputs, and sign in button', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageProvider.overrideWithValue(StorageService(prefs)),
          ],
          child: const MCQSystemApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('College MCQ System'), findsOneWidget);
      expect(find.text('Email or Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
