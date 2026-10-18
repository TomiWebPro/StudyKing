import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/ingestion/data/models/source_chunk.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/ingestion/services/chunked_content_processor.dart';

class FakeLlmService extends LlmService {
  final String response;

  FakeLlmService(this.response)
      : super(config: const LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'k',
          baseUrl: '',
          model: 'm',
        ));

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
    return Result.success(response);
  }
}

void main() {
  group('ChunkedContentProcessor.splitIntoChunks', () {
    final processor = ChunkedContentProcessor(
      llmService: FakeLlmService('x'),
      localeName: 'en',
    );

    test('returns empty for empty input', () {
      expect(processor.splitIntoChunks(''), isEmpty);
    });

    test('returns a single chunk for short text', () {
      final chunks = processor.splitIntoChunks('Short piece of text.');
      expect(chunks.length, 1);
      expect(chunks.first.text, 'Short piece of text.');
    });

    test('splits long text into multiple chunks', () {
      final longText = List.generate(4000, (i) => 'a').join();
      final chunks = processor.splitIntoChunks(longText);
      expect(chunks.length, greaterThan(1));
      for (var i = 0; i < chunks.length; i++) {
        expect(chunks[i].chunkIndex, i);
      }
    });

    test('splits textbook text at chapter boundaries and detects headings', () {
      final content = 'A' * 1500;
      final textbookText = 'Chapter 1 Introduction to Biology\n\n'
          '$content\n\n'
          'Chapter 2 The Cell Structure\n\n'
          '$content';

      final chunks = processor.splitIntoChunks(textbookText);

      expect(chunks.length, greaterThan(1));
      final chapterHeadings = chunks.where((c) => c.heading != null).toList();
      expect(chapterHeadings, isNotEmpty);
      expect(chapterHeadings.any((c) => c.heading!.contains('Chapter 1')), isTrue);
      expect(chapterHeadings.any((c) => c.heading!.contains('Chapter 2')), isTrue);
    });

    test('splits textbook text at numbered section boundaries', () {
      final content = 'B' * 1500;
      final textbookText = '1.1 The Scientific Method\n\n'
          '$content\n\n'
          '2.3 Experimental Results\n\n'
          '$content';

      final chunks = processor.splitIntoChunks(textbookText);

      expect(chunks.length, greaterThan(1));
      final numberHeadings = chunks.where((c) => c.heading != null).toList();
      expect(numberHeadings.any((c) => c.heading!.contains('1.1')), isTrue);
      expect(numberHeadings.any((c) => c.heading!.contains('2.3')), isTrue);
    });

    test('does not split on decimal value at start of prose paragraph', () {
      final content = 'C' * 1500;
      final textbookText = 'The value of pi is approximately 3.14 in math.\n\n'
          '$content\n\n'
          'Another paragraph here.\n\n'
          '$content';

      final chunks = processor.splitIntoChunks(textbookText);

      expect(chunks.length, greaterThan(1));
      // "3.14" appears mid-paragraph, should not be detected as a heading
      final falsePositives = chunks.where(
        (c) => c.heading != null && c.heading!.contains('3.14'),
      ).toList();
      expect(falsePositives, isEmpty);
    });
  });

  group('ChunkedContentProcessor.classifyChunks', () {
    test('aggregates LLM votes into a winning topic', () async {
      final processor = ChunkedContentProcessor(
        llmService: FakeLlmService('Biology'),
        localeName: 'en',
      );
      final chunks = [
        SourceChunk(chunkIndex: 0, text: 'cell biology content'),
        SourceChunk(chunkIndex: 1, text: 'more biology content'),
      ];

      final result = await processor.classifyChunks(
        chunks: chunks,
        possibleTopics: ['Biology', 'Chemistry'],
        modelId: 'm',
        subjectId: '',
      );

      expect(result.topicId, 'Biology');
      expect(result.confidence, 1.0);
    });

    test('returns empty topic when the LLM fails', () async {
      final chunks = [SourceChunk(chunkIndex: 0, text: 'content')];

      // Override chat to fail.
      final failing = _FailingLlmService();
      final failingProcessor = ChunkedContentProcessor(
        llmService: failing,
        localeName: 'en',
      );

      final result = await failingProcessor.classifyChunks(
        chunks: chunks,
        possibleTopics: ['Biology'],
        modelId: 'm',
        subjectId: '',
      );

      expect(result.topicId, '');
      expect(result.confidence, 0);
      expect(failing.chatCalled, isTrue);
    });
  });

  group('ChunkedContentProcessor.generateConsolidatedSummary', () {
    test('summarizes a single chunk', () async {
      final processor = ChunkedContentProcessor(
        llmService: FakeLlmService('summary'),
        localeName: 'en',
      );
      final result = await processor.generateConsolidatedSummary(
        chunks: [SourceChunk(chunkIndex: 0, text: 'content')],
        modelId: 'm',
      );
      expect(result.isSuccess, isTrue);
      expect(result.data, 'summary');
    });

    test('consolidates multiple chunk summaries', () async {
      final processor = ChunkedContentProcessor(
        llmService: FakeLlmService('summary'),
        localeName: 'en',
      );
      final result = await processor.generateConsolidatedSummary(
        chunks: [
          SourceChunk(chunkIndex: 0, text: 'one'),
          SourceChunk(chunkIndex: 1, text: 'two'),
        ],
        modelId: 'm',
      );
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotEmpty);
      expect(result.data, 'summary');
    });

    test('returns failure when LLM fails for single chunk', () async {
      final failing = _FailingLlmService();
      final processor = ChunkedContentProcessor(
        llmService: failing,
        localeName: 'en',
      );
      final result = await processor.generateConsolidatedSummary(
        chunks: [SourceChunk(chunkIndex: 0, text: 'content')],
        modelId: 'm',
      );
      expect(result.isFailure, isTrue);
    });

    test('returns failure when LLM fails for multiple chunks', () async {
      final failing = _FailingLlmService();
      final processor = ChunkedContentProcessor(
        llmService: failing,
        localeName: 'en',
      );
      final result = await processor.generateConsolidatedSummary(
        chunks: [
          SourceChunk(chunkIndex: 0, text: 'one'),
          SourceChunk(chunkIndex: 1, text: 'two'),
        ],
        modelId: 'm',
      );
      expect(result.isFailure, isTrue);
    });

    test('returns success with empty string for empty chunks', () async {
      final processor = ChunkedContentProcessor(
        llmService: FakeLlmService('summary'),
        localeName: 'en',
      );
      final result = await processor.generateConsolidatedSummary(
        chunks: [],
        modelId: 'm',
      );
      expect(result.isSuccess, isTrue);
      expect(result.data, '');
    });
  });

  group('ChunkedContentProcessor.retry behavior', () {
    test('retries LLM call on failure and succeeds after backoff', () async {
      final fake = _RetryingLlmService(failuresBeforeSuccess: 2);
      final processor = ChunkedContentProcessor(
        llmService: fake,
        localeName: 'en',
        maxRetryAttempts: 3,
        retryInitialDelay: Duration.zero,
      );

      final chunks = [SourceChunk(chunkIndex: 0, text: 'content')];
      await processor.classifyChunks(
        chunks: chunks,
        possibleTopics: ['Biology'],
        modelId: 'm',
        subjectId: '',
      );

      // Initial attempt + 2 retries = 3 calls
      expect(fake.chatCallCount, 3);
    });

    test('increments failedChunkCount when all retries are exhausted', () async {
      final processor = ChunkedContentProcessor(
        llmService: _FailingLlmService(),
        localeName: 'en',
        maxRetryAttempts: 2,
        retryInitialDelay: Duration.zero,
      );

      final chunks = [SourceChunk(chunkIndex: 0, text: 'content')];
      await processor.classifyChunks(
        chunks: chunks,
        possibleTopics: ['Biology'],
        modelId: 'm',
        subjectId: '',
      );

      expect(processor.failedChunkCount, 1);
    });

    test('reset clears failedChunkCount', () async {
      final processor = ChunkedContentProcessor(
        llmService: _FailingLlmService(),
        localeName: 'en',
        maxRetryAttempts: 1,
        retryInitialDelay: Duration.zero,
      );

      final chunks = [SourceChunk(chunkIndex: 0, text: 'content')];
      await processor.classifyChunks(
        chunks: chunks,
        possibleTopics: ['Biology'],
        modelId: 'm',
        subjectId: '',
      );

      expect(processor.failedChunkCount, 1);
      processor.reset();
      expect(processor.failedChunkCount, 0);
    });

    test('does not increment failedChunkCount on success', () async {
      final processor = ChunkedContentProcessor(
        llmService: FakeLlmService('Biology'),
        localeName: 'en',
        maxRetryAttempts: 3,
        retryInitialDelay: Duration.zero,
      );

      final chunks = [SourceChunk(chunkIndex: 0, text: 'content')];
      await processor.classifyChunks(
        chunks: chunks,
        possibleTopics: ['Biology'],
        modelId: 'm',
        subjectId: '',
      );

      expect(processor.failedChunkCount, 0);
    });
  });

  group('QuestionParser', () {
    final parser = QuestionParser();

    test('parses a JSON array of questions', () {
      final result = parser.parse('[{"text":"q1"},{"text":"q2"}]');
      expect(result.length, 2);
      expect(result.first['text'], 'q1');
    });

    test('parses fenced JSON', () {
      final result = parser.parse('```json\n[{"text":"q1"}]\n```');
      expect(result.length, 1);
    });

    test('returns empty on invalid input', () {
      final result = parser.parse('not json at all');
      expect(result, isEmpty);
    });
  });
}

class _FailingLlmService extends LlmService {
  bool chatCalled = false;

  _FailingLlmService()
      : super(config: const LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'k',
          baseUrl: '',
          model: 'm',
        ));

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
    chatCalled = true;
    return Result.failure('llm down');
  }
}

/// Fake LLM service that fails [failuresBeforeSuccess] times, then succeeds.
/// Used to verify retry-with-backoff behaviour in [ChunkedContentProcessor].
class _RetryingLlmService extends LlmService {
  int chatCallCount = 0;
  final int failuresBeforeSuccess;

  _RetryingLlmService({required this.failuresBeforeSuccess})
      : super(config: const LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'k',
          baseUrl: '',
          model: 'm',
        ));

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
    chatCallCount++;
    if (chatCallCount <= failuresBeforeSuccess) {
      return Result.failure('rate limited');
    }
    return Result.success('Biology');
  }
}
