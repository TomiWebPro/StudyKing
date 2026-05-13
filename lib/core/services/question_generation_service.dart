import 'dart:convert';
import '../utils/logger.dart';
import '../../core/data/models/question_model.dart';
import '../data/models/markscheme_model.dart';
import '../../core/data/repositories/question_repository.dart';
import '../../core/services/mastery_graph_service.dart';
import '../../core/data/enums.dart';
import '../services/llm_service.dart';

class QuestionGenerationService {
  final Logger _logger = const Logger('QuestionGenerationService');
  final QuestionRepository _questionRepo;
  final MasteryGraphService _masteryService;
  final LlmService _llmService;

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  QuestionGenerationService({
    QuestionRepository? questionRepo,
    MasteryGraphService? masteryService,
    required LlmService llmService,
  })  : _questionRepo = questionRepo ?? QuestionRepository(),
        _masteryService = masteryService ?? MasteryGraphService(),
        _llmService = llmService;

  Future<GenerationResult> generateQuestions({
    required String topicId,
    required String subjectId,
    required int count,
    int difficulty = 1,
    String? focusOnWeakAreas,
  }) async {
    try {
      final questions = <Question>[];

      for (int i = 0; i < count; i++) {
        final result = await _generateSingleQuestion(
          topicId: topicId,
          subjectId: subjectId,
          difficulty: difficulty,
          questionIndex: i + 1,
          totalQuestions: count,
          focusOnWeakAreas: focusOnWeakAreas,
        );

        if (result.isSuccess && result.data != null) {
          final saveResult = await _questionRepo.create(result.data!);
          if (saveResult.isSuccess) {
            questions.add(result.data!);
          }
        }
      }

      if (questions.isEmpty && count > 0) {
        return GenerationResult.failure('Failed to generate any questions');
      }
      return GenerationResult.success(questions);
    } catch (e) {
      _logger.e('Error generating questions', e);
      return GenerationResult.failure('Failed to generate questions: $e');
    }
  }

