import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../exam/models/exam.dart';
import '../../exam/providers/exam_provider.dart';
import '../../attempt/models/attempt_record.dart';
import '../../attempt/providers/attempt_provider.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  int _selectedTab = 0; // 0 = Available Exams, 1 = Attempt History

  void _showStartConfirmation(BuildContext context, Exam exam, {bool isRetake = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.timer_outlined, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isRetake ? 'Retake Timed Exam' : 'Start Timed Exam',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exam.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.schedule, 'Duration', '${exam.durationMinutes} Minutes'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.format_list_numbered, 'Questions', '10 MCQ Questions'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.lock_clock, 'Submission', 'Auto-submits on timeout'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Once started, the timer cannot be paused. Ensure you have a stable connection.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _startExam(context, exam);
            },
            child: Text(isRetake ? 'Begin Retake Now' : 'Begin Exam Now'),
          ),
        ],
      ),
    );
  }

  static Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _startExam(BuildContext context, Exam exam) async {
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Preparing your timed exam...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final attempt =
          await ref.read(attemptRepositoryProvider).startExam(exam.id);

      if (context.mounted) {
        // Pop loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        // Navigate to active exam
        context.go(
          '/student/exam/${exam.id}/start',
          extra: attempt.id,
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Pop loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        final errorMsg = e
            .toString()
            .replaceAll('Exception:', '')
            .replaceAll('DioException:', '')
            .trim();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: AppTheme.danger),
                SizedBox(width: 8),
                Text('Cannot Start Exam'),
              ],
            ),
            content: Text(
              errorMsg.contains('10')
                  ? 'This exam has fewer than 10 questions configured. The examiner must add at least 10 questions before students can take it.'
                  : errorMsg,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final examsAsync = ref.watch(examsProvider);
    final studentAttempts = ref.watch(studentAttemptsProvider);

    final passedAttemptsCount =
        studentAttempts.where((a) => a.isPassed).length;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Student Portal'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(examsProvider);
              ref.read(attemptHistoryProvider.notifier).refresh();
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(examsProvider);
          ref.read(attemptHistoryProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primaryLight,
                        child: const Icon(
                          Icons.school_rounded,
                          size: 30,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Student',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'STUDENT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Summary Stat Cards
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'Total Attempts',
                      '${studentAttempts.length}',
                      Icons.history_rounded,
                      AppTheme.primary,
                      AppTheme.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'Exams Passed',
                      '$passedAttemptsCount',
                      Icons.check_circle_outline_rounded,
                      AppTheme.success,
                      AppTheme.successLight,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Navigation Tabs (Available Exams vs Attempt History)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.borderLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTab = 0),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _selectedTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 18,
                                color: _selectedTab == 0
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Available Exams',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _selectedTab == 0
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: _selectedTab == 0
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTab = 1),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _selectedTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_edu_rounded,
                                size: 18,
                                color: _selectedTab == 1
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'My Attempts (${studentAttempts.length})',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _selectedTab == 1
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: _selectedTab == 1
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab 0: Available Exams
              if (_selectedTab == 0)
                _buildAvailableExamsTab(context, examsAsync)
              else
                _buildAttemptHistoryTab(context, studentAttempts),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableExamsTab(
    BuildContext context,
    AsyncValue<List<Exam>> examsAsync,
  ) {
    return examsAsync.when(
      data: (exams) {
        final availableExams = exams.where((e) => e.isAvailable).toList();

        if (availableExams.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 48.0,
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 54,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Exams Available Right Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Check back later when an examiner publishes an exam.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: availableExams.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final exam = availableExams[index];
            final latestAttempt = ref.watch(latestExamAttemptProvider(exam.id));
            final isAttempted = latestAttempt != null;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exam.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 15,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${exam.durationMinutes} Minutes Duration',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.quiz_outlined,
                                    size: 15,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${exam.totalQuestions > 0 ? exam.totalQuestions : 10} Questions',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Badges (Attempted vs Active)
                        if (isAttempted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: latestAttempt.isPassed
                                  ? AppTheme.successLight
                                  : AppTheme.warningLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: latestAttempt.isPassed
                                    ? AppTheme.success
                                    : AppTheme.warning,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 13,
                                  color: latestAttempt.isPassed
                                      ? AppTheme.success
                                      : AppTheme.warning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ATTEMPTED',
                                  style: TextStyle(
                                    color: latestAttempt.isPassed
                                        ? AppTheme.success
                                        : AppTheme.warning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // If Attempted, show previous score banner
                    if (isAttempted) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.bgLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 18,
                              color: latestAttempt.isPassed
                                  ? AppTheme.success
                                  : AppTheme.warning,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Latest Score: ',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              '${latestAttempt.score}/${latestAttempt.totalQuestions} (${latestAttempt.percentage.toStringAsFixed(0)}%)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: latestAttempt.isPassed
                                    ? AppTheme.success
                                    : AppTheme.warning,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              latestAttempt.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: latestAttempt.isPassed
                                    ? AppTheme.success
                                    : AppTheme.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Actions
                    if (isAttempted) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.go(
                                  '/student/attempt/${latestAttempt.attemptId}/result',
                                );
                              },
                              icon: const Icon(Icons.analytics_outlined, size: 18),
                              label: const Text('View Result'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showStartConfirmation(
                                context,
                                exam,
                                isRetake: true,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                              ),
                              icon: const Icon(Icons.replay_rounded, size: 18),
                              label: const Text('Retake Exam'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showStartConfirmation(
                            context,
                            exam,
                          ),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start Timed Exam'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.danger, size: 36),
              const SizedBox(height: 8),
              Text(
                'Error loading exams: $err',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.danger),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(examsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttemptHistoryTab(
    BuildContext context,
    List<AttemptRecord> attempts,
  ) {
    if (attempts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.history_edu_rounded,
                  size: 54,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Previous Attempts Yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Complete an exam from the "Available Exams" tab to view your scores and full evaluation history here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _selectedTab = 0),
                  icon: const Icon(Icons.quiz_outlined),
                  label: const Text('Go to Available Exams'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attempts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = attempts[index];
        final isPassed = record.isPassed;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.examTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 13,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(record.submittedAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Pass/Fail Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPassed
                            ? AppTheme.successLight
                            : AppTheme.dangerLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPassed ? 'PASSED' : 'FAILED',
                        style: TextStyle(
                          color: isPassed ? AppTheme.success : AppTheme.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Score stats row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _attemptMetric(
                        'Score',
                        '${record.score}/${record.totalQuestions}',
                        isPassed ? AppTheme.success : AppTheme.textPrimary,
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: AppTheme.borderLight,
                      ),
                      _attemptMetric(
                        'Percentage',
                        '${record.percentage.toStringAsFixed(0)}%',
                        isPassed ? AppTheme.success : AppTheme.danger,
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: AppTheme.borderLight,
                      ),
                      _attemptMetric(
                        'Correct',
                        '${record.correctCount}',
                        AppTheme.success,
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: AppTheme.borderLight,
                      ),
                      _attemptMetric(
                        'Incorrect',
                        '${record.incorrectCount}',
                        AppTheme.danger,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.go('/student/attempt/${record.attemptId}/result');
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View Full Score Card'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _attemptMetric(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String count,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} at ${two(dt.hour)}:${two(dt.minute)}';
  }
}
