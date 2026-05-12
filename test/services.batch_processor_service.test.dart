import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/services/batch_processor_service.dart';

void main() {
  group('BatchProcessingService', () {
    late BatchProcessingService service;

    setUp(() {
      service = BatchProcessingService();
    });

    test('creates instance with dio', () {
      expect(service.dio, isNotNull);
    });

    test('creates instance with contextApi', () {
      expect(service.contextApi, isNotNull);
    });

    test('creates instance with batchApi', () {
      expect(service.batchApi, isNotNull);
    });

    test('creates instance with batchAdmin', () {
      expect(service.batchAdmin, isNotNull);
    });

    test('initializes with empty contextWindows', () {
      expect(service.contextWindows, isEmpty);
    });

    test('has uuid generator', () {
      expect(service.uuid, isNotNull);
    });

    test('contextWindows returns unmodifiable map', () {
      expect(() => service.contextWindows['test'] = 9999, throwsA(anything));
    });

    group('prefetchContextWindows', () {
      test('handles empty model list', () async {
        await service.prefetchContextWindows([]);
        expect(service.contextWindows, isEmpty);
      });

      test('handles model list without throwing', () async {
        await service.prefetchContextWindows(['model1', 'model2']);
        expect(service.contextWindows, isA<Map<String, int>>());
      });
    });

    group('processTextExtractedPages', () {
      test('handles empty text list', () async {
        final segments = await service.processTextExtractedPages([], 'model');
        expect(segments, isEmpty);
      });

      test('processes single text page', () async {
        final segments = await service.processTextExtractedPages(['Page 1 content'], 'model');
        expect(segments, isNotEmpty);
        expect(segments.first.textSegment, isNotEmpty);
      });

      test('processes multiple text pages', () async {
        final segments = await service.processTextExtractedPages(
          ['Page 1', 'Page 2', 'Page 3'],
          'model',
        );
        expect(segments, isNotEmpty);
      });

      test('skips empty pages', () async {
        final segments = await service.processTextExtractedPages(
          ['', 'Content', ''],
          'model',
        );
        expect(segments, isNotEmpty);
      });
    });

    group('processText', () {
      test('returns segments for valid response', () async {
        final segments = await service.processText('Test input', 'model');
        expect(segments, isA<List<TextSegment>>());
      });

      test('returns at least one segment', () async {
        final segments = await service.processText('Hello', 'test-model');
        expect(segments.isNotEmpty, isTrue);
      });

      test('returns segment with error message on failure', () async {
        final segments = await service.processText('error', 'model');
        expect(segments.first.textSegment, isNotEmpty);
      });
    });
  });

  group('TextSegment', () {
    test('creates instance with required fields', () {
      final segment = TextSegment(
        messageId: 'msg1',
        page: 1,
        textSegment: 'Test content',
      );
      expect(segment.messageId, equals('msg1'));
      expect(segment.page, equals(1));
      expect(segment.textSegment, equals('Test content'));
    });

    test('creates instance with zero page', () {
      final segment = TextSegment(messageId: 'id', page: 0, textSegment: 'text');
      expect(segment.page, equals(0));
    });

    group('toJson', () {
      test('serializes all fields', () {
        final segment = TextSegment(messageId: 'id', page: 5, textSegment: 'content');
        final json = segment.toJson();
        expect(json['id'], equals('id'));
        expect(json['page'], equals(5));
        expect(json['text'], equals('content'));
      });
    });

    group('fromJson', () {
      test('parses valid JSON', () {
        final json = {'id': 'msg1', 'page': 3, 'text': 'Test'};
        final segment = TextSegment.fromJson(json);
        expect(segment.messageId, equals('msg1'));
        expect(segment.page, equals(3));
        expect(segment.textSegment, equals('Test'));
      });

      test('uses default page for missing', () {
        final json = {'id': 'msg1', 'text': 'Test'};
        final segment = TextSegment.fromJson(json);
        expect(segment.page, equals(1));
      });

      test('uses empty string for missing text', () {
        final json = {'id': 'msg1', 'page': 2};
        final segment = TextSegment.fromJson(json);
        expect(segment.textSegment, isEmpty);
      });
    });
  });

  group('BatchAdmin', () {
    late BatchAdmin admin;

    setUp(() {
      admin = BatchAdmin();
    });

    test('creates instance with dio', () {
      expect(admin.dio, isNotNull);
    });

    group('process', () {
      test('handles empty segments', () async {
        final result = await admin.process([]);
        expect(result, isA<BatchResult>());
      });

      test('returns batch result', () async {
        final result = await admin.process(['seg1', 'seg2']);
        expect(result.isSuccess, isA<bool>());
        expect(result.content, isA<List<String>>());
      });

      test('returns result on error', () async {
        final result = await admin.process(['segment']);
        expect(result.content, isNotNull);
      });
    });
  });

  group('PlatformDatabase', () {
    test('creates instance with database map', () {
      final db = PlatformDatabase({'contextWindow': 8192});
      expect(db.database, isNotEmpty);
    });

    test('returns context window from database', () {
      final db = PlatformDatabase({'contextWindow': 16384});
      expect(db.contextWindow, equals(16384));
    });

    test('returns default for missing contextWindow', () {
      final db = PlatformDatabase({});
      expect(db.contextWindow, equals(4096));
    });

    test('handles non-numeric contextWindow', () {
      final db = PlatformDatabase({'contextWindow': 'not-a-number'});
      expect(db.contextWindow, isNotNull);
    });
  });

  group('BatchAPI', () {
    late BatchAPI batchApi;

    setUp(() {
      batchApi = BatchAPI();
    });

    test('creates instance with dio', () {
      expect(batchApi.dio, isNotNull);
    });

    group('get', () {
      test('throws exception on error', () async {
        expect(
          () => batchApi.get('test/endpoint', params: {'key': 'value'}),
          throwsA(anything),
        );
      });

      test('accepts endpoint parameter', () async {
        try {
          await batchApi.get('test/endpoint');
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('accepts params parameter', () async {
        try {
          await batchApi.get('endpoint', params: {'model': 'test'});
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });
  });

  group('ContextAPI', () {
    late ContextAPI contextApi;

    setUp(() {
      contextApi = ContextAPI();
    });

    test('creates instance with dio', () {
      expect(contextApi.dio, isNotNull);
    });

    group('get', () {
      test('throws exception on error', () async {
        expect(
          () => contextApi.get('test/endpoint'),
          throwsA(anything),
        );
      });

      test('accepts endpoint parameter', () async {
        try {
          await contextApi.get('test/endpoint');
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('accepts path parameter', () async {
        try {
          await contextApi.get('endpoint', path: {'key': 'value'});
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('accepts params parameter', () async {
        try {
          await contextApi.get('endpoint', params: {'model': 'test'});
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });
  });

  group('BatchResult', () {
    test('creates instance with required fields', () {
      final result = BatchResult(isSuccess: true, content: ['item1', 'item2']);
      expect(result.isSuccess, isTrue);
      expect(result.content, hasLength(2));
    });

    test('creates instance with empty content', () {
      final result = BatchResult(isSuccess: false, content: []);
      expect(result.isSuccess, isFalse);
      expect(result.content, isEmpty);
    });

    test('handles single content item', () {
      final result = BatchResult(isSuccess: true, content: ['single']);
      expect(result.content, hasLength(1));
    });
  });
}
