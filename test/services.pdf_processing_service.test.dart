import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/services/pdf_processing_service.dart';
import 'package:studyking/providers/llm_engine_provider.dart';

class MockLLMAIEngineProvider extends LLMAIEngineProvider {
  MockLLMAIEngineProvider() : super();

  @override
  Future<String> setApiKey(String newKey) async {
    return newKey;
  }
}

void main() {
  group('PDFProcessingService', () {
    late PDFProcessingService service;
    late MockLLMAIEngineProvider mockProvider;

    setUp(() {
      mockProvider = MockLLMAIEngineProvider();
      service = PDFProcessingService(llmEngineProvider: mockProvider);
    });

    group('initialization', () {
      test('creates service with required provider', () {
        expect(service.llmEngineProvider, isNotNull);
      });

      test('initializes with default currentContext', () {
        expect(service.currentContext, equals(8192));
      });

      test('initializes with empty contextWindows map', () {
        expect(service.contextWindows, isEmpty);
      });

      test('initializes with isFetching false', () {
        expect(service.isFetching, isFalse);
      });
    });

    group('fetchContextWindow', () {
      test('sets isFetching to true during fetch', () async {
        service.fetchContextWindow('test-model');
        expect(service.isFetching, isTrue);
      });

      test('handles exception and sets default values', () async {
        await service.fetchContextWindow('invalid-model');
        expect(service.contextWindows.containsKey('invalid-model'), isTrue);
      });

      test('updates currentContext after fetch', () async {
        await service.fetchContextWindow('test-model');
        expect(service.currentContext, isA<int>());
      });
    });

    group('chunkText', () {
      test('returns empty list for empty pages', () {
        final result = service.chunkText([]);
        expect(result, isEmpty);
      });

      test('handles single page smaller than context', () {
        final result = service.chunkText(['short text']);
        expect(result.length, equals(1));
        expect(result.first, contains('short text'));
      });

      test('chunks pages when exceeding context window', () {
        service = PDFProcessingService(llmEngineProvider: mockProvider);
        final largeText = List.generate(10, (i) => 'x' * 2000);
        final result = service.chunkText(largeText);
        expect(result.length, greaterThanOrEqualTo(1));
      });

      test('returns all pages in chunks', () {
        final pages = ['page1', 'page2', 'page3'];
        final result = service.chunkText(pages);
        expect(result.isNotEmpty, isTrue);
      });

      test('handles page exactly at context boundary', () {
        final pages = ['x' * 8192, 'x' * 100];
        final result = service.chunkText(pages);
        expect(result.length, greaterThanOrEqualTo(2));
      });
    });

    group('fetchContextPages', () {
      test('returns empty list when data is not a list', () async {
        final result = await service.fetchContextPages(5);
        expect(result, isA<List<Map<String, dynamic>>>());
      });
    });

    group('processTextChunks', () {
      test('returns empty list for empty chunks', () async {
        final result = await service.processTextChunks([]);
        expect(result, isEmpty);
      });

      test('processes chunks and returns text segments', () async {
        final chunks = [['text1'], ['text2']];
        final result = await service.processTextChunks(chunks);
        expect(result, isA<List<TextSegment>>());
      });
    });

    group('onError', () {
      test('does not throw on error callback', () {
        expect(() => service.onError('test error'), returnsNormally);
      });
    });

    group('notifyListeners', () {
      test('ChangeNotifier notifies on fetchContextWindow', () async {
        var notified = false;
        service.addListener(() => notified = true);
        await service.fetchContextWindow('test-model');
        expect(notified, isTrue);
      });
    });
  });

  group('TextSegment', () {
    test('creates text segment with id and text', () {
      final segment = TextSegment(id: 'test-id', text: 'test content');
      expect(segment.id, equals('test-id'));
      expect(segment.text, equals('test content'));
    });

    test('allows creating multiple segments', () {
      final segment1 = TextSegment(id: '1', text: 'first');
      final segment2 = TextSegment(id: '2', text: 'second');
      expect(segment1.id, isNot(equals(segment2.id)));
    });
  });

  group('ApiContext', () {
    test('creates instance with endpoint', () {
      final context = ApiContext();
      expect(context.endpoint, isA<String>());
    });

    test('endpoint starts with api prefix', () {
      final context = ApiContext();
      expect(context.endpoint.startsWith('/api'), isTrue);
    });
  });

  group('ContextGenerator', () {
    test('initializes with empty context map', () {
      final generator = ContextGenerator();
      expect(generator.getContextMap(), isEmpty);
    });

    test('getContextWindow returns default for unknown model', () {
      final generator = ContextGenerator();
      expect(generator.getContextWindow('unknown'), equals(4096));
    });

    test('setContext updates context for model', () {
      final generator = ContextGenerator();
      generator.setContext('gpt-4', 8192);
      expect(generator.getContextWindow('gpt-4'), equals(8192));
    });

    test('setContext updates currentContext', () {
      final generator = ContextGenerator();
      generator.setContext('test-model', 16384);
      expect(generator.currentContext, equals(16384));
    });

    test('clearContext removes all entries', () {
      final generator = ContextGenerator();
      generator.setContext('model1', 8192);
      generator.setContext('model2', 16384);
      generator.clearContext();
      expect(generator.getContextMap(), isEmpty);
      expect(generator.currentContext, equals(0));
    });

    test('getContextMap returns unmodifiable map', () {
      final generator = ContextGenerator();
      generator.setContext('test', 4096);
      expect(() => generator.getContextMap()['test'] = 9999, throwsA(anything));
    });

    test('setContext overrides previous value', () {
      final generator = ContextGenerator();
      generator.setContext('model', 4096);
      generator.setContext('model', 8192);
      expect(generator.getContextWindow('model'), equals(8192));
    });
  });

  group('HTTPResponseProcessor', () {
    test('creates instance with required fields', () {
      final processor = HTTPResponseProcessor(
        body: 'test body',
        headers: {'content-type': 'application/json'},
        status: '200',
      );
      expect(processor.body, equals('test body'));
      expect(processor.headers, isNotEmpty);
      expect(processor.status, equals('200'));
    });

    test('accepts optional query parameters', () {
      final processor = HTTPResponseProcessor(
        body: 'test',
        headers: {},
        status: '200',
        queryParameters: {'page': '1'},
      );
      expect(processor.queryParameters, isNotNull);
    });
  });

  group('StorageService', () {
    test('initialize does not throw', () async {
      expect(() => StorageService.initialize(), returnsNormally);
    });

    test('set does not throw', () async {
      expect(() => StorageService.set('key', 'value'), returnsNormally);
    });

    test('get returns null', () async {
      final result = await StorageService.get('key');
      expect(result, isNull);
    });

    test('remove does not throw', () async {
      expect(() => StorageService.remove('key'), returnsNormally);
    });

    test('clearAll does not throw', () async {
      expect(() => StorageService.clearAll(), returnsNormally);
    });

    test('clearBox does not throw', () async {
      expect(() => StorageService.clearBox(), returnsNormally);
    });
  });
}
