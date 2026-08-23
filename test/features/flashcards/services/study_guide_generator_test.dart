import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/flashcards/data/models/study_guide_model.dart';
import 'package:studyking/features/flashcards/data/repositories/study_guide_repository.dart';
import 'package:studyking/features/flashcards/services/study_guide_generator.dart';

class _FakeLlmService extends LlmService {
  _FakeLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'test',
          ),
        );

  Result<String>? forcedResult;
  String? response;
  String? lastFeature;

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
    lastFeature = feature;
    if (forcedResult != null) return forcedResult!;
    return Result.success(response ?? '');
  }
}

class _FakeStudyGuideRepository extends StudyGuideRepository {
  final Map<String, StudyGuide> stored = {};

  @override
  Future<Result<void>> create(StudyGuide guide) async {
    stored[guide.id] = guide;
    return Result.success(null);
  }
}

void main() {
  group('StudyGuideGenerator', () {
    late _FakeLlmService llm;
    late _FakeStudyGuideRepository repo;
    late StudyGuideGenerator generator;

    setUp(() {
      llm = _FakeLlmService();
      repo = _FakeStudyGuideRepository();
      generator = StudyGuideGenerator(llmService: llm, repository: repo);
    });

    test('happy path saves study guide', () async {
      llm.response = '# Key Concepts\n- Cell division\n- Photosynthesis';
      final result = await generator.generateStudyGuide(
        content: 'Biology content',
        sourceId: 's1',
        topicId: 't1',
        subjectId: 'sub1',
        topicTitle: 'Biology',
        modelId: 'model-x',
      );
      expect(result.isSuccess, isTrue);
      final guide = result.data!;
      expect(guide.content, contains('Cell division'));
      expect(guide.title, 'Study Guide: Biology');
      expect(repo.stored.containsKey(guide.id), isTrue);
      expect(llm.lastFeature, 'study_guide_generation');
    });

    test('propagates LLM failure', () async {
      llm.forcedResult = Result.failure('model unavailable');
      final result = await generator.generateStudyGuide(
        content: 'x',
        sourceId: 's1',
        topicId: 't1',
        subjectId: 'sub1',
        topicTitle: 'Biology',
        modelId: 'model-x',
      );
      expect(result.isFailure, isTrue);
      expect(repo.stored, isEmpty);
    });

    test('returns failure for empty response', () async {
      llm.response = '   ';
      final result = await generator.generateStudyGuide(
        content: 'x',
        sourceId: 's1',
        topicId: 't1',
        subjectId: 'sub1',
        topicTitle: 'Biology',
        modelId: 'model-x',
      );
      expect(result.isFailure, isTrue);
      expect(result.error, contains('Empty study guide'));
    });
  });
}
