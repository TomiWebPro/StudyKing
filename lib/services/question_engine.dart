// COMPLETE QUESTION ENGINE
// LLM-powered question generator with multiple types
// Stores questions to database with validation

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Question type enum
enum QuestionType {
  multipleChoice,  // MCQ with options A, B, C, D
  input,           // Text input questions
  graph,           // Graph analysis questions
  calculation,     // Math calculation questions
  trueFalse,       // True/False questions
  match,           // Matching questions
}

/// Question storage model
class LessonQuestion extends ChangeNotifier {
  String? questionId;
  String? questionText;
  final Date? createdAt;
  final String questionType;
  String? correctAnswer;
  List<String>? options;
  final String? sourceMaterial;
  final int? difficulty;

  LessonQuestion({
    this.questionId,
    this.questionText,
    this.createdAt,
    required this.questionType,
    this.correctAnswer,
    this.options,
    this.sourceMaterial,
    this.difficulty,
  });

  factory LessonQuestion.fromJson(String questionModel, String sourceMaterial) {
    return LessonQuestion(
      questionId: questionModel.question_id,
      questionType: questionModel.question_type,
      sourceMaterial: sourceMaterial,
      difficulty: questionModel.difficulty,
      correctAnswer: questionModel.knowledge,
      options: questionModel.hasCorrect ? questionModel.options : null,
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
}

/// Question generating command
class LessonQuestionGenerator {
  final LessonQuestion _lessonQuestion = LessonQuestion(
    questionType: QuestionType.input,
    questionText: 'What is the capital of France?',
  );

  LessonQuestion get lessonQuestion => _lessonQuestion;

  void setUp(LessonQuestion lessonQuestion) {
    _lessonQuestion = lessonQuestion;
    _lessonQuestion.notifyListeners();
  }

  void setQuestionText(String questionText) {
    _lessonQuestion.questionText = questionText;
    _lessonQuestion.notifyListeners();
  }

  void setQuestionType(String questionType) {
    _lessonQuestion.questionType = questionType;
    _lessonQuestion.notifyListeners();
  }

  String getQuestionText() => _lessonQuestion.questionText;
  String getQuestionType => _lessonQuestion.questionType;
  LessonQuestion getQuestion => _lessonQuestion;
}

/// Question prompt source
class LessonQuestionPrompts {
  static const String mcqPrompt = '''
You are an LLM-powered quiz generator. Create multiple choice questions (MCQ).
Question type: $questionType
Topic: $topic
Source material: $content
Format: JSON with options A, B, C, D
''';

  static const String inputPrompt = '''
You are an input-type question generator.
Generate text-based questions with expected answers.
Use examples as few-shot.
''';

  static const String graphPrompt = '''
You are graph analysis generator.
Create graph interpretation questions.
Include instructions for reading graph data.
'''
}

/// Generate question from story/lesson
Future<String> generateQuestionFromStory({
  required String storyContent,
  required String topic,
  required QuestionType questionType,
  int questionCount = 5,
}) async {
  try {
    final dio = Dio();
    final response = await dio.post(
      'https://api.openrouter.ai/v1/chat/completions',
      data: {
        'model': 'openai/gpt-4o',
        'messages': [
          {'role': 'system', 'content': 'Generate questions from study material.'},
          {'role': 'user', 'content': storyContent},
        ],
        'temperature': 0.7,
      },
    );
    return response.data;
  } catch (e) {
    print('Error generating question: $e');
    return '';
  }
}

/// Validate question response
class LessonQuestionValidation {
  static bool validateMultipleChoice(Map<String, dynamic> question) {
    return question.containsKey('options') && question.containsKey('answer');
  }

  static bool validateInput(Map<String, dynamic> question) {
    return question.containsKey('question') && question.containsKey('expected_answer');
  }

  static bool validateGraph(Map<String, dynamic> question) {
    return question.containsKey('graph_instruction') ||
           question.containsKey('plot_type');
  }
}
