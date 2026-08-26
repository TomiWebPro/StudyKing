import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/errors/result.dart';
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
}
