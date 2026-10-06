import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../exam/providers/exam_provider.dart';
import '../../attempt/providers/attempt_provider.dart';
import '../../attempt/models/attempt.dart';
import '../../attempt/models/attempt_record.dart';

class ActiveExamScreen extends ConsumerStatefulWidget {
  final String examId;
  final String attemptId;

  const ActiveExamScreen({
    super.key,
    required this.examId,
    required this.attemptId,
  });

  @override
  ConsumerState<ActiveExamScreen> createState() => _ActiveExamScreenState();
}

class _ActiveExamScreenState extends ConsumerState<ActiveExamScreen> {
  Attempt? _attempt;
  final Map<String, int> _answers = {}; // questionId -> selectedOptionIndex (0-3)
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAttempt();
  }

  Future<void> _loadAttempt() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final attempt = await ref
          .read(attemptRepositoryProvider)
          .getAttempt(widget.attemptId);

      if (!mounted) return;

      setState(() {
        _attempt = attempt;
        _isLoading = false;
      });

      _startTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_attempt == null) return;

    // Calculate initial difference
    final now = DateTime.now();
    if (now.isAfter(_attempt!.endsAt)) {
      _timeLeft = Duration.zero;
      _submitExam(autoSubmitted: true);
      return;
    }

    _timeLeft = _attempt!.endsAt.difference(now);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final currentTime = DateTime.now();
      if (currentTime.isAfter(_attempt!.endsAt)) {
        timer.cancel();
        setState(() => _timeLeft = Duration.zero);
        _submitExam(autoSubmitted: true);
      } else {
        setState(() {
          _timeLeft = _attempt!.endsAt.difference(currentTime);
        });
      }
    });
  }

  Future<void> _submitExam({bool autoSubmitted = false}) async {
    if (_isSubmitting) return;

    if (autoSubmitted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Time is up! Submitting your answers automatically...'),
          backgroundColor: AppTheme.danger,
          duration: Duration(seconds: 3),
        ),
      );
    }

    setState(() => _isSubmitting = true);

    final payload = _answers.entries
        .map((e) => {"questionId": e.key, "answer": e.value})
        .toList();

    try {
      await ref
          .read(attemptRepositoryProvider)
          .submitExam(widget.attemptId, payload);

      _timer?.cancel();

      // Retrieve result and save into persistent attempt history
      try {
        final result = await ref
            .read(attemptRepositoryProvider)
            .getResult(widget.attemptId);

        final user = ref.read(authProvider).value;
        final exam = ref.read(examDetailProvider(widget.examId)).value;
        final examTitle = exam?.title ?? 'Exam';

        final record = AttemptRecord(
          id: widget.attemptId,
          attemptId: widget.attemptId,
          examId: widget.examId,
          examTitle: examTitle,
          userId: user?.id ?? '',
          userEmail: user?.email ?? '',
          userName: user?.displayName ?? 'Student',
          score: result.score,
          percentage: result.percentage,
          correctCount: result.correctCount,
          incorrectCount: result.incorrectCount,
          totalQuestions: result.totalQuestions ??
              (_attempt?.questions.length ??
                  (result.correctCount + result.incorrectCount)),
          submittedAt: DateTime.now(),
          status: result.isPassed ? 'PASSED' : 'FAILED',
        );

        await ref.read(attemptHistoryProvider.notifier).recordAttempt(record);
      } catch (_) {
        // Fallback: If result fetch is pending, ResultScreen will also register the record
      }

      if (mounted) {
        context.go('/student/attempt/${widget.attemptId}/result');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final errorMsg = e.toString().replaceAll('Exception:', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $errorMsg'),
            backgroundColor: AppTheme.danger,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _submitExam(),
            ),
          ),
        );
      }
    }
  }

  void _showSubmitConfirmationDialog() {
    if (_attempt == null) return;

    final totalCount = _attempt!.questions.length;
    final answeredCount = _answers.length;
    final unansweredCount = totalCount - answeredCount;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Submit Exam?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Answered: $answeredCount / $totalCount questions',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (unansweredCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ You still have $unansweredCount unanswered question${unansweredCount > 1 ? 's' : ''}.',
                style: const TextStyle(color: AppTheme.danger, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Once submitted, your answers cannot be altered and your score will be computed.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Exam'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitExam();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            child: const Text('Confirm Submit'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.isNegative || d == Duration.zero) return '00:00';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    final hours = d.inHours;

    String two(int n) => n.toString().padLeft(2, '0');

    if (hours > 0) {
      return '${two(hours)}:${two(minutes.remainder(60))}:${two(seconds)}';
    }
    return '${two(minutes)}:${two(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your exam questions...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _attempt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
                const SizedBox(height: 16),
                Text(
                  'Failed to load exam: $_errorMessage',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadAttempt,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final questions = _attempt!.questions;
    final isLowTime = _timeLeft.inMinutes < 2 && _timeLeft.inSeconds > 0;

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam')),
        body: const Center(
          child: Text('No questions found in this attempt.'),
        ),
      );
    }

    final currentQuestion = questions[_currentQuestionIndex];
    final selectedOption = _answers[currentQuestion.id];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Exit Exam?'),
              content: const Text(
                'Leaving the screen will not pause the timer. You can return from the dashboard or submit now.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Stay in Exam'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/student');
                  },
                  child: const Text('Leave'),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgLight,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              const Icon(Icons.quiz_outlined, size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Question ${_currentQuestionIndex + 1}/${questions.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            // Timer Badge
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isLowTime ? AppTheme.dangerLight : AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isLowTime ? AppTheme.danger : AppTheme.primary,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: isLowTime ? AppTheme.danger : AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(_timeLeft),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isLowTime ? AppTheme.danger : AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _isSubmitting
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Submitting answers and calculating score...',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Linear Progress Bar
                  LinearProgressIndicator(
                    value: questions.isNotEmpty
                        ? _answers.length / questions.length
                        : 0.0,
                    backgroundColor: AppTheme.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.success),
                    minHeight: 4,
                  ),

                  // Question Palette Bar
                  Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: Colors.white,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: questions.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final qId = questions[index].id;
                        final isAnswered = _answers.containsKey(qId);
                        final isCurrent = index == _currentQuestionIndex;

                        return InkWell(
                          onTap: () => setState(() => _currentQuestionIndex = index),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? AppTheme.primary
                                  : (isAnswered ? AppTheme.successLight : AppTheme.bgLight),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrent
                                    ? AppTheme.primary
                                    : (isAnswered ? AppTheme.success : AppTheme.borderLight),
                                width: isCurrent ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isCurrent
                                    ? Colors.white
                                    : (isAnswered ? AppTheme.success : AppTheme.textSecondary),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(height: 1),

                  // Main Question Area
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Question Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Q${_currentQuestionIndex + 1}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Single Choice',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    currentQuestion.text,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 4 Option Cards
                          ...List.generate(currentQuestion.options.length, (optIndex) {
                            final optionText = currentQuestion.options[optIndex];
                            final isSelected = selectedOption == optIndex;
                            final optionLetter = String.fromCharCode(65 + optIndex); // A, B, C, D

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _answers[currentQuestion.id] = optIndex;
                                  });
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.primaryLight : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected ? AppTheme.primary : AppTheme.borderLight,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected ? AppTheme.primary : AppTheme.bgLight,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.primary
                                                : AppTheme.borderLight,
                                          ),
                                        ),
                                        child: Text(
                                          optionLetter,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          optionText,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                                isSelected ? FontWeight.w600 : FontWeight.normal,
                                            color: isSelected
                                                ? AppTheme.primaryDark
                                                : AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: AppTheme.borderLight)),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          if (_currentQuestionIndex > 0)
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _currentQuestionIndex--);
                              },
                              icon: const Icon(Icons.arrow_back, size: 18),
                              label: const Text('Prev'),
                            ),
                          const Spacer(),
                          if (_currentQuestionIndex < questions.length - 1)
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() => _currentQuestionIndex++);
                              },
                              icon: const Icon(Icons.arrow_forward, size: 18),
                              label: const Text('Next'),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _showSubmitConfirmationDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                              ),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Submit Exam'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
