class Question {
  final String id;
  final String text;
  final List<String> options;
  final int? correctAnswer; // Null for students in sanitized mode
  final int marks;

  Question({
    required this.id,
    required this.text,
    required this.options,
    this.correctAnswer,
    this.marks = 1,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    List<String> parsedOptions = [];
    if (json['options'] is List) {
      parsedOptions = (json['options'] as List)
          .map((opt) => opt.toString())
          .toList();
    }

    int? correctAns;
    if (json['correctAnswer'] != null) {
      correctAns = int.tryParse(json['correctAnswer'].toString());
    }

    int marksVal = 1;
    if (json['marks'] != null) {
      marksVal = int.tryParse(json['marks'].toString()) ?? 1;
    }

    return Question(
      id: (json['_id'] ?? json['id'] ?? json['questionId'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      options: parsedOptions,
      correctAnswer: correctAns,
      marks: marksVal,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'text': text,
      'options': options,
      'marks': marks,
    };
    if (correctAnswer != null) {
      map['correctAnswer'] = correctAnswer;
    }
    return map;
  }

  Question copyWith({
    String? id,
    String? text,
    List<String>? options,
    int? correctAnswer,
    int? marks,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      marks: marks ?? this.marks,
    );
  }
}
