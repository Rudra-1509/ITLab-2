import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../exam/models/exam.dart';
import '../../exam/providers/exam_provider.dart';
import '../../attempt/models/attempt_record.dart';
import '../../attempt/providers/attempt_provider.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedTab = 0; // 0 = Exams Management, 1 = Student Attempts & Scores
  String _examSearchQuery = '';
  final TextEditingController _examSearchController = TextEditingController();

  String _attemptSearchQuery = '';
  final TextEditingController _attemptSearchController =
      TextEditingController();
  String? _filterExamId;
  String _filterStatus = 'ALL'; // ALL, PASSED, FAILED

  @override
  void dispose() {
    _examSearchController.dispose();
    _attemptSearchController.dispose();
    super.dispose();
  }

  Future<void> _deleteExam(BuildContext context, Exam exam) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Exam?'),
        content: Text(
          'Are you sure you want to delete "${exam.title}" and all its questions? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(examRepositoryProvider).deleteExam(exam.id);
        ref.invalidate(adminExamsProvider);
        ref.invalidate(examsProvider);
        ref.invalidate(adminSummaryProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exam deleted successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting exam: $e'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    }
  }

  void _showAttemptDetailDialog(BuildContext context, AttemptRecord record) {
    final isPassed = record.isPassed;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPassed ? AppTheme.successLight : AppTheme.dangerLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPassed ? Icons.emoji_events_rounded : Icons.cancel_outlined,
                color: isPassed ? AppTheme.success : AppTheme.danger,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Student Attempt Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Info Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryLight,
                      child: Text(
                        record.userName.isNotEmpty
                            ? record.userName[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.userName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            record.userEmail,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Exam & Submission Date
              Text(
                'Exam: ${record.examTitle}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Submitted: ${_formatDateTime(record.submittedAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Score Breakdown Grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isPassed
                      ? AppTheme.successLight.withValues(alpha: 0.5)
                      : AppTheme.dangerLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPassed
                        ? AppTheme.success.withValues(alpha: 0.3)
                        : AppTheme.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Score:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${record.score} / ${record.totalQuestions} (${record.percentage.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isPassed
                                ? AppTheme.success
                                : AppTheme.danger,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppTheme.success,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Correct Answers:',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          '${record.correctCount}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.cancel,
                              size: 16,
                              color: AppTheme.danger,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Incorrect Answers:',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          '${record.incorrectCount}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final summaryAsync = ref.watch(adminSummaryProvider);
    final examsAsync = ref.watch(adminExamsProvider);
    final allAttempts = ref.watch(attemptHistoryProvider);

    // Calculate aggregated stats
    final totalAttemptsCount = allAttempts.length;
    final avgScore = totalAttemptsCount > 0
        ? (allAttempts.fold<double>(0.0, (sum, a) => sum + a.percentage) /
                  totalAttemptsCount)
              .toStringAsFixed(1)
        : '0.0';
    final passRate = totalAttemptsCount > 0
        ? ((allAttempts.where((a) => a.isPassed).length / totalAttemptsCount) *
                  100)
              .toStringAsFixed(0)
        : '0';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text('${user?.role ?? 'ADMIN'} Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh All',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(adminSummaryProvider);
              ref.invalidate(adminExamsProvider);
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
          ref.invalidate(adminSummaryProvider);
          ref.invalidate(adminExamsProvider);
          ref.invalidate(examsProvider);
          ref.read(attemptHistoryProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primaryLight,
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
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
                              user?.displayName ?? 'Admin / Examiner',
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
                        child: Text(
                          user?.role ?? 'ADMIN',
                          style: const TextStyle(
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

              // Summary Stats (Total Exams, Total Attempts, Avg Score, Pass Rate)
              Row(
                children: [
                  Expanded(
                    child: summaryAsync.when(
                      data: (summary) => _statCard(
                        'Total Exams',
                        summary.exams.toString(),
                        Icons.quiz_outlined,
                        AppTheme.secondary,
                        const Color(0xFFCCFBF1),
                      ),
                      loading: () => _statCard(
                        'Total Exams',
                        '...',
                        Icons.quiz_outlined,
                        AppTheme.secondary,
                        const Color(0xFFCCFBF1),
                      ),
                      error: (_, _) => _statCard(
                        'Total Exams',
                        '0',
                        Icons.quiz_outlined,
                        AppTheme.secondary,
                        const Color(0xFFCCFBF1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'Student Attempts',
                      totalAttemptsCount.toString(),
                      Icons.people_outline_rounded,
                      AppTheme.primary,
                      AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'Average Score',
                      '$avgScore%',
                      Icons.analytics_outlined,
                      AppTheme.accent,
                      AppTheme.warningLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'Pass Rate',
                      '$passRate%',
                      Icons.check_circle_outline_rounded,
                      AppTheme.success,
                      AppTheme.successLight,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Dashboard Tabs Selector
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
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.format_list_bulleted_rounded,
                                size: 18,
                                color: _selectedTab == 0
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Exam Management',
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
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.grade_rounded,
                                size: 18,
                                color: _selectedTab == 1
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Student Scores ($totalAttemptsCount)',
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

              // TAB 0: Exam Management
              if (_selectedTab == 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'All Exams',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/admin/exams/create'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create Exam'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Exam Search Bar
                TextField(
                  controller: _examSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search exams by title...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _examSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _examSearchController.clear();
                              setState(() => _examSearchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) =>
                      setState(() => _examSearchQuery = v.trim().toLowerCase()),
                ),

                const SizedBox(height: 16),

                _buildExamsList(context, examsAsync, allAttempts),
              ]
              // TAB 1: Student Attempts & Scores
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student Attempts & Scores',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'View all student submissions and results',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (_filterExamId != null ||
                        _filterStatus != 'ALL' ||
                        _attemptSearchQuery.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          _attemptSearchController.clear();
                          setState(() {
                            _attemptSearchQuery = '';
                            _filterExamId = null;
                            _filterStatus = 'ALL';
                          });
                        },
                        icon: const Icon(Icons.filter_alt_off, size: 16),
                        label: const Text('Clear Filters'),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Search by Student or Exam
                TextField(
                  controller: _attemptSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search by student email, name, or exam...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _attemptSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _attemptSearchController.clear();
                              setState(() => _attemptSearchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(
                    () => _attemptSearchQuery = v.trim().toLowerCase(),
                  ),
                ),

                const SizedBox(height: 12),

                // Filter Bar (Status & Exams)
                examsAsync.when(
                  data: (exams) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Status Filter Chips
                        ChoiceChip(
                          label: const Text(
                            'All Status',
                            style: TextStyle(color: Colors.black),
                          ),
                          selected: _filterStatus == 'ALL',
                          onSelected: (_) =>
                              setState(() => _filterStatus = 'ALL'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text(
                            'Passed Only',
                            style: TextStyle(color: Colors.black),
                          ),
                          selected: _filterStatus == 'PASSED',
                          onSelected: (_) =>
                              setState(() => _filterStatus = 'PASSED'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text(
                            'Failed Only',
                            style: TextStyle(color: Colors.black),
                          ),
                          selected: _filterStatus == 'FAILED',
                          onSelected: (_) =>
                              setState(() => _filterStatus = 'FAILED'),
                        ),
                        const SizedBox(width: 16),
                        // Exam Filter Dropdown
                        if (exams.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: _filterExamId,
                                hint: const Text(
                                  'Filter by Exam',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('All Exams'),
                                  ),
                                  ...exams.map(
                                    (e) => DropdownMenuItem<String?>(
                                      value: e.id,
                                      child: Text(
                                        e.title.length > 25
                                            ? '${e.title.substring(0, 25)}...'
                                            : e.title,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (val) =>
                                    setState(() => _filterExamId = val),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),

                _buildStudentAttemptsList(context, allAttempts),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamsList(
    BuildContext context,
    AsyncValue<List<Exam>> examsAsync,
    List<AttemptRecord> allAttempts,
  ) {
    return examsAsync.when(
      data: (exams) {
        final filteredExams = _examSearchQuery.isEmpty
            ? exams
            : exams
                  .where(
                    (e) => e.title.toLowerCase().contains(_examSearchQuery),
                  )
                  .toList();

        if (filteredExams.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_late_outlined,
                      size: 48,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _examSearchQuery.isEmpty
                          ? 'No Exams Created Yet'
                          : 'No exams match "$_examSearchQuery"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Click "Create Exam" to set up a new timed exam with MCQs.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/admin/exams/create'),
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Exam'),
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
          itemCount: filteredExams.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final exam = filteredExams[index];
            final qCount = exam.totalQuestions;
            final hasEnoughQuestions = qCount >= 10;
            final examAttempts = allAttempts
                .where((a) => a.examId == exam.id)
                .toList();

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
                                    Icons.timer_outlined,
                                    size: 15,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${exam.durationMinutes} Mins Timer',
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
                                    '$qCount Questions',
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
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: exam.isAvailable
                                ? AppTheme.successLight
                                : AppTheme.warningLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            exam.isAvailable ? 'LIVE' : 'DRAFT',
                            style: TextStyle(
                              color: exam.isAvailable
                                  ? AppTheme.success
                                  : AppTheme.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (!hasEnoughQuestions) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warningLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: AppTheme.warning,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Requires at least 10 questions for student attempts ($qCount/10 added)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // Action Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.go('/admin/exam/${exam.id}/edit'),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit & Timer'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go(
                            '/admin/exam/${exam.id}/questions/add',
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add MCQ'),
                        ),
                        if (examAttempts.isNotEmpty)
                          ActionChip(
                            avatar: const Icon(Icons.people, size: 16),
                            label: Text(
                              '${examAttempts.length} Attempts',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                            backgroundColor: AppTheme.primaryLight,
                            onPressed: () {
                              setState(() {
                                _selectedTab = 1;
                                _filterExamId = exam.id;
                              });
                            },
                          ),
                        IconButton(
                          tooltip: 'Delete Exam',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppTheme.danger,
                          ),
                          onPressed: () => _deleteExam(context, exam),
                        ),
                      ],
                    ),
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
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.danger, size: 36),
              const SizedBox(height: 8),
              Text(
                'Error loading admin exams: $e',
                style: const TextStyle(color: AppTheme.danger),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminExamsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentAttemptsList(
    BuildContext context,
    List<AttemptRecord> allAttempts,
  ) {
    // Filter attempts based on search query, selected exam, and status
    final filteredAttempts = allAttempts.where((att) {
      if (_filterExamId != null && att.examId != _filterExamId) {
        return false;
      }
      if (_filterStatus == 'PASSED' && !att.isPassed) {
        return false;
      }
      if (_filterStatus == 'FAILED' && att.isPassed) {
        return false;
      }
      if (_attemptSearchQuery.isNotEmpty) {
        final query = _attemptSearchQuery.toLowerCase();
        final matchUser =
            att.userName.toLowerCase().contains(query) ||
            att.userEmail.toLowerCase().contains(query);
        final matchExam = att.examTitle.toLowerCase().contains(query);
        if (!matchUser && !matchExam) return false;
      }
      return true;
    }).toList();

    if (filteredAttempts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.person_search_outlined,
                  size: 48,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No Student Attempts Found',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  'No student attempts match the selected search or filter criteria.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                if (_filterExamId != null ||
                    _filterStatus != 'ALL' ||
                    _attemptSearchQuery.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _attemptSearchController.clear();
                      setState(() {
                        _attemptSearchQuery = '';
                        _filterExamId = null;
                        _filterStatus = 'ALL';
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Filters'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredAttempts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = filteredAttempts[index];
        final isPassed = record.isPassed;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Student Name, Email & Pass/Fail status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryLight,
                      child: Text(
                        record.userName.isNotEmpty
                            ? record.userName[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.userName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            record.userEmail,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
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

                const SizedBox(height: 12),

                // Exam Title & Submission Date
                Row(
                  children: [
                    const Icon(
                      Icons.quiz_outlined,
                      size: 15,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        record.examTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    // Text(
                    //   _formatDateTime(record.submittedAt),
                    //   style: const TextStyle(
                    //     fontSize: 11,
                    //     color: AppTheme.textSecondary,
                    //   ),
                    // ),
                  ],
                ),

                const SizedBox(height: 12),

                // Score metrics row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.bgLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _scoreMetric(
                        'Score',
                        '${record.score}/${record.totalQuestions}',
                        isPassed ? AppTheme.success : AppTheme.textPrimary,
                      ),
                      Container(
                        width: 1,
                        height: 22,
                        color: AppTheme.borderLight,
                      ),
                      _scoreMetric(
                        'Percentage',
                        '${record.percentage.toStringAsFixed(0)}%',
                        isPassed ? AppTheme.success : AppTheme.danger,
                      ),
                      Container(
                        width: 1,
                        height: 22,
                        color: AppTheme.borderLight,
                      ),
                      _scoreMetric(
                        'Correct',
                        '${record.correctCount}',
                        AppTheme.success,
                      ),
                      Container(
                        width: 1,
                        height: 22,
                        color: AppTheme.borderLight,
                      ),
                      _scoreMetric(
                        'Incorrect',
                        '${record.incorrectCount}',
                        AppTheme.danger,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAttemptDetailDialog(context, record),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('View Full Breakdown'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _scoreMetric(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
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

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} at ${two(dt.hour)}:${two(dt.minute)}';
  }
}
