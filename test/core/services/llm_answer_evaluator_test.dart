import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:studyking/core/data/extraction/asr_engine.dart';
import 'package:studyking/core/data/extraction/transcription_extractor.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_answer_evaluator.dart';

class _StubLlmClient extends MultimodalLlmClient {
  Result<LlmEvaluation>? nextResult;
  int callCount = 0;

  _StubLlmClient({this.nextResult});

  @override
  Future<Result<LlmEvaluation>> evaluate({
    required String prompt,
    required String mediaBase64,
    required String mediaType,
  }) async {
    callCount++;
    return nextResult ??
        Result.success(const LlmEvaluation(isCorrect: true, score: 1.0, feedback: 'ok', confidence: 1.0));
  }
}

class _StubTranscription extends TranscriptionService {
  Result<String>? nextResult;
  int callCount = 0;

  _StubTranscription({this.nextResult});

  @override
  Future<Result<String>> transcribe(String audioData) async {
    callCount++;
    return nextResult ?? Result.success('transcribed text');
  }
}

Markscheme _markscheme(String correct, {List<String> acceptable = const []}) => Markscheme(
      questionId: 'q1',
      correctAnswer: correct,
      acceptableAnswers: acceptable,
    );

LlmAnswerEvaluator _evaluator({
  required MultimodalLlmClient llm,
  required TranscriptionService transcription,
  double threshold = 0.5,
}) =>
    LlmAnswerEvaluator(
      llmClient: llm,
      transcriptionService: transcription,
      messages: ValidationMessagesForEvaluator.english,
      lowConfidenceThreshold: threshold,
    );

