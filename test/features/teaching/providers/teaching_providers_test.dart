import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/teaching/providers/teaching_providers.dart';
import 'package:studyking/features/teaching/services/prompts/prompts.dart';
import 'package:studyking/features/teaching/services/tutor_service.dart';
import 'package:studyking/features/teaching/services/exercise_evaluator.dart';
import 'package:studyking/features/teaching/services/voice_controller.dart';
import 'package:studyking/core/utils/clock.dart';

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
  });

  group('clockProvider', () {
    test('creates a SystemClock', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final clock = container.read(clockProvider);
      expect(clock, isA<SystemClock>());
    });

    test('can be overridden', () {
      final fakeClock = SystemClock();
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(fakeClock),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(clockProvider), same(fakeClock));
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
  });

  group('promptsProvider', () {
    test('returns a ConversationPromptSet', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final prompts = container.read(promptsProvider);
      expect(prompts, isA<ConversationPromptSet>());
    });

    test('can be overridden', () {
      final fakePrompts = const ConversationPromptSet();
      final container = ProviderContainer(
        overrides: [
          promptsProvider.overrideWithValue(fakePrompts),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(promptsProvider), same(fakePrompts));
    });
  });
}