  Future<GenerationResult<Question>> _generateSingleQuestion({
    required String topicId,
    required String subjectId,
    required int difficulty,
    required int questionIndex,
    required int totalQuestions,
    String? focusOnWeakAreas,
  }) async {
    String? lastError;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final question = await _callLlmAPI(
          topicId: topicId,
          subjectId: subjectId,
          difficulty: difficulty,
          questionIndex: questionIndex,
          totalQuestions: totalQuestions,
          focusOnWeakAreas: focusOnWeakAreas,
        );
        return GenerationResult.success(question);
      } catch (e) {
        lastError = e.toString();
        _logger.w('Attempt ${attempt + 1} failed: $e');

        if (attempt < maxRetries - 1) {
          await Future.delayed(retryDelay * (attempt + 1));
        }
      }
    }

    return GenerationResult.failure('Failed after $maxRetries attempts: $lastError');
  }

  Future<Question> _callLlmAPI({
    required String topicId,
    required String subjectId,
    required int difficulty,
    required int questionIndex,
    required int totalQuestions,
    String? focusOnWeakAreas,
  }) async {
    final model = _getModelForDifficulty(difficulty);
    final difficultyLabel = _getDifficultyLabel(difficulty);

    String prompt = _buildQuestionPrompt(
      topicId: topicId,
      subjectId: subjectId,
      difficultyLabel: difficultyLabel,
      difficulty: difficulty,
      questionIndex: questionIndex,
      totalQuestions: totalQuestions,
      focusOnWeakAreas: focusOnWeakAreas,
    );

    final response = await _llmService.chat(
      message: prompt,
      modelId: model,
      systemPrompt: _systemPrompt,
    );

    if (response.isEmpty) {
      throw GenerationException('Empty response from LLM API');
    }

    return _parseQuestionResponse(
      response,
      topicId: topicId,
      subjectId: subjectId,
      difficulty: difficulty,
      model: model,
    );
  }

  String _getModelForDifficulty(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'google/gemini-2.5-flash-preview-05-20';
      case 2:
        return 'anthropic/claude-3.5-haiku';
      case 3:
        return 'anthropic/claude-3.5-sonnet';
      default:
        return 'google/gemini-2.5-flash-preview-05-20';
    }
  }

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'easy';
      case 2:
        return 'medium';
      case 3:
        return 'hard';
      default:
        return 'medium';
    }
  }

  String get _systemPrompt => '''You are an expert question generator for educational content. 
Generate well-crafted questions following strict JSON format. Return ONLY valid JSON without any markdown or additional text.
Questions should be educational, clear, and have precise answers.''';

  String _buildQuestionPrompt({
    required String topicId,
    required String subjectId,
    required String difficultyLabel,
    required int difficulty,
    required int questionIndex,
    required int totalQuestions,
    String? focusOnWeakAreas,
  }) {
    final weakAreasContext = focusOnWeakAreas != null
        ? ' Focus on: $focusOnWeakAreas'
        : '';

    return '''Generate question $questionIndex of $totalQuestions for topic: $topicId, subject: $subjectId.
Difficulty: $difficultyLabel$weakAreasContext

Return JSON in this exact format:
{
  "text": "The question text",
  "type": "singleChoice|multiChoice|typedAnswer|mathExpression",
  "difficulty": $difficulty,
  "options": ["Option A", "Option B", "Option C", "Option D"],
  "markscheme": {
    "questionId": "generate-a-uuid",
    "correctAnswer": "The correct answer",
    "acceptableAnswers": ["alternative1", "alternative2"],
    "explanation": "Why this is correct",
    "steps": []
  },
  "tags": ["tag1", "tag2"],
  "explanation": "Brief explanation for learning"
}

For singleChoice/multiChoice: include 4 options.
For typedAnswer: leave options empty.
For mathExpression: include the equation in the question text.
For stepByStep: include steps in the markscheme.

Return ONLY the JSON object, no markdown formatting.''';
  }

  Question _parseQuestionResponse(
    String content, {
    required String topicId,
    required String subjectId,
    required int difficulty,
    required String model,
  }) {
    try {
      String jsonStr = content.trim();
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      }
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      final questionId = json['markscheme']?['questionId'] ?? 
          '${topicId}_${DateTime.now().millisecondsSinceEpoch}';

      Markscheme? markscheme;
      final markschemeData = json['markscheme'];
      if (markschemeData != null) {
        markscheme = Markscheme.fromJson({
          'questionId': questionId,
          'correctAnswer': markschemeData['correctAnswer'] ?? '',
          'acceptableAnswers': markschemeData['acceptableAnswers'] ?? [],
          'explanation': markschemeData['explanation'],
          'markschemePoints': markschemeData['markschemePoints'],
          'steps': (markschemeData['steps'] as List? ?? []).map((s) {
            if (s is String) {
              return MarkSchemeStep(
                stepNumber: '${markschemeData['steps'].indexOf(s) + 1}',
                requiredAnswer: s,
                points: 1.0,
              );
            }
            return MarkSchemeStep.fromJson(s);
          }).toList(),
        });
      }

      final questionType = _parseQuestionType(json['type'] ?? 'singleChoice');

      return Question(
        id: questionId,
        text: json['text'] ?? 'Generated question',
        type: questionType,
        difficulty: difficulty,
        subjectId: subjectId,
        topicId: topicId,
        options: List<String>.from(json['options'] ?? []),
        markscheme: markscheme,
        model: model,
        tags: List<String>.from(json['tags'] ?? []),
        explanation: json['explanation'],
        difficultyText: _getDifficultyLabel(difficulty),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.e('Error parsing question response', e);
      throw GenerationException('Failed to parse question: $e');
    }
  }

  QuestionType _parseQuestionType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'singlechoice':
      case 'single_choice':
        return QuestionType.singleChoice;
      case 'multichoice':
      case 'multi_choice':
        return QuestionType.multiChoice;
      case 'typedanswer':
      case 'typed_answer':
        return QuestionType.typedAnswer;
      case 'mathexpression':
      case 'math_expression':
        return QuestionType.mathExpression;
      case 'essay':
        return QuestionType.essay;
      case 'stepbystep':
      case 'step_by_step':
        return QuestionType.stepByStep;
      case 'canvas':
        return QuestionType.canvas;
      case 'graphdrawing':
      case 'graph_drawing':
        return QuestionType.graphDrawing;
      default:
        return QuestionType.singleChoice;
    }
  }

  Future<GenerationResult<List<Question>>> generateForWeakTopics({
    required String studentId,
    required String subjectId,
    int questionsPerTopic = 5,
  }) async {
    try {
      final weakTopicsResult = await _masteryService.getWeakTopics(studentId);

      if (weakTopicsResult.isFailure) {
        return GenerationResult.failure(weakTopicsResult.error ?? 'Failed to get weak topics');
      }

      final weakTopics = weakTopicsResult.data!;
      final questions = <Question>[];

      for (final topic in weakTopics) {
        final result = await generateQuestions(
          topicId: topic.topicId,
          subjectId: subjectId,
          count: questionsPerTopic,
          difficulty: _estimateDifficultyFromMastery(topic),
          focusOnWeakAreas: topic.weakSubtopics.isNotEmpty
              ? topic.weakSubtopics.join(', ')
              : null,
        );

        if (result.isSuccess && result.data != null) {
          questions.addAll(result.data!);
        }
      }

      return GenerationResult.success(questions);
    } catch (e) {
      return GenerationResult.failure('Failed to generate for weak topics: $e');
    }
  }

  int _estimateDifficultyFromMastery(dynamic topicMastery) {
    final accuracy = topicMastery.accuracy ?? 0.0;
    if (accuracy >= 0.8) return 3;
    if (accuracy >= 0.5) return 2;
    return 1;
  }
}

class GenerationResult<T> {
  final T? data;
  final String? error;
  final int? statusCode;

  const GenerationResult._({this.data, this.error, this.statusCode});

  factory GenerationResult.success(T data) => GenerationResult._(data: data);

  factory GenerationResult.failure(String error, {int? statusCode}) =>
      GenerationResult._(error: error, statusCode: statusCode);

  bool get isSuccess => error == null && data != null;
  bool get isFailure => error != null;
}

class GenerationException implements Exception {
  final String message;
  final int? statusCode;

  GenerationException(this.message, {this.statusCode});

  @override
  String toString() => 'GenerationException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
