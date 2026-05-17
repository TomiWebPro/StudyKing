import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/teaching/services/exercise_evaluator.dart';

class FakeLlmForEvaluator extends LlmService {
  String responseJson;

  FakeLlmForEvaluator({this.responseJson = ''})
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'test-key',
          ),
        );

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    return Result.success(responseJson);
  }
}

void main() {
  group('ExerciseEvaluator', () {
    late FakeLlmForEvaluator llmService;
    late ExerciseEvaluator evaluator;

    setUp(() {
      llmService = FakeLlmForEvaluator();
      evaluator = ExerciseEvaluator(
        llmService: llmService,
        modelId: 'test-model',
      );
    });

    test('evaluate returns EvaluationResult from LLM response', () async {
      llmService.responseJson =
          '{"score": 0.9, "explanation": "Excellent work!", "partialCredit": 0.0, "conceptBreakdown": {"Concept1": 0.9, "Concept2": 0.8}}';

      final result = await evaluator.evaluate(
        question: 'What is 2+2?',
        studentAnswer: '4',
        subjectId: 'math',
        topicTitle: 'Addition',
      );

      expect(result.score, equals(0.9));
      expect(result.explanation, contains('Excellent'));
      expect(result.partialCredit, equals(0.0));
      expect(result.conceptBreakdown, isNotNull);
    });

    test('evaluate handles LLM returning non-JSON gracefully', () async {
      llmService.responseJson = 'The answer looks correct overall.';

      final result = await evaluator.evaluate(
        question: 'Explain photosynthesis',
        studentAnswer: 'Plants use sunlight',
        subjectId: 'biology',
        topicTitle: 'Photosynthesis',
      );

      expect(result.score, equals(0.5));
      expect(result.explanation, isNotEmpty);
    });

    test('evaluate handles empty LLM response', () async {
      llmService.responseJson = '';

      final result = await evaluator.evaluate(
        question: 'Question?',
        studentAnswer: 'Answer.',
        subjectId: 'science',
        topicTitle: 'Topic',
      );

      expect(result.score, equals(0.5));
    });

    test('evaluate handles low score', () async {
      llmService.responseJson =
          '{"score": 0.2, "explanation": "Incorrect answer."}';

      final result = await evaluator.evaluate(
        question: 'What is the capital?',
        studentAnswer: 'London',
        subjectId: 'geography',
        topicTitle: 'Capitals',
      );

      expect(result.score, equals(0.2));
    });

    test('accepts custom prompts', () async {
      llmService.responseJson = '{"score": 1.0, "explanation": "Perfect."}';

      final result = await evaluator.evaluate(
        question: 'Test',
        studentAnswer: 'Answer',
        subjectId: 'math',
        topicTitle: 'Test',
        systemPrompt: 'Custom system prompt',
        userPrompt: 'Custom user prompt',
      );

      expect(result.score, equals(1.0));
    });
  });
}
