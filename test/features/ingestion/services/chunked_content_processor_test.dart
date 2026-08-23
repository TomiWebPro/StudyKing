import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/ingestion/data/models/source_chunk.dart';
import 'package:studyking/features/ingestion/services/chunked_content_processor.dart';

class _FakeLlmService extends LlmService {
  _FakeLlmService()
      : super(config: LlmConfiguration(provider: LlmProvider.openRouter, apiKey: 'test'));

  int classifyCallCount = 0;
  int summarizeCallCount = 0;
  int questionCallCount = 0;
  String classifyResult = 'Math';
  String summarizeResult = 'Summary text';
  String questionResult = '[]';
  bool shouldFail = false;

  static const String defaultQuestions = '''[
    {"text": "Q1", "type": "singleChoice", "options": ["A", "B", "C", "D"], "correctAnswer": "A", "explanation": "Exp1"}
  ]''';

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
    if (shouldFail) return Result.failure('Simulated LLM error');

    if (feature == 'content_classification') {
      classifyCallCount++;
      return Result.success(classifyResult);
    }
    if (feature == 'content_summarization') {
      summarizeCallCount++;
      return Result.success(summarizeResult);
    }
    if (feature == 'question_generation') {
      questionCallCount++;
      return Result.success(
        questionResult.isNotEmpty ? questionResult : defaultQuestions,
      );
    }
    return Result.success('');
  }
}

class _FailOnConsolidationLlm extends LlmService {
  _FailOnConsolidationLlm()
      : super(config: LlmConfiguration(provider: LlmProvider.openRouter, apiKey: 'test'));

  int _summarizeCallCount = 0;

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
    if (feature == 'content_summarization') {
      _summarizeCallCount++;
      if (_summarizeCallCount > 2) {
        return Result.failure('Consolidation failed');
      }
      return Result.success('Chunk summary');
    }
    return Result.success('');
  }
}

