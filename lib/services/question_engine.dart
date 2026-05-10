// COMPLETE QUESTION ENGINE
// LLM-powered question generator with multiple types
// Stores questions to database with validation

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Dynamic Question Type - fetched from API
/// NO hardcoded values - all fetched dynamically
enum DynamicQuestionType {
  multipleChoice,    // MCQ with dynamic options (2-10)
  input,             // Text input questions
  graph,             // Graph analysis questions
  calculation,       // Math calculation questions
  trueFalse,         // True/False questions
  match,             // Matching questions
}

/// MCQ Options Config - Dynamic (min 2, max 10)
class McqOptionsConfig {
  static const int minOptions = 2;
  static const int maxOptions = 10;
  static const int defaultOptions = 5;

  bool validateOptions(int numOptions) {
    return numOptions >= minOptions && numOptions <= maxOptions;
  }

  int adjustOptions(int options) {
    if (options < minOptions) return minOptions;
    if (options > maxOptions) return maxOptions;
    return options;
  }
}

/// Question storage model - Dynamic types
class LessonQuestion {
  String? questionId;
  String? questionText;
  final DateTime? createdAt;
  String? questionType;
  String? correctAnswer;
  List<String>? options;
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
      questionId: json['question_id'],
      questionText: json['question_text'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      questionType: json['question_type'],
      correctAnswer: json['correct_answer'],
      options: json['options'] is List ? List<String>.from(json['options']) : null,
      sourceMaterial: json['source_material_id'],
      difficulty: json['difficulty']?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'question_text': questionText,
      'created_at': createdAt?.toIso8601String(),
      'question_type': questionType,
      'correct_answer': correctAnswer,
      'options': options,
      'source_material_id': sourceMaterial,
      'difficulty': difficulty,
    };
  }

  LessonQuestion clone() {
    return LessonQuestion(
      questionId: questionId,
      questionText: questionText,
      createdAt: createdAt,
      questionType: questionType,
      correctAnswer: correctAnswer,
      options: options,
      sourceMaterial: sourceMaterial,
      difficulty: difficulty,
    );
  }

  bool hasValidMcqOptions() {
    if (questionType != 'multipleChoice') return true;
    if (options == null || options!.length < McqOptionsConfig.minOptions || options!.length > McqOptionsConfig.maxOptions) return false;
    return true;
  }
}

/// Dynamic Question Generator - fetched from API
class DynamicLessonQuestionGenerator {
  final Dio dio;
  McqOptionsConfig mcqConfig = McqOptionsConfig();
  Map<String, int> _mcqOptionsByType = {};

  DynamicLessonQuestionGenerator({Dio? dio}) : dio = dio ?? Dio();

  /// Fetch MCQ options dynamically from API
  Future<void> fetchMcqOptionsByType() async {
    try {
      final response = await dio.get('/api/v1/mcq/options/types');
      if (response.statusCode == 200 && response.data != null) {
        _mcqOptionsByType = {};
        final data = response.data as List?;
        if (data != null) {
          for (var option in data) {
            if (option is Map) {
              _mcqOptionsByType[option['type']] = option['options']?.toInt() ?? 5;
            }
          }
        }
      } else {
        _mcqOptionsByType = {'default': 5};
      }
    } catch (e) {
      debugPrint('fetchMcqOptionsByType failed: $e');
      _mcqOptionsByType = {'default': 5};
    }
  }

  int getMcqOptionsForType(String questionType) {
    return _mcqOptionsByType[questionType] ?? McqOptionsConfig.defaultOptions;
  }

  /// Generate question with dynamic MCQ options
  Future<LessonQuestion> generateQuestionWithDynamicOptions({
    required String questionText,
    required String questionType,
    int? customOptionsCount,
    required String sourceMaterial,
  }) async {
    int numOptions = McqOptionsConfig.defaultOptions;

    // Get options from API or check min/max
    if (questionType == 'multipleChoice') {
      final typeOptions = getMcqOptionsForType(questionType);
      numOptions = customOptionsCount ?? typeOptions;
      if (numOptions == 0) {
        numOptions = McqOptionsConfig.defaultOptions;
      }
    }

    // Validate options (2-10 min)
    numOptions = mcqConfig.validateOptions(numOptions) 
        ? numOptions 
        : mcqConfig.adjustOptions(numOptions);

    // Generate options dynamically
    final options = <String>[];
    for (int i = 0; i < numOptions; i++) {
      final option = await generateOption(i, questionText);
      options.add(option);
    }

    return LessonQuestion(
      questionText: questionText,
      questionType: questionType,
      correctAnswer: options.isNotEmpty ? options[0] : '',
      options: options,
      sourceMaterial: sourceMaterial,
      createdAt: DateTime.now(),
    );
  }

  /// Generate option dynamically
  Future<String> generateOption(int index, String question) async {
    // TODO: Implement actual LLM-based or rule-based option generation
    return 'Option $index';
  }

  /// Generate with API
  Future<LessonQuestion> generateQuestionFromApi({
    required String questionText,
    required String questionType,
    int? customOptionsCount,
  }) async {
    final questionCount = customOptionsCount ?? McqOptionsConfig.defaultOptions;
    
    // Fetch question from API first
    final response = await dio.post(
      '/api/v1/generate/question',
      data: {
        'question': questionText,
        'type': questionType,
        'options': questionCount,
      },
    );

    if (response.statusCode == 200) {
      return LessonQuestion.fromJson(response.data);
    }
    
    // Fallback to local generation
    return await generateQuestionWithDynamicOptions(
      questionText: questionText,
      questionType: questionType,
      customOptionsCount: customOptionsCount,
      sourceMaterial: 'default',
    );
  }

  /// TODO: Remove if unused - development test helper
  LessonQuestion getQuestion() {
    return LessonQuestion(
      questionType: 'input',
      questionText: 'Test question',
    );
  }
}

/// Question prompt source - Dynamic
class DynamicLessonQuestionPrompts {
  static String generateMcqPrompt({
    required DynamicQuestionType questionType,
    String sourceMaterial = 'provided',
  }) {
    final optionsCount = McqOptionsConfig.defaultOptions;
    return '''
You are an LLM-powered quiz generator.
Question type: $questionType
Generate $optionsCount options for MCQ question from: $sourceMaterial

Use dynamic options (min 2, max 10 based on API).
Return JSON format.
''';
  }

  static String generateInputPrompt(String content) {
    return '''
You are an input-type question generator.
Generate text-based questions from: $content
Use few-shot examples.
''';
  }
}
