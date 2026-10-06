import 'package:flutter/material.dart';
import 'add_edit_question_screen.dart';

/// Legacy alias pointing to [AddEditQuestionScreen]
class AddQuestionScreen extends StatelessWidget {
  final String examId;
  const AddQuestionScreen({super.key, required this.examId});

  @override
  Widget build(BuildContext context) {
    return AddEditQuestionScreen(examId: examId);
  }
}
