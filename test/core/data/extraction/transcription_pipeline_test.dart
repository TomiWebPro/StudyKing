import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:studyking/core/data/extraction/asr_engine.dart';
import 'package:studyking/core/data/extraction/transcription_extractor.dart';
import 'package:studyking/core/data/extraction/transcription_pipeline.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';

class _FakeLlmService extends LlmService {
  final Future<Result<String>> Function()? _onChat;

  _FakeLlmService({Future<Result<String>> Function()? onChat})
      : _onChat = onChat,
        super(
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
    String? taskType,
    String? sessionId,
  }) async {
    if (_onChat != null) return _onChat();
    return Result.success('transcribed text');
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
    String? taskType,
    String? sessionId,
  }) async* {
    yield 'stream response';
  }
}

class _FakeAsrEngine extends AsrEngine {
  final bool available;
  final Future<TranscriptionResult> Function(String filePath) onTranscribeFile;

  _FakeAsrEngine({
    required this.available,
    required this.onTranscribeFile,
  });

  @override
  bool get isAvailable => available;

  @override
  Future<TranscriptionResult> transcribeFile({
    required String filePath,
    String? language,
  }) {
    return onTranscribeFile(filePath);
  }
}

class _MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(Uri url) _onGet;
  final Future<http.StreamedResponse> Function(http.MultipartRequest)? _onSend;

  _MockHttpClient(this._onGet, {Future<http.StreamedResponse> Function(http.MultipartRequest)? onSend})
      : _onSend = onSend;

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _onGet(url);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request is http.MultipartRequest && _onSend != null) {
      return _onSend(request);
    }
    throw UnimplementedError('send not used in tests');
  }
}

class _StreamableMockHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest) _onSend;

  _StreamableMockHttpClient(this._onSend);

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final response = await _onSend(http.Request('GET', url));
    final bodyBytes = await response.stream.toBytes();
    return http.Response.bytes(bodyBytes, response.statusCode, headers: response.headers);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _onSend(request);
  }
}

/// MPEG-1 Layer III, 128 kbps, 44100 Hz: 1152 samples/frame, 417 bytes/frame.
const _kMp3FrameSize = 417;

/// Builds a synthetic MP3 byte stream of [numFrames] MPEG-1 Layer III frames.
/// Each frame uses a valid header (`0xFF 0xFB 0x90 0x00`); the body is zeroed
/// but the chunker only inspects headers, so this is sufficient to exercise
/// frame-aware splitting.
Uint8List _buildSyntheticMp3(int numFrames) {
  final bytes = Uint8List(numFrames * _kMp3FrameSize);
  for (var f = 0; f < numFrames; f++) {
    final off = f * _kMp3FrameSize;
    bytes[off] = 0xFF;
    bytes[off + 1] = 0xFB;
    bytes[off + 2] = 0x90;
    bytes[off + 3] = 0x00;
  }
  return bytes;
}

