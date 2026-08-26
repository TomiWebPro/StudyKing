import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/extraction/llm_ocr_engine.dart';
import 'package:studyking/core/data/extraction/ocr_engine.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';

class _FakeLlmService extends LlmService {
  final Future<Result<String>> Function()? onChat;

  _FakeLlmService({this.onChat})
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'fake-key',
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
    if (onChat != null) return onChat!();
    return Result.success('hello world');
  }

  @override
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {
    yield 'stream';
  }
}

void main() {
  group('LlmOcrEngine', () {
    test('exposes engine name and no native confidence support', () {
      final engine = LlmOcrEngine(
        llmService: _FakeLlmService(),
        modelId: 'm',
        localeName: 'en',
      );
      expect(engine.name, 'llm');
      expect(engine.supportsConfidence, isFalse);
    });

    test('returns extracted text with configurable fallback confidence', () async {
      final engine = LlmOcrEngine(
        llmService: _FakeLlmService(onChat: () async => Result.success('  Extracted line  ')),
        modelId: 'm',
        localeName: 'en',
        fallbackConfidence: 0.6,
      );
      final result = await engine.recognize(
        OcrImageInput(rawContent: 'x', bytes: [1, 2, 3]),
      );
      expect(result.isSuccess, isTrue);
      expect(result.data!.text, 'Extracted line');
      expect(result.data!.confidence, 0.6);
    });

    test('returns success with empty text when LLM yields nothing', () async {
      final engine = LlmOcrEngine(
        llmService: _FakeLlmService(onChat: () async => Result.success('   ')),
        modelId: 'm',
        localeName: 'en',
      );
      final result = await engine.recognize(
        const OcrImageInput(rawContent: 'x', bytes: [1]),
      );
      expect(result.isSuccess, isTrue);
      expect(result.data!.hasText, isFalse);
      expect(result.data!.confidence, isNull);
    });

    test('returns failure when LLM chat fails', () async {
      final engine = LlmOcrEngine(
        llmService: _FakeLlmService(onChat: () async => Result.failure('api down')),
        modelId: 'm',
        localeName: 'en',
      );
      final result = await engine.recognize(
        const OcrImageInput(rawContent: 'x', bytes: [1]),
      );
      expect(result.isFailure, isTrue);
    });

    test('returns failure when no LLM service is configured', () async {
      final engine = LlmOcrEngine(modelId: 'm', localeName: 'en');
      final result = await engine.recognize(
        const OcrImageInput(rawContent: 'x', bytes: [1]),
      );
      expect(result.isFailure, isTrue);
    });

    test('forwards URLs directly to the LLM without throwing', () async {
      var called = false;
      final engine = LlmOcrEngine(
        llmService: _FakeLlmService(
          onChat: () async {
            called = true;
            return Result.success('ok');
          },
        ),
        modelId: 'm',
        localeName: 'en',
      );
      final urlResult = await engine.recognize(
        const OcrImageInput(rawContent: 'https://example.com/a.png'),
      );
      expect(urlResult.isSuccess, isTrue);
      expect(called, isTrue);
    });
  });
}
