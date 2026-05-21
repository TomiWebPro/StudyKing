import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/teaching/services/exercise_evaluator.dart';

class FakeLlmForEvaluator extends LlmService {
  String responseJson;
  bool shouldFail = false;

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
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    if (shouldFail) return Result.failure('LLM failure');
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
        localeName: 'en',
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

    test('returns fallback when LLM returns failure', () async {
      llmService.responseJson = '';
      llmService.shouldFail = true;

      final result = await evaluator.evaluate(
        question: 'Question?',
        studentAnswer: 'Answer.',
        subjectId: 'science',
        topicTitle: 'Topic',
      );

      expect(result.score, equals(0.5));
      expect(result.explanation, isNotEmpty);
    });

    test('handles malformed JSON with missing required fields', () async {
      llmService.responseJson = '{"score": 0.8}';

      final result = await evaluator.evaluate(
        question: 'Question?',
        studentAnswer: 'Answer.',
        subjectId: 'science',
        topicTitle: 'Topic',
      );

      expect(result.score, equals(0.8));
    });

    group('error-state: edge responses', () {
      test('handles score at 0.0 boundary', () async {
        llmService.responseJson =
            '{"score": 0.0, "explanation": "Completely wrong."}';

        final result = await evaluator.evaluate(
          question: 'Question?',
          studentAnswer: 'Wrong answer.',
          subjectId: 'science',
          topicTitle: 'Topic',
        );

        expect(result.score, equals(0.0));
      });

      test('handles score at 1.0 boundary', () async {
        llmService.responseJson =
            '{"score": 1.0, "explanation": "Perfect answer!"}';

        final result = await evaluator.evaluate(
          question: 'Question?',
          studentAnswer: 'Correct answer.',
          subjectId: 'science',
          topicTitle: 'Topic',
        );

        expect(result.score, equals(1.0));
      });

      test('handles extra unknown fields in JSON', () async {
        llmService.responseJson =
            '{"score": 0.7, "explanation": "Good.", "unknownField": "value", "extraNested": {"a": 1}}';

        final result = await evaluator.evaluate(
          question: 'Question?',
          studentAnswer: 'Answer.',
          subjectId: 'science',
          topicTitle: 'Topic',
        );

        expect(result.score, equals(0.7));
        expect(result.explanation, equals('Good.'));
      });

      test('handles explanation with special characters', () async {
        llmService.responseJson =
            '{"score": 0.5, "explanation": "Line1\\nLine2\\tTabbed\\"Quoted\\"\\u00e9"}';

        final result = await evaluator.evaluate(
          question: 'Question?',
          studentAnswer: 'Answer.',
          subjectId: 'science',
          topicTitle: 'Topic',
        );

        expect(result.score, equals(0.5));
        expect(result.explanation, isNotEmpty);
      });
    });
  });
}