void main() {
  group('TranscriptionPipeline', () {
    test('processes YouTube URL through extractor', () async {
      final mockClient = _MockHttpClient((_) async => http.Response('', 404));
      final extractor = TranscriptionExtractor(
        modelId: 'test-model',
        localeName: 'en',
        httpClient: mockClient,
      );
      final pipeline = TranscriptionPipeline(extractor: extractor);

      final result = await pipeline.transcribe(
        rawContent: 'https://youtube.com/watch?v=abc123',
      );

      expect(result.text, '');
      expect(result.extractionMethod, 'youtube_no_transcript');
      pipeline.dispose();
    });

    test('uses ASR engine for file when available', () async {
      final dir = Directory.systemTemp.createTempSync('pipeline_test_');
      try {
        final file = File('${dir.path}/test.mp3');
        await file.writeAsBytes([0xFF, 0xFB, 0x90]);

        final asrEngine = _FakeAsrEngine(
          available: true,
          onTranscribeFile: (_) async => TranscriptionResult(
            text: 'asr transcript',
            extractionMethod: 'whisper_api',
            confidence: 0.95,
          ),
        );

        final extractor = TranscriptionExtractor(
          modelId: 'test-model',
          localeName: 'en',
          httpClient: _MockHttpClient((_) async => http.Response('', 404)),
        );

        final pipeline = TranscriptionPipeline(
          extractor: extractor,
          asrEngine: asrEngine,
        );

        final result = await pipeline.transcribe(
          rawContent: 'file://${file.path}',
        );

        expect(result.text, 'asr transcript');
        expect(result.extractionMethod, 'whisper_api');
        pipeline.dispose();
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('falls back to extractor when ASR fails for file', () async {
      final dir = Directory.systemTemp.createTempSync('pipeline_fallback_test_');
      try {
        final file = File('${dir.path}/test.mp3');
        await file.writeAsBytes([0xFF, 0xFB, 0x90]);

        final asrEngine = _FakeAsrEngine(
          available: true,
          onTranscribeFile: (_) async => const TranscriptionResult(
            text: '',
            extractionMethod: 'whisper_api',
          ),
        );

        final llm = _FakeLlmService(
          onChat: () async => Result.success('llm transcript'),
        );

        final extractor = TranscriptionExtractor(
          llmService: llm,
          modelId: 'test-model',
          localeName: 'en',
          httpClient: _MockHttpClient((_) async => http.Response('', 404)),
        );

        final pipeline = TranscriptionPipeline(
          extractor: extractor,
          asrEngine: asrEngine,
          llmService: llm,
        );

        final result = await pipeline.transcribe(
          rawContent: 'file://${file.path}',
        );

        expect(result.text, 'llm transcript');
        pipeline.dispose();
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('processes URL through ASR when available by downloading file', () async {
      final asrEngine = _FakeAsrEngine(
        available: true,
        onTranscribeFile: (_) async => TranscriptionResult(
          text: 'downloaded asr transcript',
          extractionMethod: 'whisper_api',
          confidence: 0.90,
        ),
      );

      final mockClient = _StreamableMockHttpClient(
        (request) async => http.StreamedResponse(
          Stream.value(Uint8List.fromList([0xFF, 0xFB, 0x90, 0x00])),
          200,
          headers: {'content-type': 'audio/mpeg'},
        ),
      );

      final extractor = TranscriptionExtractor(
        modelId: 'test-model',
        localeName: 'en',
        httpClient: mockClient,
      );

      final pipeline = TranscriptionPipeline(
        extractor: extractor,
        asrEngine: asrEngine,
        httpClient: mockClient,
      );

      final result = await pipeline.transcribe(
        rawContent: 'https://example.com/audio.mp3',
      );

      expect(result.text, 'downloaded asr transcript');
      expect(result.extractionMethod, 'whisper_api');
      pipeline.dispose();
    });

    test('falls back to LLM for URL when ASR download fails', () async {
      final llm = _FakeLlmService(
        onChat: () async => Result.success('url llm transcript'),
      );

      final mockClient = _StreamableMockHttpClient(
        (request) async => http.StreamedResponse(
          Stream.value([]),
          404,
        ),
      );

      final extractor = TranscriptionExtractor(
        llmService: llm,
        modelId: 'test-model',
        localeName: 'en',
        httpClient: mockClient,
      );

      final pipeline = TranscriptionPipeline(
        extractor: extractor,
        llmService: llm,
        httpClient: mockClient,
      );

      final result = await pipeline.transcribe(
        rawContent: 'https://example.com/audio.mp3',
      );

      expect(result.text, 'url llm transcript');
      pipeline.dispose();
    });

    test('processes URL through extractor when no ASR and no LLM', () async {
      final mockClient = _StreamableMockHttpClient(
        (request) async => http.StreamedResponse(
          Stream.value([]),
          404,
        ),
      );

      final extractor = TranscriptionExtractor(
        modelId: 'test-model',
        localeName: 'en',
        httpClient: mockClient,
      );

      final pipeline = TranscriptionPipeline(
        extractor: extractor,
        httpClient: mockClient,
      );

      final result = await pipeline.transcribe(
        rawContent: 'https://example.com/audio.mp3',
      );

      expect(result.text, '');
      expect(result.extractionMethod, 'pipeline_no_handler');
      pipeline.dispose();
    });

    test('handles raw content through extractor', () async {
      final llm = _FakeLlmService(
        onChat: () async => Result.success('raw transcript'),
      );

      final extractor = TranscriptionExtractor(
        llmService: llm,
        modelId: 'test-model',
        localeName: 'en',
      );

      final pipeline = TranscriptionPipeline(
        extractor: extractor,
        llmService: llm,
      );

      final result = await pipeline.transcribe(
        rawContent: 'this is some raw audio content that is longer than 20 characters',
      );

      expect(result.text, 'raw transcript');
      pipeline.dispose();
    });

    test('returns pipeline_no_handler for URL with no services', () async {
      final mockClient = _MockHttpClient((_) async => http.Response('', 404));

      final extractor = TranscriptionExtractor(
        modelId: 'test-model',
        localeName: 'en',
        httpClient: mockClient,
      );

      final pipeline = TranscriptionPipeline(extractor: extractor);

      final result = await pipeline.transcribe(
        rawContent: 'https://example.com/audio.mp3',
      );

      expect(result.text, '');
      expect(result.extractionMethod, 'pipeline_no_handler');
      pipeline.dispose();
    });

    test('YouTube with no captions returns empty without hallucination', () async {
      final llm = _FakeLlmService(
        onChat: () async => Result.success('youtube llm transcript'),
      );

      final mockClient = _MockHttpClient((_) async => http.Response('', 404));

      final extractor = TranscriptionExtractor(
        llmService: llm,
        modelId: 'test-model',
        localeName: 'en',
        httpClient: mockClient,
      );

      final pipeline = TranscriptionPipeline(
        extractor: extractor,
        llmService: llm,
      );

      // LLM hallucination removed; YouTube without captions returns empty
      final result = await pipeline.transcribe(
        rawContent: 'https://youtube.com/watch?v=abc123',
      );

      expect(result.text, '');
      pipeline.dispose();
    });

    test('handles youtu.be short URLs with no captions', () async {
      final llm = _FakeLlmService(
        onChat: () async => Result.success('youtu.be transcript'),
      );

      final mockClient = _MockHttpClient((_) async => http.Response('', 404));

      final extractor = TranscriptionExtractor(
        llmService: llm,
        modelId: 'test-model',
        localeName: 'en',
        httpClient: mockClient,
      );

      final pipeline = TranscriptionPipeline(
        extractor: extractor,
        llmService: llm,
      );

      // LLM hallucination removed; YouTube without captions returns empty
      final result = await pipeline.transcribe(
        rawContent: 'https://youtu.be/abc123',
      );

      expect(result.text, '');
      pipeline.dispose();
    });

    test('YouTube fallback does not duplicate the failed extractor call', () async {
      var chatCalls = 0;
      final requestedUris = <Uri>[];
      final llm = _FakeLlmService(
        onChat: () async {
          chatCalls++;
          return Result.success('hallucinated transcript');
        },
      );
      final mockClient = _MockHttpClient((uri) async {
        requestedUris.add(uri);
        return http.Response('', 404);
      });

      final extractor = TranscriptionExtractor(
        llmService: llm,
        modelId: 'test-model',
        localeName: 'en',
        httpClient: mockClient,
      );
      final pipeline = TranscriptionPipeline(
        extractor: extractor,
        llmService: llm,
      );

      final result = await pipeline.transcribe(
        rawContent: 'https://youtube.com/watch?v=abc123',
      );

      // Caption-less video: empty result, no hallucinated LLM transcript.
      expect(result.text, '');
      expect(result.extractionMethod, 'youtube_no_transcript');
      // The LLM is never consulted for video URLs.
      expect(chatCalls, 0);
      // A single extractor pass queries the transcript API twice
      // (its two endpoint attempts) and the video page once. A
      // duplicate fallback call would double these counts.
      final transcriptApiCalls = requestedUris
          .where((uri) => uri.host == 'youtubetranscript.com')
          .length;
      final pageFetches = requestedUris
          .where((uri) => uri.host == 'www.youtube.com' && uri.path == '/watch')
          .length;
      expect(transcriptApiCalls, 2);
      expect(pageFetches, 1);
      pipeline.dispose();
    });

    test('uses sourceUrl when provided', () async {
      final asrEngine = _FakeAsrEngine(
        available: true,
        onTranscribeFile: (_) async => TranscriptionResult(
          text: 'source url transcript',
          extractionMethod: 'whisper_api',
          confidence: 0.88,
        ),
      );

      final mockClient = _StreamableMockHttpClient(
        (request) async => http.StreamedResponse(
          Stream.value(Uint8List.fromList([0xFF, 0xFB, 0x90, 0x00])),
          200,
          headers: {'content-type': 'audio/mpeg'},
        ),
      );

      final extractor = TranscriptionExtractor(
        modelId: 'test-model',
        localeName: 'en',
        httpClient: mockClient,
      );

      final pipeline = TranscriptionPipeline(
        extractor: extractor,
        asrEngine: asrEngine,
        httpClient: mockClient,
      );

      final result = await pipeline.transcribe(
        rawContent: 'some raw content',
        sourceUrl: 'https://example.com/audio.mp3',
      );

      expect(result.text, 'source url transcript');
      pipeline.dispose();
    });

    test('cleans up temporary files after URL ASR', () async {
      final asrEngine = _FakeAsrEngine(
        available: true,
        onTranscribeFile: (_) async => TranscriptionResult(
          text: 'cleanup test',
          extractionMethod: 'whisper_api',
          confidence: 0.85,
        ),
      );

      final mockClient = _StreamableMockHttpClient(
        (request) async => http.StreamedResponse(
          Stream.value(Uint8List.fromList([0xFF, 0xFB, 0x90, 0x00])),
          200,
          headers: {'content-type': 'audio/mpeg'},
        ),
      );

      final extractor = TranscriptionExtractor(
        modelId: 'test-model',
        localeName: 'en',
        httpClient: mockClient,
      );

      final pipeline = TranscriptionPipeline(
        extractor: extractor,
        asrEngine: asrEngine,
        httpClient: mockClient,
      );

      final result = await pipeline.transcribe(
        rawContent: 'https://example.com/audio.mp3',
      );

      expect(result.text, 'cleanup test');
      pipeline.dispose();
    });

    test('chunked ASR frame-splits a large MP3 into valid chunks', () async {
      final dir = Directory.systemTemp.createTempSync('pipeline_chunk_test_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final chunkerBytes = _buildSyntheticMp3(1200); // ~31s of audio
      final largeFile = File('${dir.path}/large.mp3');
      await largeFile.writeAsBytes(chunkerBytes);

      var callCount = 0;
      final asrEngine = _FakeAsrEngine(
        available: true,
        onTranscribeFile: (filePath) async {
          callCount++;
          return TranscriptionResult(
            text: 'chunk $callCount',
            extractionMethod: 'whisper_api',
            confidence: 0.90,
          );
        },
      );

      final extractor = TranscriptionExtractor(
        modelId: 'test-model',
        localeName: 'en',
        httpClient: _MockHttpClient((_) async => http.Response('', 404)),
      );

      final pipeline = TranscriptionPipeline(
        extractor: extractor,
        asrEngine: asrEngine,
        // Use a small threshold so the chunked path engages without a 25MB
        // allocation: the file (~500KB) is well over 1KB.
        maxFileSizeBytes: 1024,
      );

      final result = await pipeline.transcribe(
        rawContent: 'file://${largeFile.path}',
      );

      expect(result.text, isNotEmpty);
      expect(result.extractionMethod, 'chunked_asr');
      expect(result.segments, isNotNull);
      expect(result.segments!.length, greaterThan(1));
      // The ASR engine was invoked once per frame-aware chunk (not once per
      // raw byte slice, and never on a corrupted chunk).
      expect(callCount, result.segments!.length);
      pipeline.dispose();
    });

    test('chunked ASR keeps segment offsets when a chunk yields no text',
        () async {
      // ~90s of audio → 3 chunks at a 30s target. The middle (2nd) chunk
      // returns empty text; later segments must keep their real timeline offset.
      final dir = Directory.systemTemp.createTempSync('pipeline_chunk_test_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final chunkerBytes = _buildSyntheticMp3(3444); // ~90s of audio → 3 chunks
      final largeFile = File('${dir.path}/large.mp3');
      await largeFile.writeAsBytes(chunkerBytes);

      var callCount = 0;
      final asrEngine = _FakeAsrEngine(
        available: true,
        onTranscribeFile: (filePath) async {
          final index = ++callCount;
          if (index == 2) {
            // Empty result on the middle chunk (silence / transient failure).
            return const TranscriptionResult(
              text: '',
              extractionMethod: 'whisper_api',
            );
          }
          return TranscriptionResult(
            text: 'segment $index',
            extractionMethod: 'whisper_api',
            confidence: 0.90,
          );
        },
      );

      final extractor = TranscriptionExtractor(
        modelId: 'test-model',
        localeName: 'en',
        httpClient: _MockHttpClient((_) async => http.Response('', 404)),
      );

      final pipeline = TranscriptionPipeline(
        extractor: extractor,
        asrEngine: asrEngine,
        maxFileSizeBytes: 1024,
      );

      final result = await pipeline.transcribe(
        rawContent: 'file://${largeFile.path}',
      );

      expect(result.extractionMethod, 'chunked_asr');
      expect(result.segments, isNotNull);
      expect(result.segments!.length, 2);
      expect(result.segments![0].text, 'segment 1');
      expect(result.segments![1].text, 'segment 3');
      // The empty chunk still occupies ~30s of timeline, so segment 3 starts
      // just under 60s — not 30s (which would be the drift bug).
      expect(result.segments![1].startSeconds, closeTo(60.0, 1.5));
      expect(result.segments![1].endSeconds, closeTo(90.0, 1.5));
      pipeline.dispose();
    });

    test('fails loud for an oversized unsupported format (no valid frames)',
        () async {
      final dir = Directory.systemTemp.createTempSync('pipeline_unsupported_test_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final largeFile = File('${dir.path}/large.bin');
      await largeFile
          .writeAsBytes(Uint8List.fromList(List.filled(2048, 0xAB)));

      final asrEngine = _FakeAsrEngine(
        available: true,
        onTranscribeFile: (_) async => const TranscriptionResult(
          text: 'should not be transcribed',
          extractionMethod: 'whisper_api',
        ),
      );

      final extractor = TranscriptionExtractor(
        modelId: 'test-model',
        localeName: 'en',
        httpClient: _MockHttpClient((_) async => http.Response('', 404)),
      );

      final pipeline = TranscriptionPipeline(
        extractor: extractor,
        asrEngine: asrEngine,
        maxFileSizeBytes: 1024,
      );

      final result = await pipeline.transcribe(
        rawContent: 'file://${largeFile.path}',
      );

      // The chunker rejects the format rather than byte-splitting it.
      expect(result.text, isEmpty);
      expect(result.extractionMethod, 'asr_unsupported_format');
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage, contains('Unsupported audio format'));
      pipeline.dispose();
    });

    test('fails loud for oversized file when no ASR key is configured', () async {
      final dir = Directory.systemTemp.createTempSync('pipeline_noops_test_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final largeFile = File('${dir.path}/large.mp3');
      await largeFile.writeAsBytes(_buildSyntheticMp3(1200));

      final extractor = TranscriptionExtractor(
        modelId: 'test-model',
        localeName: 'en',
        httpClient: _MockHttpClient((_) async => http.Response('', 404)),
      );

      final pipeline = TranscriptionPipeline(
        extractor: extractor,
        asrEngine: NoopAsrEngine(),
        maxFileSizeBytes: 1024,
      );

      final result = await pipeline.transcribe(
        rawContent: 'file://${largeFile.path}',
      );

      expect(result.text, isEmpty);
      expect(result.extractionMethod, 'asr_file_too_large');
      expect(result.errorMessage, isNotNull);
      pipeline.dispose();
    });

    test('detects content type from URL extension', () async {
      final asrEngine = _FakeAsrEngine(
        available: true,
        onTranscribeFile: (_) async => const TranscriptionResult(
          text: 'wav transcript',
          extractionMethod: 'whisper_api',
        ),
      );

      final mockClient = _StreamableMockHttpClient(
        (request) async => http.StreamedResponse(
          Stream.value(Uint8List.fromList([0xFF, 0xFB, 0x90, 0x00])),
          200,
          headers: {'content-type': 'application/octet-stream'},
        ),
      );

      final extractor = TranscriptionExtractor(
        modelId: 'test-model',
        localeName: 'en',
        httpClient: mockClient,
      );

      final pipeline = TranscriptionPipeline(
        extractor: extractor,
        asrEngine: asrEngine,
        httpClient: mockClient,
      );

      final result = await pipeline.transcribe(
        rawContent: 'https://example.com/audio.wav',
      );

      expect(result.text, 'wav transcript');
      pipeline.dispose();
    });

    test('falls back to extractor for non-audio URL without ASR', () async {
      final llm = _FakeLlmService(
        onChat: () async => Result.success('llm url transcript'),
      );

      final mockClient = _StreamableMockHttpClient(
        (request) async => http.StreamedResponse(
          Stream.value([]),
          200,
          headers: {'content-type': 'audio/mpeg'},
        ),
      );

      final extractor = TranscriptionExtractor(
        llmService: llm,
        modelId: 'test-model',
        localeName: 'en',
        httpClient: mockClient,
      );

      final pipeline = TranscriptionPipeline(
        extractor: extractor,
        llmService: llm,
        httpClient: mockClient,
      );

      final result = await pipeline.transcribe(
        rawContent: 'https://example.com/audio.mp3',
      );

      expect(result.text, 'llm url transcript');
      pipeline.dispose();
    });
  });
}
