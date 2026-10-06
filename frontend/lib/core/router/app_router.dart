import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/student/presentation/student_dashboard.dart';
import '../../features/student/presentation/active_exam_screen.dart';
import '../../features/student/presentation/result_screen.dart';
import '../../features/admin/presentation/admin_dashboard.dart';
import '../../features/admin/presentation/exam_management_screen.dart';
import '../../features/admin/presentation/add_edit_question_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = authState.value != null;
      final isLoggingIn = state.uri.path == '/login';

      if (!isAuth && !isLoggingIn) return '/login';

      if (isAuth && isLoggingIn) {
        final user = authState.value;
        if (user != null && user.isAdmin) {
          return '/admin';
        }
        return '/student';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Student Routes
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboard(),
        routes: [
          GoRoute(
            path: 'exam/:examId/start',
            builder: (context, state) {
              final examId = state.pathParameters['examId'] ?? '';
              final attemptId = (state.extra as String?) ?? examId;
              return ActiveExamScreen(
                examId: examId,
                attemptId: attemptId,
              );
            },
          ),
          GoRoute(
            path: 'attempt/:attemptId/result',
            builder: (context, state) => ResultScreen(
              attemptId: state.pathParameters['attemptId'] ?? '',
            ),
          ),
        ],
      ),

      // Admin Routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
        routes: [
          GoRoute(
            path: 'exams/create',
            builder: (context, state) => const ExamManagementScreen(),
          ),
          GoRoute(
            path: 'manage-exam',
            builder: (context, state) =>
                ExamManagementScreen(examId: state.extra as String?),
          ),
          GoRoute(
            path: 'exam/:examId/edit',
            builder: (context, state) => ExamManagementScreen(
              examId: state.pathParameters['examId'],
            ),
          ),
          GoRoute(
            path: 'exam/:examId/add-question',
            builder: (context, state) => AddEditQuestionScreen(
              examId: state.pathParameters['examId'] ?? '',
            ),
          ),
          GoRoute(
            path: 'exam/:examId/questions/add',
            builder: (context, state) => AddEditQuestionScreen(
              examId: state.pathParameters['examId'] ?? '',
            ),
          ),
        ],
      ),
    ],
  );
});