void main() {
  late _FakeLlmService fakeLlm;
  late ChunkedContentProcessor processor;

  setUp(() {
    fakeLlm = _FakeLlmService();
    fakeLlm.questionResult = '';
    processor = ChunkedContentProcessor(llmService: fakeLlm, localeName: 'en');
  });

  group('splitIntoChunks', () {
    test('returns single chunk for empty text', () {
      final chunks = processor.splitIntoChunks('');
      expect(chunks, isEmpty);
    });

    test('returns single chunk for text under max size', () {
      final chunks = processor.splitIntoChunks('Short text');
      expect(chunks, hasLength(1));
      expect(chunks.first.text, 'Short text');
      expect(chunks.first.chunkIndex, 0);
    });

    test('splits large text into multiple chunks', () {
      final text = 'A' * 10000;
      final chunks = processor.splitIntoChunks(text);
      expect(chunks.length, greaterThan(1));
      for (final chunk in chunks) {
        expect(chunk.text.length, lessThanOrEqualTo(3100));
      }
    });

    test('assigns sequential chunk indices', () {
      final text = 'A' * 10000;
      final chunks = processor.splitIntoChunks(text);
      for (var i = 0; i < chunks.length; i++) {
        expect(chunks[i].chunkIndex, i);
      }
    });

    test('preserves headings when present', () {
      final text = '# Chapter 1\n${'A' * 2000}\n\n# Chapter 2\n${'B' * 2000}';
      final chunks = processor.splitIntoChunks(text);
      final headings = chunks.map((c) => c.heading).whereType<String>().toList();
      expect(headings, isNotEmpty);
    });
  });

  group('classifyChunks', () {
    test('returns empty result for no chunks', () async {
      final result = await processor.classifyChunks(
        chunks: [],
        possibleTopics: ['Math'],
        modelId: 'test',
        subjectId: 'sub1',
      );
      expect(result.topicId, isEmpty);
      expect(result.confidence, 0);
    });

    test('returns empty result for no possible topics', () async {
      final chunks = [SourceChunk(chunkIndex: 0, text: 'Content')];
      final result = await processor.classifyChunks(
        chunks: chunks,
        possibleTopics: [],
        modelId: 'test',
        subjectId: 'sub1',
      );
      expect(result.topicId, isEmpty);
    });

    test('classifies single chunk correctly', () async {
      final chunks = [SourceChunk(chunkIndex: 0, text: 'Algebra content')];
      final result = await processor.classifyChunks(
        chunks: chunks,
        possibleTopics: ['Math', 'Physics'],
        modelId: 'test',
        subjectId: 'sub1',
      );
      expect(result.topicId, 'Math');
      expect(fakeLlm.classifyCallCount, 1);
    });

    test('uses majority vote for multiple chunks', () async {
      fakeLlm.classifyResult = 'Math';
      final chunks = [
        SourceChunk(chunkIndex: 0, text: 'Algebra'),
        SourceChunk(chunkIndex: 1, text: 'Calculus'),
        SourceChunk(chunkIndex: 2, text: 'Geometry'),
      ];
      final result = await processor.classifyChunks(
        chunks: chunks,
        possibleTopics: ['Math', 'Physics'],
        modelId: 'test',
        subjectId: 'sub1',
      );
      expect(result.topicId, 'Math');
      expect(result.confidence, 1.0);
      expect(fakeLlm.classifyCallCount, 3);
    });

    test('handles LLM failure gracefully', () async {
      fakeLlm.shouldFail = true;
      final chunks = [SourceChunk(chunkIndex: 0, text: 'Content')];
      final result = await processor.classifyChunks(
        chunks: chunks,
        possibleTopics: ['Math'],
        modelId: 'test',
        subjectId: 'sub1',
      );
      expect(result.topicId, isEmpty);
    });
  });

  group('generateConsolidatedSummary', () {
    test('returns empty for no chunks', () async {
      final result = await processor.generateConsolidatedSummary(
        chunks: [],
        modelId: 'test',
      );
      expect(result, isEmpty);
    });

    test('summarizes single chunk directly', () async {
      final chunks = [SourceChunk(chunkIndex: 0, text: 'Content')];
      final result = await processor.generateConsolidatedSummary(
        chunks: chunks,
        modelId: 'test',
      );
      expect(result, 'Summary text');
      expect(fakeLlm.summarizeCallCount, 1);
    });

    test('consolidates multiple chunk summaries', () async {
      final chunks = [
        SourceChunk(chunkIndex: 0, text: 'Part 1'),
        SourceChunk(chunkIndex: 1, text: 'Part 2'),
      ];
      final result = await processor.generateConsolidatedSummary(
        chunks: chunks,
        modelId: 'test',
      );
      expect(result, isNotEmpty);
      expect(fakeLlm.summarizeCallCount, 3);
    });

    test('handles LLM failure by returning concatenated summaries', () async {
      final failFakeLlm = _FailOnConsolidationLlm();
      final failProcessor = ChunkedContentProcessor(llmService: failFakeLlm, localeName: 'en');
      final chunks = [
        SourceChunk(chunkIndex: 0, text: 'Part 1'),
        SourceChunk(chunkIndex: 1, text: 'Part 2'),
      ];

      final result = await failProcessor.generateConsolidatedSummary(
        chunks: chunks,
        modelId: 'test',
      );
      expect(result, isNotEmpty);
    });
  });

  group('generateQuestionsFromChunks', () {
    test('returns empty for no chunks', () async {
      final results = await processor.generateQuestionsFromChunks(
        chunks: [],
        modelId: 'test',
        questionParser: QuestionParser(),
      );
      expect(results, isEmpty);
    });

    test('generates questions from single chunk', () async {
      final chunks = [SourceChunk(chunkIndex: 0, text: 'Content')];
      final results = await processor.generateQuestionsFromChunks(
        chunks: chunks,
        modelId: 'test',
        questionParser: QuestionParser(),
      );
      expect(results, isNotEmpty);
      expect(results.first.chunkIndex, 0);
      expect(fakeLlm.questionCallCount, 1);
    });

    test('generates questions from multiple chunks', () async {
      final chunks = [
        SourceChunk(chunkIndex: 0, text: 'Part 1'),
        SourceChunk(chunkIndex: 1, text: 'Part 2'),
      ];
      final results = await processor.generateQuestionsFromChunks(
        chunks: chunks,
        modelId: 'test',
        questionParser: QuestionParser(),
      );
      expect(results, isNotEmpty);
      expect(fakeLlm.questionCallCount, 2);
      final chunkIndices = results.map((r) => r.chunkIndex).toSet();
      expect(chunkIndices, containsAll([0, 1]));
    });

    test('handles LLM failure for individual chunks', () async {
      fakeLlm.shouldFail = true;
      final chunks = [SourceChunk(chunkIndex: 0, text: 'Content')];
      final results = await processor.generateQuestionsFromChunks(
        chunks: chunks,
        modelId: 'test',
        questionParser: QuestionParser(),
      );
      expect(results, isEmpty);
    });

    test('links questions to correct chunk indices', () async {
      fakeLlm.questionResult = '''[
        {"text": "Q from chunk", "type": "singleChoice", "options": ["A", "B"], "correctAnswer": "A", "explanation": "Exp"}
      ]''';
      final chunks = [
        SourceChunk(chunkIndex: 0, text: 'Part 1'),
        SourceChunk(chunkIndex: 1, text: 'Part 2'),
      ];
      final results = await processor.generateQuestionsFromChunks(
        chunks: chunks,
        modelId: 'test',
        questionParser: QuestionParser(),
      );
      expect(results.length, 2);
      expect(results[0].chunkIndex, 0);
      expect(results[1].chunkIndex, 1);
      expect(results[0].questionData['text'], results[1].questionData['text']);
    });
  });

  group('QuestionParser', () {
    test('parses valid JSON array', () {
      final parser = QuestionParser();
      final result = parser.parse('[{"text": "Q1"}]');
      expect(result, hasLength(1));
      expect(result.first['text'], 'Q1');
    });

    test('parses JSON with questions key', () {
      final parser = QuestionParser();
      final result = parser.parse('{"questions": [{"text": "Q1"}]}');
      expect(result, hasLength(1));
    });

    test('handles markdown code blocks', () {
      final parser = QuestionParser();
      final result = parser.parse('```json\n[{"text": "Q1"}]\n```');
      expect(result, hasLength(1));
    });

    test('returns empty for invalid JSON', () {
      final parser = QuestionParser();
      final result = parser.parse('not json');
      expect(result, isEmpty);
    });

    test('returns empty for empty response', () {
      final parser = QuestionParser();
      final result = parser.parse('');
      expect(result, isEmpty);
    });
  });

  group('cancel and reset', () {
    test('cancel stops processing', () {
      processor.cancel();
      final chunks = processor.splitIntoChunks('A' * 10000);
      expect(chunks, isNotEmpty);
    });

    test('reset allows processing after cancel', () {
      processor.cancel();
      processor.reset();
      final chunks = processor.splitIntoChunks('A' * 10000);
      expect(chunks, isNotEmpty);
    });
  });
}
