import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:studyking/core/data/extraction/asr_engine.dart';

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

void main() {
  group('NoopAsrEngine', () {
    test('isAvailable returns false', () {
      final engine = NoopAsrEngine();
      expect(engine.isAvailable, isFalse);
    });

    test('transcribeFile returns empty result', () async {
      final engine = NoopAsrEngine();
      final result = await engine.transcribeFile(filePath: '/test/file.mp3');
      expect(result.text, '');
      expect(result.extractionMethod, 'no_asr_engine');
    });
  });

  group('WhisperApiAsrEngine', () {
    test('isAvailable returns false when no API key', () {
      final engine = WhisperApiAsrEngine(apiKey: null);
      expect(engine.isAvailable, isFalse);
    });

    test('isAvailable returns false when API key is empty', () {
      final engine = WhisperApiAsrEngine(apiKey: '');
      expect(engine.isAvailable, isFalse);
    });

    test('isAvailable returns true when API key is set', () {
      final engine = WhisperApiAsrEngine(apiKey: 'sk-test-key');
      expect(engine.isAvailable, isTrue);
    });

    test('returns whisper_no_api_key when no API key configured', () async {
      final engine = WhisperApiAsrEngine(apiKey: null);
      final result = await engine.transcribeFile(filePath: '/test/file.mp3');
      expect(result.text, '');
      expect(result.extractionMethod, 'whisper_no_api_key');
    });

    test('returns whisper_file_not_found for non-existent file', () async {
      final engine = WhisperApiAsrEngine(apiKey: 'sk-test-key');
      final result = await engine.transcribeFile(filePath: '/nonexistent/file.mp3');
      expect(result.text, '');
      expect(result.extractionMethod, 'whisper_file_not_found');
    });

    test('parses verbose JSON response correctly', () async {
      final dir = Directory.systemTemp.createTempSync('whisper_test_');
      try {
        final file = File('${dir.path}/test.mp3');
        await file.writeAsBytes([0xFF, 0xFB, 0x90]);

        final mockClient = _MockHttpClient(
          (_) async => http.Response('', 404),
          onSend: (request) async {
            final response = http.StreamedResponse(
              Stream.value(utf8.encode(jsonEncode({
                'text': 'Hello world',
                'duration': 5.0,
                'segments': [
                  {
                    'text': ' Hello',
                    'start': 0.0,
                    'end': 2.0,
                    'avg_logprob': -0.1,
                    'no_speech_prob': 0.01,
                    'confidence': 0.95,
                  },
                  {
                    'text': ' world',
                    'start': 2.0,
                    'end': 5.0,
                    'avg_logprob': -0.2,
                    'no_speech_prob': 0.02,
                    'confidence': 0.90,
                  },
                ],
              }))),
              200,
            );
            return response;
          },
        );

        final engine = WhisperApiAsrEngine(
          apiKey: 'sk-test-key',
          httpClient: mockClient,
        );

        final result = await engine.transcribeFile(filePath: file.path);

        expect(result.text, 'Hello world');
        expect(result.extractionMethod, 'whisper_api');
        expect(result.durationSeconds, 5);
        expect(result.confidence, greaterThan(0.0));
        expect(result.segments, isNotNull);
        expect(result.segments, hasLength(2));
        expect(result.segments![0].text, 'Hello');
        expect(result.segments![1].text, 'world');
        engine.dispose();
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('handles API error response', () async {
      final dir = Directory.systemTemp.createTempSync('whisper_error_test_');
      try {
        final file = File('${dir.path}/test.mp3');
        await file.writeAsBytes([0xFF, 0xFB, 0x90]);

        final mockClient = _MockHttpClient(
          (_) async => http.Response('', 404),
          onSend: (request) async {
            final response = http.StreamedResponse(
              Stream.value(utf8.encode('{"error": "invalid request"}')),
              400,
            );
            return response;
          },
        );

        final engine = WhisperApiAsrEngine(
          apiKey: 'sk-test-key',
          httpClient: mockClient,
        );

        final result = await engine.transcribeFile(filePath: file.path);

        expect(result.text, '');
        expect(result.extractionMethod, 'whisper_api_error');
        expect(result.errorMessage, contains('Whisper API error: 400'));
        engine.dispose();
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('logs warning when response is not valid JSON at all', () async {
      final dir = Directory.systemTemp.createTempSync('whisper_parsefail_test_');
      try {
        final file = File('${dir.path}/test.mp3');
        await file.writeAsBytes([0xFF, 0xFB, 0x90]);

        final mockClient = _MockHttpClient(
          (_) async => http.Response('', 404),
          onSend: (request) async {
            final response = http.StreamedResponse(
              Stream.value(utf8.encode('totally not json :::')),
              200,
            );
            return response;
          },
        );

        final records = <String>[];
        final originalPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) => records.add(message ?? '');

        final engine = WhisperApiAsrEngine(
          apiKey: 'sk-test-key',
          httpClient: mockClient,
        );

        final result = await engine.transcribeFile(filePath: file.path);

        debugPrint = originalPrint;

        expect(result.text, '');
        expect(result.extractionMethod, 'whisper_parse_failed');
        expect(
          records.any((r) => r.contains('Failed to extract fallback text')),
          isTrue,
          reason: 'expected a warning to be logged for the parse failure',
        );
        engine.dispose();
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('falls back to simple text parse when segments missing', () async {
      final dir = Directory.systemTemp.createTempSync('whisper_simple_test_');
      try {
        final file = File('${dir.path}/test.mp3');
        await file.writeAsBytes([0xFF, 0xFB, 0x90]);

        final mockClient = _MockHttpClient(
          (_) async => http.Response('', 404),
          onSend: (request) async {
            final response = http.StreamedResponse(
              Stream.value(utf8.encode(jsonEncode({
                'text': 'Simple transcript without segments',
              }))),
              200,
            );
            return response;
          },
        );

        final engine = WhisperApiAsrEngine(
          apiKey: 'sk-test-key',
          httpClient: mockClient,
        );

        final result = await engine.transcribeFile(filePath: file.path);

        expect(result.text, 'Simple transcript without segments');
        expect(result.extractionMethod, 'whisper_api');
        expect(result.segments, isNull);
        engine.dispose();
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
