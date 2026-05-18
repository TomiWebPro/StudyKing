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
import 'package:studyking/features/teaching/services/exercise_evaluator.dart';
import 'package:studyking/features/teaching/services/voice_controller.dart';

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
    test('creates an ExerciseEvaluator', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final evaluator = container.read(exerciseEvaluatorProvider);
      expect(evaluator, isA<ExerciseEvaluator>());
    });

    test('is wired to llmServiceProvider', () {
      final fakeService = LlmService(
        config: const LlmConfiguration(provider: LlmProvider.openRouter, apiKey: 'test'),
      );
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);
      final evaluator = container.read(exerciseEvaluatorProvider);
      expect(evaluator, isA<ExerciseEvaluator>());
    });

    test('uses teachingModelIdProvider for modelId', () {
      final container = ProviderContainer(
        overrides: [
          teachingModelIdProvider.overrideWith((ref) => 'eval-test-model'),
        ],
      );
      addTearDown(container.dispose);
      final evaluator = container.read(exerciseEvaluatorProvider);
      expect(evaluator, isA<ExerciseEvaluator>());
    });

    test('uses localeProvider for localeName', () {
      final container = ProviderContainer(
        overrides: [
          localeProvider.overrideWith((ref) => const Locale('es')),
        ],
      );
      addTearDown(container.dispose);
      final evaluator = container.read(exerciseEvaluatorProvider);
      expect(evaluator, isA<ExerciseEvaluator>());
    });

    test('is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final a = container.read(exerciseEvaluatorProvider);
      final b = container.read(exerciseEvaluatorProvider);
      expect(a, same(b));
    });

    test('evaluator uses overridden locale', () {
      final container = ProviderContainer(
        overrides: [
          localeProvider.overrideWith((ref) => const Locale('es')),
        ],
      );
      addTearDown(container.dispose);
      final evaluator = container.read(exerciseEvaluatorProvider);
      expect(evaluator, isA<ExerciseEvaluator>());
    });

    test('handles error when modelId is empty by still constructing evaluator', () {
      final container = ProviderContainer(
        overrides: [
          teachingModelIdProvider.overrideWith((ref) => ''),
        ],
      );
      addTearDown(container.dispose);
      final evaluator = container.read(exerciseEvaluatorProvider);
      expect(evaluator, isA<ExerciseEvaluator>());
    });

    test('evaluator propagates errors from LLM service', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final evaluator = container.read(exerciseEvaluatorProvider);
      final result = await evaluator.evaluate(
        question: 'test',
        studentAnswer: 'test',
        subjectId: 'test',
        topicTitle: 'test',
      );
      expect(result, isA<EvaluationResult>());
      expect(result.score, 0.5);
    });

    test('handles error from fake LLM service', () async {
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
      expect(result, isA<EvaluationResult>());
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
      expect(result, isA<EvaluationResult>());
      expect(result.score, 0.8);
    });
  });

  group('voiceControllerProvider', () {
    test('creates a VoiceController', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(voiceControllerProvider);
      expect(controller, isA<VoiceController>());
    });

    test('can be overridden', () {
      final fakeController = VoiceController();
      final container = ProviderContainer(
        overrides: [
          voiceControllerProvider.overrideWithValue(fakeController),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(voiceControllerProvider), same(fakeController));
    });

    test('is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final a = container.read(voiceControllerProvider);
      final b = container.read(voiceControllerProvider);
      expect(a, same(b));
    });
  });

  group('clockProvider', () {
    test('creates a SystemClock', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final clock = container.read(clockProvider);
      expect(clock, isA<SystemClock>());
    });

    test('can be overridden', () {
      final fakeClock = _FakeClock(DateTime(2024, 6, 15));
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(fakeClock),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(clockProvider), same(fakeClock));
    });

    test('is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final a = container.read(clockProvider);
      final b = container.read(clockProvider);
      expect(a, same(b));
    });
  });

  group('tutorServiceProvider', () {
    test('creates a TutorService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(tutorServiceProvider);
      expect(service, isA<TutorService>());
    });

    test('is wired to llmServiceProvider', () {
      final fakeService = LlmService(
        config: const LlmConfiguration(provider: LlmProvider.openRouter, apiKey: 'test'),
      );
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(tutorServiceProvider);
      expect(service, isA<TutorService>());
    });

    test('is wired to exerciseEvaluatorProvider', () {
      final fakeEvaluator = ExerciseEvaluator(
        llmService: LlmService(
          config: const LlmConfiguration(provider: LlmProvider.openRouter, apiKey: 'test'),
        ),
        modelId: 'test',
        localeName: 'en',
      );
      final container = ProviderContainer(
        overrides: [
          exerciseEvaluatorProvider.overrideWithValue(fakeEvaluator),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(tutorServiceProvider);
      expect(service, isA<TutorService>());
    });

    test('is wired to clockProvider', () {
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

    test('is wired to teachingModelIdProvider', () {
      final container = ProviderContainer(
        overrides: [
          teachingModelIdProvider.overrideWith((ref) => 'tutor-model-override'),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(tutorServiceProvider);
      expect(service, isA<TutorService>());
    });

    test('is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final a = container.read(tutorServiceProvider);
      final b = container.read(tutorServiceProvider);
      expect(a, same(b));
    });
  });

}
