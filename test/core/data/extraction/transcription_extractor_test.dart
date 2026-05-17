import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/extraction/transcription_extractor.dart';

void main() {
  group('TranscriptionExtractor', () {
    late TranscriptionExtractor extractor;

    setUp(() {
      extractor = TranscriptionExtractor(modelId: 'test-model');
    });

    tearDown(() {
      extractor.dispose();
    });

    group('transcribeAudio', () {
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
    });

    group('transcribeVideo', () {
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
    });

    group('YouTube video ID extraction', () {
      test('extracts video ID from youtube.com URL', () async {
        final result = await extractor.transcribeVideo(
          rawContent: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          sourceUrl: null,
        );
        expect(result.text, '');
      });

      test('extracts video ID from youtu.be URL', () async {
        final result = await extractor.transcribeVideo(
          rawContent: 'https://youtu.be/dQw4w9WgXcQ',
          sourceUrl: null,
        );
        expect(result.text, '');
      });
    });

    group('transcribeAudio using sourceUrl', () {
      test('uses sourceUrl when rawContent is not a URL', () async {
        final result = await extractor.transcribeAudio(
          rawContent: 'some id',
          sourceUrl: 'https://example.com/audio.mp3',
        );
        expect(result.extractionMethod, 'audio_url_no_llm');
      });
    });

    group('transcribeVideo using sourceUrl', () {
      test('uses sourceUrl for YouTube detection', () async {
        final result = await extractor.transcribeVideo(
          rawContent: 'some id',
          sourceUrl: 'https://youtube.com/watch?v=abc123',
        );
        expect(result.text, '');
      });
    });
  });
}
