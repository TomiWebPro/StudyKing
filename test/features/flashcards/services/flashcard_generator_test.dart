import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/flashcards/data/models/flashcard_model.dart';
import 'package:studyking/features/flashcards/data/repositories/flashcard_repository.dart';
import 'package:studyking/features/flashcards/services/flashcard_generator.dart';

class _FakeLlmService extends LlmService {
  final String responseJson;

  _FakeLlmService({required this.responseJson})
      : super(config: LlmConfiguration(provider: LlmProvider.openRouter, apiKey: 'test'));

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
    return Result.success(responseJson);
  }
}

class _FakeFlashcardRepository extends FlashcardRepository {
  final Map<String, Flashcard> _storage = {};

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Flashcard>>> getAll() async =>
      Result.success(_storage.values.toList());

  @override
  Future<Result<Flashcard?>> get(String id) async =>
      Result.success(_storage[id]);

  @override
  Future<Result<void>> save(String key, Flashcard item) async {
    _storage[key] = item;
    return Result.success(null);
  }

  @override
  Future<Result<void>> create(Flashcard flashcard) async {
    _storage[flashcard.id] = flashcard;
    return Result.success(null);
  }
}

void main() {
  group('FlashcardGenerator', () {
    late _FakeFlashcardRepository repo;

    setUp(() {
      repo = _FakeFlashcardRepository();
    });

    test('parses valid JSON flashcards and saves them', () async {
      final flashcardsJson = '''[
        {"front": "What is DNA?", "back": "Deoxyribonucleic acid", "tags": ["biology"]},
        {"front": "What is RNA?", "back": "Ribonucleic acid", "tags": ["biology", "genetics"]}
      ]''';

      final llm = _FakeLlmService(responseJson: flashcardsJson);
      final generator = FlashcardGenerator(
        llmService: llm,
        flashcardRepository: repo,
      );

      final result = await generator.generateFlashcards(
        content: 'DNA is deoxyribonucleic acid. RNA is ribonucleic acid.',
        sourceId: 'src_1',
        topicId: 'topic_1',
        subjectId: 'sub_1',
        modelId: 'test-model',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data?.length, 2);
      expect(result.data?.first.front, 'What is DNA?');
      expect(result.data?.first.sourceId, 'src_1');
      expect(result.data?.first.tags, ['biology']);
    });

    test('handles flashcards wrapped in object with key', () async {
      final flashcardsJson = '{"flashcards": [{"front": "Formula?", "back": "E = mc²", "tags": ["physics"]}]}';

      final llm = _FakeLlmService(responseJson: flashcardsJson);
      final generator = FlashcardGenerator(
        llmService: llm,
        flashcardRepository: repo,
      );

      final result = await generator.generateFlashcards(
        content: 'Einstein equation.',
        sourceId: 'src_1',
        topicId: 'topic_1',
        subjectId: 'sub_1',
        modelId: 'test-model',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data?.length, 1);
      expect(result.data?.first.front, 'Formula?');
    });

    test('skips flashcards with empty front or back', () async {
      final flashcardsJson = '''[
        {"front": "Valid?", "back": "Yes"},
        {"front": "", "back": "Missing front"},
        {"front": "Missing back", "back": ""},
        {"front": "Also valid", "back": "Yes too"}
      ]''';

      final llm = _FakeLlmService(responseJson: flashcardsJson);
      final generator = FlashcardGenerator(
        llmService: llm,
        flashcardRepository: repo,
      );

      final result = await generator.generateFlashcards(
        content: 'Some content.',
        sourceId: 'src_1',
        topicId: 'topic_1',
        subjectId: 'sub_1',
        modelId: 'test-model',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data?.length, 2);
    });

    test('skips malformed flashcard items and logs a warning', () async {
      final records = <String>[];
      final originalPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => records.add(message ?? '');

      final flashcardsJson = '''[
        {"front": "Valid?", "back": "Yes"},
        "this is not a flashcard object",
        {"front": "Also valid", "back": "Yes too"}
      ]''';

      final llm = _FakeLlmService(responseJson: flashcardsJson);
      final generator = FlashcardGenerator(
        llmService: llm,
        flashcardRepository: repo,
      );

      final result = await generator.generateFlashcards(
        content: 'Some content.',
        sourceId: 'src_1',
        topicId: 'topic_1',
        subjectId: 'sub_1',
        modelId: 'test-model',
      );

      debugPrint = originalPrint;

      expect(result.isSuccess, isTrue);
      expect(result.data?.length, 2);
      expect(
        records.any((r) => r.contains('malformed flashcard item')),
        isTrue,
        reason: 'expected a warning to be logged for the skipped item',
      );
    });

    test('returns failure on invalid JSON', () async {
      final llm = _FakeLlmService(responseJson: 'not json at all');
      final generator = FlashcardGenerator(
        llmService: llm,
        flashcardRepository: repo,
      );

      final result = await generator.generateFlashcards(
        content: 'Some content.',
        sourceId: 'src_1',
        topicId: 'topic_1',
        subjectId: 'sub_1',
        modelId: 'test-model',
      );

      expect(result.isFailure, isTrue);
    });

    test('handles response wrapped in markdown code block', () async {
      final flashcardsJson = '```json\n[{"front": "Q1", "back": "A1", "tags": []}]\n```';

      final llm = _FakeLlmService(responseJson: flashcardsJson);
      final generator = FlashcardGenerator(
        llmService: llm,
        flashcardRepository: repo,
      );

      final result = await generator.generateFlashcards(
        content: 'Content.',
        sourceId: 'src_1',
        topicId: 'topic_1',
        subjectId: 'sub_1',
        modelId: 'test-model',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data?.length, 1);
    });

    test('all generated flashcards have correct source/topic/subject IDs', () async {
      final flashcardsJson = '[{"front": "Q1", "back": "A1", "tags": []}, {"front": "Q2", "back": "A2", "tags": []}]';

      final llm = _FakeLlmService(responseJson: flashcardsJson);
      final generator = FlashcardGenerator(
        llmService: llm,
        flashcardRepository: repo,
      );

      final result = await generator.generateFlashcards(
        content: 'Content.',
        sourceId: 'src_test',
        topicId: 'topic_test',
        subjectId: 'sub_test',
        modelId: 'test-model',
      );

      expect(result.isSuccess, isTrue);
      for (final card in result.data!) {
        expect(card.sourceId, 'src_test');
        expect(card.topicId, 'topic_test');
        expect(card.subjectId, 'sub_test');
      }
    });
  });
}
