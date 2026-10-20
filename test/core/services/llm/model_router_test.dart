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
      // Syllabus topic-extraction is a classification task (ContentPipeline
      // uses the classification model); it must NOT fall into 'unknown'.
      expect(
        LlmTaskType.fromFeature('syllabus_topic_extraction'),
        equals(LlmTaskType.classification),
      );
      // 'teaching' is the live tutoring feature passed by ConversationManager;
      // it must classify as tutor, not fall into 'unknown'.
      expect(LlmTaskType.fromFeature('teaching'), equals(LlmTaskType.tutor));
      // Planner advisor (plan generation / adaptation) is invoked from mentor
      // agent tools (CreatePlanTool) during Mentor Mode planning journeys
      // (agent_must_read.md §54-67). Its tokens must attribute to the 'mentor'
      // task type so they are visible in the task-manager portal (Vision §0:
      // students must see and steer where tokens go), never 'unknown'.
      expect(
        LlmTaskType.fromFeature('planner_advisor_plan_generation'),
        equals(LlmTaskType.mentor),
      );
      expect(
        LlmTaskType.fromFeature('planner_advisor_plan_adaptation'),
        equals(LlmTaskType.mentor),
      );
      // The fallback path appends ' (fallback)'; it must still classify.
      expect(
        LlmTaskType.fromFeature('planner_advisor_plan_generation (fallback)'),
        equals(LlmTaskType.mentor),
      );
      // Image analysis during tutoring is a live visual-tutoring modality
      // (ConversationManager.processImage). Its tokens must attribute to the
      // tutor task type instead of leaking into the 'unknown' bucket, so the
      // prep-vs-live ratio and the task-manager portal stay accurate.
      expect(
        LlmTaskType.fromFeature('teaching_image_analysis'),
        equals(LlmTaskType.tutor),
      );
      // Conversation-memory compression is live summarization work, not an
      // unclassified 'general' chat turn.
      expect(
        LlmTaskType.fromFeature('conversation_memory_compression'),
        equals(LlmTaskType.summarization),
      );
      // Quick Guide is a teaching aid (just-in-time reference during a lesson),
      // so its tokens must attribute to the 'tutor' task type, not 'unknown'.
      expect(
        LlmTaskType.fromFeature('tutor_quick_guide'),
        equals(LlmTaskType.tutor),
      );
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

    test('maps off-period prep features to background', () {
      // Vision Next-Term §4.1: prep tasks (PDF ingestion, question variants,
      // lesson pre-generation, embeddings, mastery refresh) are all off-period
      // background work. Mapping them to background ensures LlmUsageMeter
      // records them with a prep-category taskType, not null — so
      // PrepBudgetService.totalLiveTokens() does not mistakenly count prep
      // tokens as live.
      expect(LlmTaskType.fromFeature('pdf_ingestion'), equals(LlmTaskType.background));
      expect(LlmTaskType.fromFeature('question_variants'), equals(LlmTaskType.background));
      expect(LlmTaskType.fromFeature('lesson_prep'), equals(LlmTaskType.background));
      expect(LlmTaskType.fromFeature('embeddings'), equals(LlmTaskType.background));
      expect(LlmTaskType.fromFeature('mastery_refresh'), equals(LlmTaskType.background));
    });

    test('maps question_variant_generation to background (not generation)', () {
      // Regression guard: QuestionVariantService previously used the feature
      // string 'question_variant_generation', which fromFeature misclassified
      // as LlmTaskType.generation (live) because 'variant_generation' matched
      // the generation block before the prep-category block. The prep
      // features now check first, so even the older feature string maps to
      // background — actual prep tokens are never counted as live generation
      // (Vision Next-Term §0 token principle, §4.4 ratio).
      expect(
        LlmTaskType.fromFeature('question_variant_generation'),
        equals(LlmTaskType.background),
      );
      expect(
        LlmTaskType.fromFeature('question_variants'),
        equals(LlmTaskType.background),
      );
      // Sanity: genuine live generation features still map to generation.
      expect(
        LlmTaskType.fromFeature('question_generation'),
        equals(LlmTaskType.generation),
      );
    });

    test('returns null for unrecognized features', () {
      expect(LlmTaskType.fromFeature('weather_lookup'), isNull);
    });
  });
}
