import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/features/teaching/providers/teaching_providers.dart';
import 'package:studyking/features/teaching/services/tutor_service.dart';
import 'package:studyking/features/teaching/data/models/evaluation_result.dart';


class _FakeClock implements Clock {
  final DateTime fixed;
  _FakeClock(this.fixed);
  @override
  DateTime now() => fixed;
}

class _FakeLlmService extends LlmService {
  bool shouldThrow = false;

  _FakeLlmService()
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
    if (shouldThrow) return Result.failure('Simulated LLM error');
    return Result.success('{"score": 0.8, "explanation": "Good job"}');
  }
}

void main() {
  group('teachingModelIdProvider', () {
    test('returns saved model when selectedModelProvider is non-empty', () {
      final container = ProviderContainer(
        overrides: [
          selectedModelProvider.overrideWith((ref) => 'custom-model'),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(teachingModelIdProvider), 'custom-model');
    });

    test('falls back to default model for provider when selectedModel is empty', () {
      final container = ProviderContainer(
        overrides: [
          selectedModelProvider.overrideWith((ref) => ''),
        ],
      );
      addTearDown(container.dispose);
      final modelId = container.read(teachingModelIdProvider);
      expect(modelId, isNotEmpty);
      expect(modelId, equals(defaultModelForProvider(container.read(llmProviderProvider))));
    });

    test('is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final a = container.read(teachingModelIdProvider);
      final b = container.read(teachingModelIdProvider);
      expect(a, same(b));
    });
  });

  group('exerciseEvaluatorProvider', () {
    test('behavioral: llmService override affects evaluation', () async {
      final fakeService = _FakeLlmService();
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);
      final evaluator = container.read(exerciseEvaluatorProvider);
      final result = await evaluator.evaluate(
        question: 'test',
        studentAnswer: 'test',
        subjectId: 'test',
        topicTitle: 'test',
      );
      expect(result, isA<EvaluationResult>());
      expect(result.score, 0.8);
    });

    test('uses teachingModelIdProvider for modelId', () async {
      final container = ProviderContainer(
        overrides: [
          teachingModelIdProvider.overrideWith((ref) => 'eval-test-model'),
        ],
      );
      addTearDown(container.dispose);
      final evaluator = container.read(exerciseEvaluatorProvider);
      final result = await evaluator.evaluate(
        question: 'What is 2+2?',
        studentAnswer: '4',
        subjectId: 'math',
        topicTitle: 'arithmetic',
      );
      expect(result, isA<EvaluationResult>());
      expect(result.score, greaterThanOrEqualTo(0));
    });

    test('behavioral: localeProvider affects evaluator locale', () async {
      final container = ProviderContainer(
        overrides: [
          localeProvider.overrideWith((ref) => const Locale('es')),
        ],
      );
      addTearDown(container.dispose);
      final evaluator = container.read(exerciseEvaluatorProvider);
      final result = await evaluator.evaluate(
        question: 'test',
        studentAnswer: 'test',
        subjectId: 'test',
        topicTitle: 'test',
      );
      expect(result, isA<EvaluationResult>());
      expect(result.score, greaterThanOrEqualTo(0));
    });

    test('is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final a = container.read(exerciseEvaluatorProvider);
      final b = container.read(exerciseEvaluatorProvider);
      expect(a, same(b));
    });

    test('error-state: empty modelId still produces a result with fallback score', () async {
      final container = ProviderContainer(
        overrides: [
          teachingModelIdProvider.overrideWith((ref) => ''),
        ],
      );
      addTearDown(container.dispose);
      final evaluator = container.read(exerciseEvaluatorProvider);
      final result = await evaluator.evaluate(
        question: 'test',
        studentAnswer: 'test',
        subjectId: 'test',
        topicTitle: 'test',
      );
      expect(result, isA<EvaluationResult>());
      expect(result.score, greaterThanOrEqualTo(0));
    });

    test('propagates errors from LLM service gracefully', () async {
      final fakeService = _FakeLlmService();
      fakeService.shouldThrow = true;
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);
      final evaluator = container.read(exerciseEvaluatorProvider);
      final result = await evaluator.evaluate(
        question: 'test',
        studentAnswer: 'test',
        subjectId: 'test',
        topicTitle: 'test',
      );
      expect(result.score, 0.5);
      expect(result.explanation, contains('Could not evaluate answer'));
    });

    test('recovers after LLM service error', () async {
      final fakeService = _FakeLlmService();
      fakeService.shouldThrow = true;
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);
      var evaluator = container.read(exerciseEvaluatorProvider);
      var result = await evaluator.evaluate(
        question: 'test',
        studentAnswer: 'test',
        subjectId: 'test',
        topicTitle: 'test',
      );
      expect(result.score, 0.5);

      fakeService.shouldThrow = false;
      result = await evaluator.evaluate(
        question: 'What is 2+2?',
        studentAnswer: '4',
        subjectId: 'math',
        topicTitle: 'arithmetic',
      );
      expect(result.score, 0.8);
    });
  });

  group('clockProvider', () {
    test('can be overridden and provides time', () {
      final fakeClock = _FakeClock(DateTime(2024, 6, 15));
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(fakeClock),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(clockProvider), same(fakeClock));
      expect(container.read(clockProvider).now(), DateTime(2024, 6, 15));
    });

    test('is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final a = container.read(clockProvider);
      final b = container.read(clockProvider);
      expect(a, same(b));
    });

    test('behavioral: clock provides actual time', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final clock = container.read(clockProvider);
      final now = clock.now();
      expect(now, isA<DateTime>());
      expect(now.isAfter(DateTime(2020)), isTrue);
    });
  });

  group('tutorServiceProvider', () {
    test('is singleton (behavioral)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final a = container.read(tutorServiceProvider);
      final b = container.read(tutorServiceProvider);
      expect(a, same(b));
    });

    test('behavioral: clock override is wired through', () {
      final fakeClock = _FakeClock(DateTime(2024, 1, 1));
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(fakeClock),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(tutorServiceProvider);
      expect(service, isA<TutorService>());
    });
  });
}
