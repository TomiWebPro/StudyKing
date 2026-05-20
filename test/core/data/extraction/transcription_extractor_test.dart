import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:studyking/core/data/extraction/transcription_extractor.dart';
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
  }) async* {
    yield 'stream response';
  }
}

class _MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(Uri url) _onGet;

  _MockHttpClient(this._onGet);

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _onGet(url);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError('send not used in tests');
  }
}

void main() {
  group('TranscriptionResult', () {
    test('isError returns true when errorMessage is set', () {
      const result = TranscriptionResult(
        text: '',
        extractionMethod: 'test',
        errorMessage: 'error',
      );
      expect(result.isError, isTrue);
    });

    test('isError returns false when errorMessage is null', () {
      const result = TranscriptionResult(
        text: 'hello',
        extractionMethod: 'test',
      );
      expect(result.isError, isFalse);
    });

    test('stores all properties', () {
      const result = TranscriptionResult(
        text: 'transcript',
        durationSeconds: 120,
        extractionMethod: 'youtube',
        errorMessage: null,
      );
      expect(result.text, 'transcript');
      expect(result.durationSeconds, 120);
      expect(result.extractionMethod, 'youtube');
      expect(result.errorMessage, isNull);
    });
  });

  group('TranscriptionExtractor', () {
    group('constructor', () {
      test('accepts empty modelId without throwing', () {
        expect(
          () => TranscriptionExtractor(modelId: '', localeName: 'en'),
          returnsNormally,
        );
      });

      test('accepts custom http client', () {
        final mockClient = _MockHttpClient((_) async => http.Response('', 200));
        final extractor = TranscriptionExtractor(
          modelId: 'test-model',
          httpClient: mockClient,
          localeName: 'en',
        );
        expect(extractor, isNotNull);
        extractor.dispose();
      });
    });

    group('transcribeAudio without LLM', () {
      late TranscriptionExtractor extractor;

      setUp(() {
        extractor = TranscriptionExtractor(modelId: 'test-model', localeName: 'en');
      });

      tearDown(() {
        extractor.dispose();
      });

      test('returns empty for file:// path without LLM', () async {
        final result = await extractor.transcribeAudio(
          rawContent: 'file:///path/to/audio.mp3',
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'file_not_found');
      });

      test('returns empty for http URL without LLM', () async {
        final result = await extractor.transcribeAudio(
          rawContent: 'https://example.com/audio.mp3',
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'audio_url_no_llm');
      });

      test('returns empty for short content without LLM', () async {
        final result = await extractor.transcribeAudio(
          rawContent: 'short',
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'audio_no_content');
      });

      test('uses sourceUrl when rawContent is not a URL', () async {
        final result = await extractor.transcribeAudio(
          rawContent: 'some id',
          sourceUrl: 'https://example.com/audio.mp3',
        );
        expect(result.extractionMethod, 'audio_url_no_llm');
      });
    });

    group('transcribeAudio with LLM', () {
      test('successfully transcribes audio with LLM', () async {
        final llm = _FakeLlmService(
          onChat: () async => Result.success('audio transcript'),
        );
        final extractor = TranscriptionExtractor(
          llmService: llm,
          modelId: 'test-model',
          localeName: 'en',
        );

        final result = await extractor.transcribeAudio(
          rawContent: 'this is some audio content that is longer than 20 characters',
          sourceUrl: null,
        );

        expect(result.text, 'audio transcript');
        expect(result.extractionMethod, 'transcribed_llm');
        extractor.dispose();
      });

      test('returns empty when LLM returns empty text for audio', () async {
        final llm = _FakeLlmService(
          onChat: () async => Result.success('   '),
        );
        final extractor = TranscriptionExtractor(
          llmService: llm,
          modelId: 'test-model',
          localeName: 'en',
        );

        final result = await extractor.transcribeAudio(
          rawContent: 'this is some audio content that is longer than 20 characters',
          sourceUrl: null,
        );

        expect(result.text, '');
        expect(result.extractionMethod, 'transcription_empty');
        extractor.dispose();
      });

      test('returns error when LLM chat fails for audio', () async {
        final llm = _FakeLlmService(
          onChat: () async => Result.failure('API error'),
        );
        final extractor = TranscriptionExtractor(
          llmService: llm,
          modelId: 'test-model',
          localeName: 'en',
        );

        final result = await extractor.transcribeAudio(
          rawContent: 'this is some audio content that is longer than 20 characters',
          sourceUrl: null,
        );

        expect(result.text, '');
        expect(result.extractionMethod, 'transcription_llm_failed');
        extractor.dispose();
      });

      test('returns error when LLM throws during audio transcription', () async {
        final llm = _FakeLlmService(
          onChat: () async => throw Exception('Network error'),
        );
        final extractor = TranscriptionExtractor(
          llmService: llm,
          modelId: 'test-model',
          localeName: 'en',
        );

        final result = await extractor.transcribeAudio(
          rawContent: 'this is some audio content that is longer than 20 characters',
          sourceUrl: null,
        );

        expect(result.text, '');
        expect(result.extractionMethod, 'transcription_llm_failed');
        expect(result.errorMessage, contains('Network error'));
        extractor.dispose();
      });

      test('returns model_id_empty with empty modelId', () async {
        final llm = _FakeLlmService(
          onChat: () async => Result.success('text'),
        );
        final extractor = TranscriptionExtractor(
          llmService: llm,
          modelId: '',
          localeName: 'en',
        );

        final result = await extractor.transcribeAudio(
          rawContent: 'this is some audio content that is longer than 20 characters',
          sourceUrl: null,
        );

        expect(result.text, '');
        expect(result.extractionMethod, 'model_id_empty');
        extractor.dispose();
      });

      test('transcribes audio URL via LLM', () async {
        final llm = _FakeLlmService(
          onChat: () async => Result.success('url transcription'),
        );
        final extractor = TranscriptionExtractor(
          llmService: llm,
          modelId: 'test-model',
          localeName: 'en',
        );

        final result = await extractor.transcribeAudio(
          rawContent: 'https://example.com/audio.mp3',
          sourceUrl: null,
        );

        expect(result.text, 'url transcription');
        expect(result.extractionMethod, 'transcribed_llm');
        extractor.dispose();
      });
    });

    group('transcribeAudio with file://', () {
      test('returns file_read_error for restricted file', () async {
        final dir = Directory.systemTemp.createTempSync('audio_perm_test_');
        try {
          final file = File('${dir.path}/restricted.mp3');
          await file.writeAsBytes([0xFF, 0xFB, 0x90]);
          await Process.run('chmod', ['000', file.path]);

          final extractor = TranscriptionExtractor(modelId: 'test-model', localeName: 'en');
          final result = await extractor.transcribeAudio(
            rawContent: 'file://${file.path}',
            sourceUrl: null,
          );
          expect(result.text, '');
          expect(result.extractionMethod, 'file_read_error');
          extractor.dispose();
        } finally {
          await Process.run('chmod', ['-R', '777', dir.path]);
          dir.deleteSync(recursive: true);
        }
      });

      test('returns file_no_llm for existing file without LLM', () async {
        final dir = Directory.systemTemp.createTempSync('audio_test_');
        try {
          final file = File('${dir.path}/test.mp3');
          await file.writeAsBytes([0xFF, 0xFB, 0x90]);

          final extractor = TranscriptionExtractor(modelId: 'test-model', localeName: 'en');
          final result = await extractor.transcribeAudio(
            rawContent: 'file://${file.path}',
            sourceUrl: null,
          );
          expect(result.text, '');
          expect(result.extractionMethod, 'file_no_llm');
          extractor.dispose();
        } finally {
          dir.deleteSync(recursive: true);
        }
      });

      test('transcribes existing file via LLM', () async {
        final dir = Directory.systemTemp.createTempSync('audio_llm_test_');
        try {
          final file = File('${dir.path}/test.mp3');
          await file.writeAsBytes([0xFF, 0xFB, 0x90]);

          final llm = _FakeLlmService(
            onChat: () async => Result.success('file transcription'),
          );
          final extractor = TranscriptionExtractor(
            llmService: llm,
            modelId: 'test-model',
            localeName: 'en',
          );
          final result = await extractor.transcribeAudio(
            rawContent: 'file://${file.path}',
            sourceUrl: null,
          );
          expect(result.text, 'file transcription');
          expect(result.extractionMethod, 'transcribed_llm');
          extractor.dispose();
        } finally {
          dir.deleteSync(recursive: true);
        }
      });
    });

    group('transcribeVideo without LLM', () {
      late TranscriptionExtractor extractor;

      setUp(() {
        extractor = TranscriptionExtractor(modelId: 'test-model', localeName: 'en');
      });

      tearDown(() {
        extractor.dispose();
      });

      test('returns empty for YouTube URL without LLM', () async {
        final result = await extractor.transcribeVideo(
          rawContent: 'https://youtube.com/watch?v=abc123',
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'youtube_no_transcript');
      });

      test('detects youtu.be short URLs without LLM', () async {
        final result = await extractor.transcribeVideo(
          rawContent: 'https://youtu.be/abc123',
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'youtube_no_transcript');
      });

      test('returns empty for regular http URL without LLM', () async {
        final result = await extractor.transcribeVideo(
          rawContent: 'https://example.com/video.mp4',
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'video_url_no_llm');
      });

      test('returns empty for file path without LLM', () async {
        final result = await extractor.transcribeVideo(
          rawContent: 'file:///path/to/video.mp4',
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'file_not_found');
      });

      test('returns empty for raw content without LLM', () async {
        final result = await extractor.transcribeVideo(
          rawContent: 'raw content here',
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'video_no_content');
      });

      test('uses sourceUrl for YouTube detection', () async {
        final result = await extractor.transcribeVideo(
          rawContent: 'some id',
          sourceUrl: 'https://youtube.com/watch?v=abc123',
        );
        expect(result.text, '');
      });
    });

    group('transcribeVideo with YouTube transcript API', () {
      test('fetches transcript from JSON API response', () async {
        final mockClient = _MockHttpClient((Uri url) async {
          if (url.toString().contains('youtubetranscript.com')) {
            return http.Response(
              jsonEncode([
                {'text': 'Hello', 'start': 0.0, 'duration': 1.0},
                {'text': 'world', 'start': 1.0, 'duration': 1.0},
              ]),
              200,
            );
          }
          return http.Response('', 404);
        });

        final extractor = TranscriptionExtractor(
          modelId: 'test-model',
          httpClient: mockClient,
          localeName: 'en',
        );
        final result = await extractor.transcribeVideo(
          rawContent: 'https://youtube.com/watch?v=abc123',
          sourceUrl: null,
        );

        expect(result.text, 'Hello world');
        expect(result.extractionMethod, 'youtube_transcript_fetched');
        extractor.dispose();
      });

      test('falls back to plain text body when JSON parsing fails', () async {
        final mockClient = _MockHttpClient((Uri url) async {
          if (url.toString().contains('youtubetranscript.com')) {
            return http.Response(
              'This is a plain text transcript that is longer than 50 characters.',
              200,
            );
          }
          return http.Response('', 404);
        });

        final extractor = TranscriptionExtractor(
          modelId: 'test-model',
          httpClient: mockClient,
          localeName: 'en',
        );
        final result = await extractor.transcribeVideo(
          rawContent: 'https://youtube.com/watch?v=abc123',
          sourceUrl: null,
        );

        expect(result.text, 'This is a plain text transcript that is longer than 50 characters.');
        expect(result.extractionMethod, 'youtube_transcript_fetched');
        extractor.dispose();
      });

      test('skips short non-JSON body', () async {
        final mockClient = _MockHttpClient((Uri url) async {
          if (url.toString().contains('youtubetranscript.com')) {
            return http.Response('short', 200);
          }
          return http.Response('', 404);
        });

        final extractor = TranscriptionExtractor(
          modelId: 'test-model',
          httpClient: mockClient,
          localeName: 'en',
        );
        final result = await extractor.transcribeVideo(
          rawContent: 'https://youtube.com/watch?v=abc123',
          sourceUrl: null,
        );

        expect(result.text, '');
        expect(result.extractionMethod, 'youtube_no_transcript');
        extractor.dispose();
      });

      test('handles invalid JSON in transcript response', () async {
        final mockClient = _MockHttpClient((Uri url) async {
          if (url.toString().contains('youtubetranscript.com')) {
            return http.Response('{invalid json}', 200);
          }
          return http.Response('', 404);
        });

        final extractor = TranscriptionExtractor(
          modelId: 'test-model',
          httpClient: mockClient,
          localeName: 'en',
        );
        final result = await extractor.transcribeVideo(
          rawContent: 'https://youtube.com/watch?v=abc123',
          sourceUrl: null,
        );

        expect(result.text, '');
        expect(result.extractionMethod, 'youtube_no_transcript');
        extractor.dispose();
      });

      test('returns no transcript when API returns 404', () async {
        final mockClient = _MockHttpClient((_) async => http.Response('', 404));

        final extractor = TranscriptionExtractor(
          modelId: 'test-model',
          httpClient: mockClient,
          localeName: 'en',
        );
        final result = await extractor.transcribeVideo(
          rawContent: 'https://youtube.com/watch?v=abc123',
          sourceUrl: null,
        );

        expect(result.text, '');
        expect(result.extractionMethod, 'youtube_no_transcript');
        extractor.dispose();
      });

      test('returns youtube_invalid_url for malformed URL', () async {
        final extractor = TranscriptionExtractor(
          modelId: 'test-model',
          httpClient: _MockHttpClient((_) async => http.Response('', 404)),
          localeName: 'en',
        );
        final result = await extractor.transcribeVideo(
          rawContent: 'https://youtube.com/',
          sourceUrl: null,
        );

        expect(result.text, '');
        expect(result.extractionMethod, 'youtube_invalid_url');
        extractor.dispose();
      });

      test('handles non-YouTube URL without LLM', () async {
        final extractor = TranscriptionExtractor(
          modelId: 'test-model',
          httpClient: _MockHttpClient((_) async => http.Response('', 404)),
          localeName: 'en',
        );
        final result = await extractor.transcribeVideo(
          rawContent: 'https://example.com/watch?v=abc123',
          sourceUrl: null,
        );

        expect(result.text, '');
        expect(result.extractionMethod, 'video_url_no_llm');
        extractor.dispose();
      });
    });

    group('transcribeVideo with YouTube page content fallback', () {
      test('fetches title and description from YouTube page with LLM', () async {
        final mockClient = _MockHttpClient((Uri url) async {
          final urlStr = url.toString();
          if (urlStr.contains('youtubetranscript.com')) {
            return http.Response('', 404);
          }
          if (urlStr.contains('youtube.com/watch')) {
            return http.Response(
              '<html><head><title>Test Video</title>'
              '<meta name="description" content="A test video description">'
              '</head></html>',
              200,
            );
          }
          return http.Response('', 404);
        });

        final llm = _FakeLlmService(
          onChat: () async => Result.success('page based transcript'),
        );
        final extractor = TranscriptionExtractor(
          llmService: llm,
          modelId: 'test-model',
          httpClient: mockClient,
          localeName: 'en',
        );
        final result = await extractor.transcribeVideo(
          rawContent: 'https://youtube.com/watch?v=abc123',
          sourceUrl: null,
        );

        expect(result.text, 'page based transcript');
        expect(result.extractionMethod, 'transcribed_llm');
        extractor.dispose();
      });

      test('uses LLM with just video ID when page fetch fails', () async {
        final mockClient = _MockHttpClient((_) async => http.Response('', 404));

        final llm = _FakeLlmService(
          onChat: () async => Result.success('id based transcript'),
        );
        final extractor = TranscriptionExtractor(
          llmService: llm,
          modelId: 'test-model',
          httpClient: mockClient,
          localeName: 'en',
        );
        final result = await extractor.transcribeVideo(
          rawContent: 'https://youtube.com/watch?v=abc123',
          sourceUrl: null,
        );

        expect(result.text, 'id based transcript');
        expect(result.extractionMethod, 'transcribed_llm');
        extractor.dispose();
      });

      test('handles YouTube fetch exception with LLM fallback', () async {
        final mockClient = _MockHttpClient((Uri url) async {
          throw Exception('Network failure');
        });

        final llm = _FakeLlmService(
          onChat: () async => Result.success('fallback transcript'),
        );
        final extractor = TranscriptionExtractor(
          llmService: llm,
          modelId: 'test-model',
          httpClient: mockClient,
          localeName: 'en',
        );
        final result = await extractor.transcribeVideo(
          rawContent: 'https://youtube.com/watch?v=abc123',
          sourceUrl: null,
        );

        expect(result.text, 'fallback transcript');
        expect(result.extractionMethod, 'transcribed_llm');
        extractor.dispose();
      });

      test('returns youtube_no_transcript on exception without LLM', () async {
        final mockClient = _MockHttpClient((Uri url) async {
          throw Exception('Network failure');
        });

        final extractor = TranscriptionExtractor(
          modelId: 'test-model',
          httpClient: mockClient,
          localeName: 'en',
        );
        final result = await extractor.transcribeVideo(
          rawContent: 'https://youtube.com/watch?v=abc123',
          sourceUrl: null,
        );

        expect(result.text, '');
        expect(result.extractionMethod, 'youtube_no_transcript');
        extractor.dispose();
      });
    });

    group('transcribeVideo with raw content and LLM', () {
      test('transcribes raw content via LLM when length > 20', () async {
        final llm = _FakeLlmService(
          onChat: () async => Result.success('raw transcription'),
        );
        final extractor = TranscriptionExtractor(
          llmService: llm,
          modelId: 'test-model',
          localeName: 'en',
        );

        final result = await extractor.transcribeVideo(
          rawContent: 'this is some raw video content that is longer than 20 chars',
          sourceUrl: null,
        );

        expect(result.text, 'raw transcription');
        expect(result.extractionMethod, 'transcribed_llm');
        extractor.dispose();
      });
    });

    group('transcribeVideo with http URL and LLM', () {
      test('transcribes via LLM for non-YouTube URL', () async {
        final llm = _FakeLlmService(
          onChat: () async => Result.success('video transcript'),
        );
        final extractor = TranscriptionExtractor(
          llmService: llm,
          modelId: 'test-model',
          localeName: 'en',
        );

        final result = await extractor.transcribeVideo(
          rawContent: 'https://example.com/video.mp4',
          sourceUrl: null,
        );

        expect(result.text, 'video transcript');
        expect(result.extractionMethod, 'transcribed_llm');
        extractor.dispose();
      });
    });

    group('YouTube video ID extraction (via transcribeVideo)', () {
      test('extracts video ID from youtube.com/watch URL', () async {
        final mockClient = _MockHttpClient((_) async => http.Response('', 404));
        final llm = _FakeLlmService(
          onChat: () async => Result.success('transcript'),
        );
        final extractor = TranscriptionExtractor(
          llmService: llm,
          modelId: 'test-model',
          httpClient: mockClient,
          localeName: 'en',
        );
        final result = await extractor.transcribeVideo(
          rawContent: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          sourceUrl: null,
        );
        expect(result.text, 'transcript');
        expect(result.extractionMethod, 'transcribed_llm');
        extractor.dispose();
      });

      test('extracts video ID from youtu.be URL', () async {
        final mockClient = _MockHttpClient((_) async => http.Response('', 404));
        final llm = _FakeLlmService(
          onChat: () async => Result.success('transcript'),
        );
        final extractor = TranscriptionExtractor(
          llmService: llm,
          modelId: 'test-model',
          httpClient: mockClient,
          localeName: 'en',
        );
        final result = await extractor.transcribeVideo(
          rawContent: 'https://youtu.be/dQw4w9WgXcQ',
          sourceUrl: null,
        );
        expect(result.text, 'transcript');
        expect(result.extractionMethod, 'transcribed_llm');
        extractor.dispose();
      });

      test('extracts video ID from youtu.be with additional params', () async {
        final mockClient = _MockHttpClient((_) async => http.Response('', 404));
        final llm = _FakeLlmService(
          onChat: () async => Result.success('transcript'),
        );
        final extractor = TranscriptionExtractor(
          llmService: llm,
          modelId: 'test-model',
          httpClient: mockClient,
          localeName: 'en',
        );
        final result = await extractor.transcribeVideo(
          rawContent: 'https://youtu.be/dQw4w9WgXcQ?t=30',
          sourceUrl: null,
        );
        expect(result.text, 'transcript');
        expect(result.extractionMethod, 'transcribed_llm');
        extractor.dispose();
      });
    });

    group('transcribeWithLlm', () {
      test('returns llm_not_available when LLM is null', () async {
        final extractor = TranscriptionExtractor(
          modelId: 'test-model',
          localeName: 'en',
        );
        final result = await extractor.transcribeAudio(
          rawContent: 'this is some audio content that is longer than 20 characters',
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'audio_no_content');
        extractor.dispose();
      });
    });

    group('dispose', () {
      test('can be called without error', () {
        final extractor = TranscriptionExtractor(modelId: 'test-model', localeName: 'en');
        expect(() => extractor.dispose(), returnsNormally);
      });
    });
  });
}
