import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../exam/models/question.dart';
import '../../exam/providers/exam_provider.dart';

class AddEditQuestionScreen extends ConsumerStatefulWidget {
  final String examId;
  final Question? initialQuestion;

  const AddEditQuestionScreen({
    super.key,
    required this.examId,
    this.initialQuestion,
  });

  @override
  ConsumerState<AddEditQuestionScreen> createState() =>
      _AddEditQuestionScreenState();
}

class _AddEditQuestionScreenState extends ConsumerState<AddEditQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionTextController;
  late final TextEditingController _marksController;
  late final List<TextEditingController> _optionControllers;

  int _correctAnswerIndex = 0;
  bool _isLoading = false;
  int _addedInThisSession = 0;

  bool get _isEditing => widget.initialQuestion != null;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuestion;
    _questionTextController = TextEditingController(text: q?.text ?? '');
    _marksController = TextEditingController(text: (q?.marks ?? 1).toString());

    _optionControllers = List.generate(4, (index) {
      if (q != null && index < q.options.length) {
        return TextEditingController(text: q.options[index]);
      }
      return TextEditingController();
    });

    if (q?.correctAnswer != null &&
        q!.correctAnswer! >= 0 &&
        q.correctAnswer! < 4) {
      _correctAnswerIndex = q.correctAnswer!;
    }
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _marksController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _clearFormForNextQuestion() {
    _questionTextController.clear();
    for (var c in _optionControllers) {
      c.clear();
    }
    setState(() {
      _correctAnswerIndex = 0;
      _addedInThisSession++;
    });
  }

  Future<void> _submit({bool addAnother = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final options = _optionControllers.map((c) => c.text.trim()).toList();
      final marksVal = int.tryParse(_marksController.text.trim()) ?? 1;

      final payload = {
        'text': _questionTextController.text.trim(),
        'options': options,
        'correctAnswer': _correctAnswerIndex,
        'marks': marksVal,
      };

      final repo = ref.read(examRepositoryProvider);

      if (_isEditing) {
        await repo.updateQuestion(widget.initialQuestion!.id, payload);
      } else {
        await repo.addQuestion(widget.examId, payload);
      }

      ref.invalidate(adminExamsProvider);
      ref.invalidate(examDetailProvider(widget.examId));

      if (mounted) {
        if (addAnother && !_isEditing) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Question #${_addedInThisSession + 1} added! Enter the next question.',
              ),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 2),
            ),
          );
          _clearFormForNextQuestion();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Question updated successfully!'
                    : 'Question added successfully!',
              ),
              backgroundColor: AppTheme.success,
            ),
          );
          context.pop(true);
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

  @override
  Widget build(BuildContext context) {
    final letters = ['A', 'B', 'C', 'D'];

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit MCQ Question' : 'Add MCQ Question'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEditing && _addedInThisSession > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: AppTheme.success,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$_addedInThisSession question${_addedInThisSession > 1 ? 's' : ''} added in this session so far.',
                              style: const TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

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
                                  Icons.help_outline_rounded,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isEditing
                                    ? 'Edit Question Statement'
                                    : 'Question Statement',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _questionTextController,
                            decoration: const InputDecoration(
                              labelText: 'Question Statement *',
                              hintText:
                                  'Type your multiple choice question here...',
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? 'Question text is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _marksController,
                            decoration: const InputDecoration(
                              labelText: 'Marks Awarded',
                              hintText: '1',
                              prefixIcon: Icon(Icons.star_outline, size: 20),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Marks are required';
                              }
                              if (int.tryParse(val.trim()) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

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
                                  Icons.format_list_bulleted_rounded,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '4 Options',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Fill all 4 options and mark the correct answer below',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          ...List.generate(4, (index) {
                            final isCorrect = _correctAnswerIndex == index;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(
                                        () => _correctAnswerIndex = index,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        top: 10,
                                        right: 12,
                                      ),
                                      width: 34,
                                      height: 34,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isCorrect
                                            ? AppTheme.success
                                            : AppTheme.bgLight,
                                        border: Border.all(
                                          color: isCorrect
                                              ? AppTheme.success
                                              : AppTheme.borderLight,
                                          width: isCorrect ? 2 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        letters[index],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isCorrect
                                              ? Colors.white
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _optionControllers[index],
                                      decoration: InputDecoration(
                                        labelText: 'Option ${letters[index]} *',
                                        hintText:
                                            'Enter text for Option ${letters[index]}...',
                                      ),
                                      validator: (val) =>
                                          val == null || val.trim().isEmpty
                                          ? 'Option ${letters[index]} is required'
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),

                          const Text(
                            'Select Correct Answer *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: List.generate(4, (index) {
                              final isSelected = _correctAnswerIndex == index;
                              return ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: AppTheme.success,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text('Option ${letters[index]}'),
                                  ],
                                ),
                                selected: isSelected,
                                selectedColor: AppTheme.successLight,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppTheme.success
                                      : AppTheme.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.success
                                      : AppTheme.borderLight,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setState(() => _correctAnswerIndex = index);
                                  }
                                },
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (!_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => _submit(addAnother: true),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Save & Add Next MCQ'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => _submit(addAnother: false),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: const Text('Save & Finish'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _submit(addAnother: false),
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
                            : const Icon(Icons.check),
                        label: const Text('Update Question'),
                      ),
                    ),
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
