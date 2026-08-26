import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm/model_router.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';

void main() {
  group('TaskModelConfig', () {
    test('defaults are all empty with local background disabled', () {
      const config = TaskModelConfig();
      expect(config.tutorModelId, isEmpty);
      expect(config.mentorModelId, isEmpty);
      expect(config.classificationModelId, isEmpty);
      expect(config.generationModelId, isEmpty);
      expect(config.summarizationModelId, isEmpty);
      expect(config.evaluationModelId, isEmpty);
      expect(config.transcriptionModelId, isEmpty);
      expect(config.useLocalForBackground, isFalse);
    });

    test('copyWith overrides only provided fields', () {
      const config = TaskModelConfig(mentorModelId: 'm1');
      final updated = config.copyWith(evaluationModelId: 'e1');
      expect(updated.mentorModelId, equals('m1'));
      expect(updated.evaluationModelId, equals('e1'));
      expect(updated.tutorModelId, isEmpty);
    });

    test('round-trips through json', () {
      const config = TaskModelConfig(
        tutorModelId: 't',
        mentorModelId: 'm',
        classificationModelId: 'c',
        generationModelId: 'g',
        summarizationModelId: 's',
        evaluationModelId: 'e',
        transcriptionModelId: 'tr',
        useLocalForBackground: true,
      );
      final json = config.toJson();
      final restored = TaskModelConfig.fromJson(json);
      expect(restored, equals(config));
      expect(restored.useLocalForBackground, isTrue);
    });

    test('fromJson tolerates missing/extra keys', () {
      final restored = TaskModelConfig.fromJson(<String, dynamic>{
        'tutorModelId': 'only-tutor',
      });
      expect(restored.tutorModelId, equals('only-tutor'));
      expect(restored.mentorModelId, isEmpty);
      expect(restored.useLocalForBackground, isFalse);
    });
  });

  group('ModelRouter defaults', () {
    test('uses fallback model for tutor/mentor/generation/summarization/evaluation', () {
      const router = ModelRouter(
        config: TaskModelConfig(),
        fallbackModelId: 'main-model',
        provider: LlmProvider.openRouter,
      );
      expect(router.resolve(LlmTaskType.tutor), equals('main-model'));
      expect(router.resolve(LlmTaskType.mentor), equals('main-model'));
      expect(router.resolve(LlmTaskType.generation), equals('main-model'));
      expect(router.resolve(LlmTaskType.summarization), equals('main-model'));
      expect(router.resolve(LlmTaskType.evaluation), equals('main-model'));
    });

    test('classification and background use cheap defaults', () {
      const router = ModelRouter(
        config: TaskModelConfig(),
        fallbackModelId: 'main-model',
        provider: LlmProvider.openRouter,
      );
      expect(router.resolve(LlmTaskType.classification), equals('google/gemma-2-2b-it'));
      expect(router.resolve(LlmTaskType.background), equals('google/gemma-2-2b-it'));
    });

    test('transcription uses a multimodal default', () {
      const router = ModelRouter(
        config: TaskModelConfig(),
        fallbackModelId: 'main-model',
        provider: LlmProvider.openRouter,
      );
      expect(router.resolve(LlmTaskType.transcription), equals('google/gemini-2.0-flash-001'));
    });

    test('falls back to provider default when fallback model is empty', () {
      const router = ModelRouter(
        config: TaskModelConfig(),
        fallbackModelId: '',
        provider: LlmProvider.ollama,
      );
      expect(router.resolve(LlmTaskType.tutor), equals('llama3'));
    });
  });

  group('ModelRouter explicit configuration', () {
    test('uses configured model id when present', () {
      const router = ModelRouter(
        config: TaskModelConfig(generationModelId: 'big-reasoner'),
        fallbackModelId: 'main-model',
        provider: LlmProvider.openRouter,
      );
      expect(router.resolve(LlmTaskType.generation), equals('big-reasoner'));
    });
  });

  group('ModelRouter capability fallback', () {
    test('transcription falls back when configured model is not multimodal', () {
      const router = ModelRouter(
        config: TaskModelConfig(transcriptionModelId: 'some-text-only-model'),
        fallbackModelId: 'main-model',
        provider: LlmProvider.openRouter,
      );
      // Not multimodal -> fall back to main model.
      expect(router.resolve(LlmTaskType.transcription), equals('main-model'));
    });

    test('transcription keeps a multimodal-configured model', () {
      const router = ModelRouter(
        config: TaskModelConfig(transcriptionModelId: 'openai/gpt-4o-mini'),
        fallbackModelId: 'main-model',
        provider: LlmProvider.openRouter,
      );
      expect(router.resolve(LlmTaskType.transcription), equals('openai/gpt-4o-mini'));
    });

    test('background uses local model only with ollama provider', () {
      const localRouter = ModelRouter(
        config: TaskModelConfig(useLocalForBackground: true),
        fallbackModelId: 'main-model',
        provider: LlmProvider.ollama,
      );
      expect(localRouter.resolve(LlmTaskType.background), equals('llama3'));

      const cloudRouter = ModelRouter(
        config: TaskModelConfig(useLocalForBackground: true),
        fallbackModelId: 'main-model',
        provider: LlmProvider.openRouter,
      );
      expect(cloudRouter.resolve(LlmTaskType.background), equals('main-model'));
    });
  });

  group('LlmTaskType.fromFeature', () {
    test('maps known feature strings', () {
      expect(LlmTaskType.fromFeature('mentor'), equals(LlmTaskType.mentor));
      expect(LlmTaskType.fromFeature('tutor'), equals(LlmTaskType.tutor));
      expect(
        LlmTaskType.fromFeature('content_classification'),
        equals(LlmTaskType.classification),
      );
      expect(
        LlmTaskType.fromFeature('question_generation'),
        equals(LlmTaskType.generation),
      );
      expect(
        LlmTaskType.fromFeature('content_summarization'),
        equals(LlmTaskType.summarization),
      );
      expect(
        LlmTaskType.fromFeature('teaching_evaluation'),
        equals(LlmTaskType.evaluation),
      );
      expect(
        LlmTaskType.fromFeature('transcription'),
        equals(LlmTaskType.transcription),
      );
    });

    test('returns null for unrecognized features', () {
      expect(LlmTaskType.fromFeature('weather_lookup'), isNull);
    });
  });
}
