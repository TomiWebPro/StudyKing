import 'package:dio/dio.dart';

enum DynamicQuestionType {
  multipleChoice,
  input,
  graph,
  calculation,
  trueFalse,
  match,
}

class McqOptionsConfig {
  static const int minOptions = 2;
  static const int maxOptions = 10;
  static const int defaultOptions = 5;

  bool validateOptions(int count) => count >= minOptions && count <= maxOptions;

  int adjustOptions(int count) {
    if (count < minOptions) return minOptions;
    if (count > maxOptions) return maxOptions;
    return count;
  }
}

class LessonQuestion {
  final String? questionId;
  final String? questionText;
  final DateTime? createdAt;
  final String? questionType;
  final String? correctAnswer;
  final List<String>? options;
  final String? sourceMaterial;
  final int? difficulty;

  LessonQuestion({
    this.questionId,
    this.questionText,
    this.createdAt,
    this.questionType,
    this.correctAnswer,
    this.options,
    this.sourceMaterial,
    this.difficulty,
  });

  factory LessonQuestion.fromJson(Map<String, dynamic> json) {
    return LessonQuestion(
      questionId: json['question_id'] as String?,
      questionText: json['question_text'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      questionType: json['question_type'] as String?,
      correctAnswer: json['correct_answer'] as String?,
      options: json['options'] is List
          ? List<String>.from(json['options'])
          : null,
      sourceMaterial: json['source_material_id'] as String?,
      difficulty: json['difficulty'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'question_text': questionText,
    'created_at': createdAt?.toIso8601String(),
    'question_type': questionType,
    'correct_answer': correctAnswer,
    'options': options,
    'source_material_id': sourceMaterial,
    'difficulty': difficulty,
  };

  LessonQuestion clone() {
    return LessonQuestion(
      questionId: questionId,
      questionText: questionText,
      createdAt: createdAt,
      questionType: questionType,
      correctAnswer: correctAnswer,
      options: options != null ? List<String>.from(options!) : null,
      sourceMaterial: sourceMaterial,
      difficulty: difficulty,
    );
  }

  bool hasValidMcqOptions() {
    if (questionType != 'multipleChoice') return true;
    if (options == null) return false;
    final count = options!.length;
    return count >= McqOptionsConfig.minOptions && count <= McqOptionsConfig.maxOptions;
  }
}

class DynamicLessonQuestionGenerator {
  final Dio dio;
  final McqOptionsConfig mcqConfig = McqOptionsConfig();

  DynamicLessonQuestionGenerator({Dio? dio}) : dio = dio ?? Dio();

  Future<void> fetchMcqOptionsByType() async {
    // stub - no-op
  }

  int getMcqOptionsForType(String type) {
    return 5;
  }

  Future<LessonQuestion> generateQuestionWithDynamicOptions({
    required String questionText,
    required String questionType,
    int? customOptionsCount,
    required String sourceMaterial,
  }) async {
    final count = customOptionsCount ?? 5;
    final adjusted = mcqConfig.adjustOptions(count);
    final opts = List<String>.generate(adjusted, (i) => 'Option ${i + 1}');
    return LessonQuestion(
      questionText: questionText,
      questionType: questionType,
      options: opts,
      sourceMaterial: sourceMaterial,
    );
  }

  Future<String> generateOption(int index, String question) async {
    return 'Option $index';
  }

  Future<LessonQuestion> generateQuestionFromApi({
    required String questionText,
    required String questionType,
    int? customOptionsCount,
  }) async {
    throw Exception('API error');
  }

  LessonQuestion getQuestion() {
    return LessonQuestion(
      questionType: 'input',
      questionText: 'Test question',
    );
  }
}

class DynamicLessonQuestionPrompts {
  static String generateMcqPrompt({
    required DynamicQuestionType questionType,
    String? sourceMaterial,
  }) {
    final buffer = StringBuffer('Generate a $questionType question');
    if (sourceMaterial != null) {
      buffer.write(' about $sourceMaterial');
    }
    return buffer.toString();
  }

  static String generateInputPrompt(String content) {
    return 'Generate input question about $content';
  }
}