void main() {
  group('LlmAnswerEvaluator - graph drawing', () {
    test('returns incorrect (no manual review) for empty drawing', () async {
      final evaluator = _evaluator(llm: _StubLlmClient(), transcription: _StubTranscription());

      final result = await evaluator.evaluateGraphDrawing('', _markscheme('y=2x'));

      expect(result.isSuccess, isTrue);
      expect(result.data!.isCorrect, isFalse);
      expect(result.data!.needsManualReview, isFalse);
    });

    test('returns correct when LLM reports correct with high confidence', () async {
      final llm = _StubLlmClient(
        nextResult: Result.success(const LlmEvaluation(
          isCorrect: true,
          score: 0.9,
          feedback: 'Slope and intercept correct',
          confidence: 0.95,
        )),
      );
      final evaluator = _evaluator(llm: llm, transcription: _StubTranscription());

      final result = await evaluator.evaluateGraphDrawing('base64data', _markscheme('y=2x'));

      expect(result.isSuccess, isTrue);
      expect(result.data!.isCorrect, isTrue);
      expect(result.data!.score, closeTo(0.9, 0.0001));
      expect(result.data!.needsManualReview, isFalse);
      expect(llm.callCount, 1);
    });

    test('flags manual review when LLM returns low confidence', () async {
      final llm = _StubLlmClient(
        nextResult: Result.success(const LlmEvaluation(
          isCorrect: true,
          score: 0.5,
          feedback: 'Uncertain',
          confidence: 0.2,
        )),
      );
      final evaluator = _evaluator(llm: llm, transcription: _StubTranscription());

      final result = await evaluator.evaluateGraphDrawing('base64data', _markscheme('y=2x'));

      expect(result.isSuccess, isTrue);
      expect(result.data!.needsManualReview, isTrue);
      expect(result.data!.isCorrect, isTrue);
    });

    test('flags manual review when LLM client fails (graceful fallback)', () async {
      final llm = _StubLlmClient(nextResult: Result.failure('network error'));
      final evaluator = _evaluator(llm: llm, transcription: _StubTranscription());

      final result = await evaluator.evaluateGraphDrawing('base64data', _markscheme('y=2x'));

      expect(result.isSuccess, isTrue);
      expect(result.data!.needsManualReview, isTrue);
      expect(result.data!.isCorrect, isFalse);
    });
  });

  group('LlmAnswerEvaluator - file upload', () {
    test('returns incorrect for empty upload', () async {
      final evaluator = _evaluator(llm: _StubLlmClient(), transcription: _StubTranscription());

      final result = await evaluator.evaluateFileUpload('', _markscheme('answer'));

      expect(result.isSuccess, isTrue);
      expect(result.data!.isCorrect, isFalse);
      expect(result.data!.needsManualReview, isFalse);
    });

    test('returns correct when LLM reports correct', () async {
      final llm = _StubLlmClient(
        nextResult: Result.success(const LlmEvaluation(
          isCorrect: true,
          score: 1.0,
          feedback: 'Matches',
          confidence: 0.9,
        )),
      );
      final evaluator = _evaluator(llm: llm, transcription: _StubTranscription());

      final result = await evaluator.evaluateFileUpload('filebytes', _markscheme('answer'));

      expect(result.data!.isCorrect, isTrue);
      expect(result.data!.needsManualReview, isFalse);
    });

    test('flags manual review when LLM client fails', () async {
      final llm = _StubLlmClient(nextResult: Result.failure('boom'));
      final evaluator = _evaluator(llm: llm, transcription: _StubTranscription());

      final result = await evaluator.evaluateFileUpload('filebytes', _markscheme('answer'));

      expect(result.data!.needsManualReview, isTrue);
      expect(result.data!.isCorrect, isFalse);
    });
  });

  group('LlmAnswerEvaluator - audio recording', () {
    test('returns incorrect for empty audio', () async {
      final evaluator = _evaluator(llm: _StubLlmClient(), transcription: _StubTranscription());

      final result = await evaluator.evaluateAudioRecording('', _markscheme('hello'));

      expect(result.data!.isCorrect, isFalse);
      expect(result.data!.needsManualReview, isFalse);
    });

    test('flags manual review when transcription fails', () async {
      final transcription = _StubTranscription(nextResult: Result.failure('no audio engine'));
      final evaluator = _evaluator(llm: _StubLlmClient(), transcription: transcription);

      final result = await evaluator.evaluateAudioRecording('audiobytes', _markscheme('hello'));

      expect(result.data!.needsManualReview, isTrue);
      expect(result.data!.isCorrect, isFalse);
    });

    test('marks correct when transcript matches markscheme', () async {
      final transcription = _StubTranscription(nextResult: Result.success('hello'));
      final evaluator = _evaluator(llm: _StubLlmClient(), transcription: transcription);

      final result = await evaluator.evaluateAudioRecording(
        'audiobytes',
        _markscheme('hello', acceptable: ['hi']),
      );

      expect(result.data!.isCorrect, isTrue);
      expect(result.data!.needsManualReview, isFalse);
      expect(transcription.callCount, 1);
    });

    test('marks incorrect when transcript does not match markscheme', () async {
      final transcription = _StubTranscription(nextResult: Result.success('goodbye'));
      final evaluator = _evaluator(llm: _StubLlmClient(), transcription: transcription);

      final result = await evaluator.evaluateAudioRecording(
        'audiobytes',
        _markscheme('hello'),
      );

      expect(result.data!.isCorrect, isFalse);
      expect(result.data!.needsManualReview, isFalse);
    });

    test('flags manual review when no markscheme is available', () async {
      final transcription = _StubTranscription(nextResult: Result.success('hello'));
      final evaluator = _evaluator(llm: _StubLlmClient(), transcription: transcription);

      final result = await evaluator.evaluateAudioRecording('audiobytes', null);

      expect(result.data!.needsManualReview, isTrue);
      expect(result.data!.isCorrect, isFalse);
    });
  });

  group('Unavailable clients', () {
    test('UnavailableMultimodalLlmClient reports failure', () async {
      final client = UnavailableMultimodalLlmClient();
      final result = await client.evaluate(prompt: 'p', mediaBase64: 'x', mediaType: 'image/png');
      expect(result.isFailure, isTrue);
    });

    test('UnavailableTranscriptionService reports failure', () async {
      final service = UnavailableTranscriptionService();
      final result = await service.transcribe('audio');
      expect(result.isFailure, isTrue);
    });
  });

  group('LlmAnswerEvaluator - low confidence threshold', () {
    test('respects custom threshold for manual review', () async {
      final llm = _StubLlmClient(
        nextResult: Result.success(const LlmEvaluation(
          isCorrect: true,
          score: 1.0,
          feedback: 'ok',
          confidence: 0.6,
        )),
      );
      final evaluator = _evaluator(llm: llm, transcription: _StubTranscription(), threshold: 0.7);

      final result = await evaluator.evaluateGraphDrawing('d', _markscheme('y=x'));

      expect(result.data!.needsManualReview, isTrue);
    });
  });

  group('LlmGradingMultimodalClient', () {
    test('parses a valid grading JSON response', () async {
      final client = _gradingClient(
        responseBody: _chatBody(jsonEncode({
          'isCorrect': true,
          'score': 0.9,
          'feedback': 'Slope and intercept correct',
          'confidence': 0.95,
        })),
      );

      final result = await client.evaluate(
        prompt: 'Grade this graph',
        mediaBase64: 'base64png',
        mediaType: 'image/png',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.isCorrect, isTrue);
      expect(result.data!.score, closeTo(0.9, 0.0001));
      expect(result.data!.confidence, closeTo(0.95, 0.0001));
      expect(result.data!.feedback, 'Slope and intercept correct');
    });

    test('extracts grading JSON embedded in surrounding prose', () async {
      final client = _gradingClient(
        responseBody: _chatBody(
          'Sure! Here is my assessment: '
          '{"isCorrect": false, "score": 0.25, "feedback": "Wrong slope", "confidence": 0.8}',
        ),
      );

      final result = await client.evaluate(
        prompt: 'Grade this graph',
        mediaBase64: 'base64png',
        mediaType: 'image/png',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.isCorrect, isFalse);
      expect(result.data!.score, closeTo(0.25, 0.0001));
      expect(result.data!.confidence, closeTo(0.8, 0.0001));
    });

    test('clamps out-of-range score and confidence to 0..1', () async {
      final client = _gradingClient(
        responseBody: _chatBody(jsonEncode({
          'isCorrect': true,
          'score': 1.7,
          'feedback': 'ok',
          'confidence': -0.3,
        })),
      );

      final result = await client.evaluate(
        prompt: 'p',
        mediaBase64: 'b64',
        mediaType: 'image/png',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.score, 1.0);
      expect(result.data!.confidence, 0.0);
    });

    test('fails without a grade when the response is not grading JSON', () async {
      final client = _gradingClient(
        responseBody: _chatBody('I cannot grade this submission.'),
      );

      final result = await client.evaluate(
        prompt: 'p',
        mediaBase64: 'b64',
        mediaType: 'image/png',
      );

      expect(result.isFailure, isTrue);
    });

    test('fails when required grading fields are missing', () async {
      final client = _gradingClient(
        responseBody: _chatBody(jsonEncode({'feedback': 'no verdict'})),
      );

      final result = await client.evaluate(
        prompt: 'p',
        mediaBase64: 'b64',
        mediaType: 'image/png',
      );

      expect(result.isFailure, isTrue);
    });

    test('fails when the LLM call fails (no API key configured)', () async {
      final client = _gradingClient(
        responseBody: _chatBody('{}'),
        apiKey: '',
      );

      final result = await client.evaluate(
        prompt: 'p',
        mediaBase64: 'b64',
        mediaType: 'image/png',
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('API key'));
    });

    test('fails for empty media without calling the LLM', () async {
      final client = _gradingClient(responseBody: _chatBody('{}'));

      final result = await client.evaluate(
        prompt: 'p',
        mediaBase64: '   ',
        mediaType: 'image/png',
      );

      expect(result.isFailure, isTrue);
    });
  });

  group('parseGradingResponse', () {
    test('returns null for content without JSON', () {
      expect(parseGradingResponse('no json here'), isNull);
    });

    test('returns null for malformed JSON', () {
      expect(parseGradingResponse('{not json'), isNull);
    });

    test('accepts numeric booleans and string-encoded numbers', () {
      final evaluation = parseGradingResponse(
        '{"isCorrect": 1, "score": "0.5", "feedback": "ok", "confidence": "0.75"}',
      );

      expect(evaluation, isNotNull);
      expect(evaluation!.isCorrect, isTrue);
      expect(evaluation.score, closeTo(0.5, 0.0001));
      expect(evaluation.confidence, closeTo(0.75, 0.0001));
    });
  });

  group('WhisperTranscriptionService', () {
    test('returns the recognized transcript text', () async {
      final engine = _FakeAsrEngine(
        result: const TranscriptionResult(
          text: ' photosynthesis ',
          extractionMethod: 'whisper_api',
        ),
      );
      final service = WhisperTranscriptionService(asrEngine: engine);

      final result = await service.transcribe('/tmp/recording.m4a');

      expect(result.isSuccess, isTrue);
      expect(result.data, 'photosynthesis');
      expect(engine.lastFilePath, '/tmp/recording.m4a');
    });

    test('fails when the ASR engine is not configured', () async {
      final engine = _FakeAsrEngine(
        available: false,
        result: const TranscriptionResult(text: 'x', extractionMethod: 'noop'),
      );
      final service = WhisperTranscriptionService(asrEngine: engine);

      final result = await service.transcribe('/tmp/recording.m4a');

      expect(result.isFailure, isTrue);
      expect(engine.callCount, 0);
    });

    test('fails when transcription produces no text', () async {
      final engine = _FakeAsrEngine(
        result: const TranscriptionResult(
          text: '   ',
          extractionMethod: 'whisper_api',
        ),
      );
      final service = WhisperTranscriptionService(asrEngine: engine);

      final result = await service.transcribe('/tmp/recording.m4a');

      expect(result.isFailure, isTrue);
    });

    test('fails gracefully when the ASR engine throws', () async {
      final engine = _FakeAsrEngine(
        shouldThrow: true,
        result: const TranscriptionResult(text: 'x', extractionMethod: 'whisper_api'),
      );
      final service = WhisperTranscriptionService(asrEngine: engine);

      final result = await service.transcribe('/tmp/recording.m4a');

      expect(result.isFailure, isTrue);
      expect(result.error, contains('Whisper transcription failed'));
    });

    test('fails for empty audio without touching the engine', () async {
      final engine = _FakeAsrEngine(
        result: const TranscriptionResult(text: 'x', extractionMethod: 'whisper_api'),
      );
      final service = WhisperTranscriptionService(asrEngine: engine);

      final result = await service.transcribe('');

      expect(result.isFailure, isTrue);
      expect(engine.callCount, 0);
    });
  });
}

