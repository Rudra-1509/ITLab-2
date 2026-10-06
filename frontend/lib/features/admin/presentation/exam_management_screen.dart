import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../exam/models/exam.dart';
import '../../exam/models/question.dart';
import '../../exam/providers/exam_provider.dart';
import 'add_edit_question_screen.dart';

class ExamManagementScreen extends ConsumerStatefulWidget {
  final String? examId;
  const ExamManagementScreen({super.key, this.examId});

  @override
  ConsumerState<ExamManagementScreen> createState() =>
      _ExamManagementScreenState();
}

class _ExamManagementScreenState extends ConsumerState<ExamManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isInitialized = false;

  bool get _isEditing => widget.examId != null;

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _populateFromExam(Exam exam) {
    if (_isInitialized) return;
    _isInitialized = true;
    _titleController.text = exam.title;
    _durationController.text = exam.durationMinutes.toString();
    _isAvailable = exam.isAvailable;
  }

  Future<void> _saveExam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(examRepositoryProvider);
      final duration = int.tryParse(_durationController.text.trim()) ?? 30;

      final data = {
        'title': _titleController.text.trim(),
        'durationMinutes': duration,
        'isAvailable': _isAvailable,
      };

      if (_isEditing) {
        await repo.updateExam(widget.examId!, data);
        ref.invalidate(adminExamsProvider);
        ref.invalidate(examsProvider);
        ref.invalidate(examDetailProvider(widget.examId!));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exam updated successfully!'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        final createdExam = await repo.createExam(data);
        ref.invalidate(adminExamsProvider);
        ref.invalidate(examsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Exam created! You can now add questions manually.',
              ),
              backgroundColor: AppTheme.success,
            ),
          );
          // Redirect to edit mode for this newly created exam so admin can add questions
          context.go('/admin/exam/${createdExam.id}/edit');
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception:', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMsg'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteQuestion(String questionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question?'),
        content: const Text(
          'Are you sure you want to delete this MCQ question from the exam?',
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

    if (confirm == true && widget.examId != null) {
      try {
        await ref.read(examRepositoryProvider).deleteQuestion(questionId);
        ref.invalidate(adminExamsProvider);
        ref.invalidate(examDetailProvider(widget.examId!));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Question deleted'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting question: $e'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    }
  }

  void _openAddQuestion() {
    if (widget.examId == null) return;
    context.go('/admin/exam/${widget.examId}/questions/add');
  }

  void _openEditQuestion(Question question) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditQuestionScreen(
          examId: widget.examId!,
          initialQuestion: question,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final examDetailAsync = _isEditing
        ? ref.watch(examDetailProvider(widget.examId!))
        : null;

    if (examDetailAsync != null) {
      examDetailAsync.whenData((exam) => _populateFromExam(exam));
    }

    final letters = ['A', 'B', 'C', 'D'];

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(_isEditing ? 'Manage Exam' : 'Create New Exam'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Refresh Exam Data',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(examDetailProvider(widget.examId!));
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exam Details Card (Timer & Settings)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit_note_rounded,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Exam Settings & Timer',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Title Field
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Exam Title *',
                              hintText:
                                  'e.g. Data Structures Midterm Examination',
                              prefixIcon: Icon(Icons.title, size: 20),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Exam title is required'
                                : null,
                          ),
                          const SizedBox(height: 18),

                          // Duration / Timer Field
                          TextFormField(
                            controller: _durationController,
                            decoration: const InputDecoration(
                              labelText: 'Duration Timer (Minutes) *',
                              hintText: '30',
                              prefixIcon: Icon(Icons.timer_outlined, size: 20),
                              suffixText: 'Minutes',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Duration is required';
                              }
                              final num = int.tryParse(v.trim());
                              if (num == null || num <= 0) {
                                return 'Enter a valid positive number of minutes';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Quick Timer Preset Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Presets:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              ...[15, 30, 45, 60, 90, 120].map((mins) {
                                final isSelected =
                                    _durationController.text == mins.toString();
                                return ActionChip(
                                  label: Text('$mins min'),
                                  backgroundColor: isSelected
                                      ? AppTheme.primaryLight
                                      : AppTheme.bgLight,
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.borderLight,
                                  ),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.textPrimary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _durationController.text = mins
                                          .toString();
                                    });
                                  },
                                );
                              }),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Is Available Switch
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.bgLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Publish Exam to Students',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        _isAvailable
                                            ? 'Exam is visible and can be attempted by students (if >= 10 questions).'
                                            : 'Exam is saved as draft and hidden from students.',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isAvailable,
                                  activeTrackColor: AppTheme.primary,
                                  onChanged: (v) =>
                                      setState(() => _isAvailable = v),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveExam,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _isEditing
                                    ? 'Update Exam & Timer'
                                    : 'Create Exam & Start Adding Questions',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Questions Section (When Editing an Exam)
                  if (_isEditing) ...[
                    const SizedBox(height: 24),

                    examDetailAsync?.when(
                          data: (exam) {
                            final questions = exam.questions;
                            final questionCount = questions.length;
                            final hasEnoughQuestions = questionCount >= 10;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Questions Header & Actions
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment
                                      .center, // Aligns button nicely
                                  children: [
                                    // 1. Wrap the left side in an Expanded widget
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // 2. Change inner Row to a Wrap to prevent internal overflow
                                          Wrap(
                                            spacing:
                                                8, // Horizontal spacing between text and badge
                                            runSpacing:
                                                6, // Vertical spacing if they wrap to two lines
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                'Exam Questions ($questionCount)',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: hasEnoughQuestions
                                                      ? AppTheme.successLight
                                                      : AppTheme.warningLight,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  hasEnoughQuestions
                                                      ? 'Ready (≥ 10 MCQs)'
                                                      : '$questionCount/10 MCQs',
                                                  style: TextStyle(
                                                    color: hasEnoughQuestions
                                                        ? AppTheme.success
                                                        : AppTheme.warning,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ), // 3. Add a little breathing room
                                    // The button stays its natural size on the right
                                    ElevatedButton.icon(
                                      onPressed: _openAddQuestion,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text(
                                        'Add Question',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),

                                if (!hasEnoughQuestions) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warningLight,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppTheme.warning.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: AppTheme.warning,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Backend requirement: The exam needs at least 10 questions before students can start it. You need ${10 - questionCount} more question${10 - questionCount > 1 ? 's' : ''}. Use "Add MCQ Question" to add them one by one.',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 16),

                                // Questions List
                                if (questions.isEmpty)
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(36.0),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.quiz_outlined,
                                              size: 48,
                                              color: AppTheme.textSecondary
                                                  .withValues(alpha: 0.5),
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'No questions added yet',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'Add questions manually one by one to configure your exam.',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton.icon(
                                              onPressed: _openAddQuestion,
                                              icon: const Icon(Icons.add),
                                              label: const Text(
                                                'Add First MCQ Question',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: questions.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, qIndex) {
                                      final q = questions[qIndex];
                                      final correctIndex = q.correctAnswer;

                                      return Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppTheme.primaryLight,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'Q${qIndex + 1}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppTheme.primary,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.bgLight,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '${q.marks} Mark${q.marks > 1 ? 's' : ''}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppTheme
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  IconButton(
                                                    tooltip: 'Edit Question',
                                                    icon: const Icon(
                                                      Icons.edit_outlined,
                                                      size: 20,
                                                      color: AppTheme.primary,
                                                    ),
                                                    onPressed: () =>
                                                        _openEditQuestion(q),
                                                  ),
                                                  IconButton(
                                                    tooltip: 'Delete Question',
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      size: 20,
                                                      color: AppTheme.danger,
                                                    ),
                                                    onPressed: () =>
                                                        _deleteQuestion(q.id),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                q.text,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              // Options Grid
                                              ...List.generate(q.options.length, (
                                                optIdx,
                                              ) {
                                                final isCorrect =
                                                    correctIndex == optIdx;
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 6.0,
                                                      ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isCorrect
                                                          ? AppTheme
                                                                .successLight
                                                          : AppTheme.bgLight,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color: isCorrect
                                                            ? AppTheme.success
                                                            : AppTheme
                                                                  .borderLight,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          '${letters[optIdx]}. ',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12,
                                                            color: isCorrect
                                                                ? AppTheme
                                                                      .success
                                                                : AppTheme
                                                                      .textSecondary,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            q.options[optIdx],
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              color: isCorrect
                                                                  ? AppTheme
                                                                        .textPrimary
                                                                  : AppTheme
                                                                        .textSecondary,
                                                              fontWeight:
                                                                  isCorrect
                                                                  ? FontWeight
                                                                        .w600
                                                                  : FontWeight
                                                                        .normal,
                                                            ),
                                                          ),
                                                        ),
                                                        if (isCorrect)
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 2,
                                                                ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: AppTheme
                                                                      .success,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        4,
                                                                      ),
                                                                ),
                                                            child: const Text(
                                                              'CORRECT',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 9,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (err, _) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'Error loading questions: $err',
                                style: const TextStyle(color: AppTheme.danger),
                              ),
                            ),
                          ),
                        ) ??
                        const SizedBox.shrink(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
