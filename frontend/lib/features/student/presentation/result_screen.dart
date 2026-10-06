import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../attempt/providers/attempt_provider.dart';

class ResultScreen extends ConsumerWidget {
  final String attemptId;

  const ResultScreen({super.key, required this.attemptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(attemptResultProvider(attemptId));
    final historyList = ref.watch(attemptHistoryProvider);
    final cachedRecord = historyList.where((a) => a.attemptId == attemptId || a.id == attemptId).firstOrNull;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/student');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgLight,
        appBar: AppBar(
          title: const Text('Exam Result'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Dashboard',
              icon: const Icon(Icons.home_outlined),
              onPressed: () => context.go('/student'),
            ),
          ],
        ),
        body: resultAsync.when(
          data: (result) {
            return _buildResultView(
              context: context,
              score: result.score,
              percentage: result.percentage,
              correctCount: result.correctCount,
              incorrectCount: result.incorrectCount,
              examTitle: cachedRecord?.examTitle,
              submittedAt: cachedRecord?.submittedAt,
            );
          },
          loading: () => cachedRecord != null
              ? _buildResultView(
                  context: context,
                  score: cachedRecord.score,
                  percentage: cachedRecord.percentage,
                  correctCount: cachedRecord.correctCount,
                  incorrectCount: cachedRecord.incorrectCount,
                  examTitle: cachedRecord.examTitle,
                  submittedAt: cachedRecord.submittedAt,
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Fetching your verified result...'),
                    ],
                  ),
                ),
          error: (err, _) {
            if (cachedRecord != null) {
              return _buildResultView(
                context: context,
                score: cachedRecord.score,
                percentage: cachedRecord.percentage,
                correctCount: cachedRecord.correctCount,
                incorrectCount: cachedRecord.incorrectCount,
                examTitle: cachedRecord.examTitle,
                submittedAt: cachedRecord.submittedAt,
              );
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
                    const SizedBox(height: 16),
                    Text(
                      'Could not load result: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.danger),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(attemptResultProvider(attemptId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultView({
    required BuildContext context,
    required int score,
    required double percentage,
    required int correctCount,
    required int incorrectCount,
    String? examTitle,
    DateTime? submittedAt,
  }) {
    final isPassed = percentage >= 50.0;
    final pctStr = percentage.toStringAsFixed(1);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 36.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Icon Badge
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPassed
                          ? AppTheme.successLight
                          : AppTheme.warningLight,
                      border: Border.all(
                        color: isPassed ? AppTheme.success : AppTheme.warning,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isPassed
                          ? Icons.emoji_events_rounded
                          : Icons.assignment_turned_in_outlined,
                      size: 42,
                      color: isPassed ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    isPassed ? 'Exam Passed!' : 'Exam Completed',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isPassed
                        ? 'Great job! You achieved a passing score.'
                        : 'Your exam has been submitted and evaluated.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  if (examTitle != null && examTitle.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.bgLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Text(
                        examTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Score Highlight Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: isPassed
                          ? AppTheme.successLight.withValues(alpha: 0.5)
                          : AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isPassed
                            ? AppTheme.success.withValues(alpha: 0.3)
                            : AppTheme.borderLight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'FINAL SCORE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: isPassed
                                ? AppTheme.success
                                : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: isPassed
                                ? AppTheme.success
                                : AppTheme.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isPassed
                                ? AppTheme.success
                                : (percentage >= 40 ? AppTheme.warning : AppTheme.danger),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$pctStr%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Breakdown Cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.successLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.success,
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$correctCount',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.success,
                                ),
                              ),
                              const Text(
                                'Correct',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.cancel_rounded,
                                color: AppTheme.danger,
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$incorrectCount',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.danger,
                                ),
                              ),
                              const Text(
                                'Incorrect',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (submittedAt != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Submitted on ${_formatDateTime(submittedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/student'),
                      icon: const Icon(Icons.dashboard_rounded),
                      label: const Text('Back to Dashboard'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} at ${two(dt.hour)}:${two(dt.minute)}';
  }
}