class _FakeChatHttpClient extends http.BaseClient {
  final String responseBody;
  final int statusCode;

  _FakeChatHttpClient({required this.responseBody, this.statusCode = 200});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(responseBody)),
      statusCode,
    );
  }
}

class _FakeAsrEngine extends AsrEngine {
  final bool available;
  final TranscriptionResult result;
  final bool shouldThrow;

  int callCount = 0;
  String? lastFilePath;

  _FakeAsrEngine({
    this.available = true,
    required this.result,
    this.shouldThrow = false,
  });

  @override
  bool get isAvailable => available;

  @override
  Future<TranscriptionResult> transcribeFile({
    required String filePath,
    String? language,
  }) async {
    callCount++;
    lastFilePath = filePath;
    if (shouldThrow) {
      throw Exception('ASR engine exploded');
    }
    return result;
  }
}

LlmGradingMultimodalClient _gradingClient({
  required String responseBody,
  int statusCode = 200,
  String apiKey = 'test-key',
  String modelId = 'test-model',
}) {
  return LlmGradingMultimodalClient(
    llmService: LlmService(
      config: LlmConfiguration(
        provider: LlmProvider.openRouter,
        apiKey: apiKey,
      ),
      httpClient: _FakeChatHttpClient(responseBody: responseBody, statusCode: statusCode),
    ),
    modelId: modelId,
  );
}

String _chatBody(String content) => jsonEncode({
      'choices': [
        {'message': {'content': content}},
      ],
      'usage': {'prompt_tokens': 10, 'completion_tokens': 5},
    });
