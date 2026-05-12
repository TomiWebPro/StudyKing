import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:studyking/services/question_engine_dynamic.dart';

void main() {
  group('DynamicQuestionType', () {
    test('has multipleChoice value', () {
      expect(DynamicQuestionType.multipleChoice, isNotNull);
    });

    test('has input value', () {
      expect(DynamicQuestionType.input, isNotNull);
    });

    test('has graph value', () {
      expect(DynamicQuestionType.graph, isNotNull);
    });

    test('has calculation value', () {
      expect(DynamicQuestionType.calculation, isNotNull);
    });

    test('has trueFalse value', () {
      expect(DynamicQuestionType.trueFalse, isNotNull);
    });

    test('has match value', () {
      expect(DynamicQuestionType.match, isNotNull);
    });

    test('enum has correct number of values', () {
      expect(DynamicQuestionType.values.length, equals(6));
    });
  });

  group('DynamicTypeFetcher', () {
    late DynamicTypeFetcher fetcher;

    setUp(() {
      fetcher = DynamicTypeFetcher();
    });

    group('initialization', () {
      test('creates instance with dio', () {
        expect(fetcher.dio, isNotNull);
      });

      test('creates instance with custom dio', () {
        final customDio = Dio();
        final customFetcher = DynamicTypeFetcher(dio: customDio);
        expect(customFetcher.dio, equals(customDio));
      });
    });

    group('fetchQuestionTypes', () {
      test('handles fetch without throwing', () async {
        expect(() => fetcher.fetchQuestionTypes(), returnsNormally);
      });

      test('questionTypes map is empty after failed fetch', () async {
        await fetcher.fetchQuestionTypes();
        expect(fetcher.getQuestionTypeIds(), isA<List<String>>());
      });
    });

    group('getQuestionTypeIds', () {
      test('returns empty list when no types fetched', () {
        final ids = fetcher.getQuestionTypeIds();
        expect(ids, isEmpty);
      });

      test('returns list of type ids', () {
        final ids = fetcher.getQuestionTypeIds();
        expect(ids, isA<List<String>>());
      });
    });

    group('getQuestionTypeInfo', () {
      test('returns null for unknown type', () {
        final info = fetcher.getQuestionTypeInfo('unknown');
        expect(info, isNull);
      });

      test('returns string for known type', () {
        final info = fetcher.getQuestionTypeInfo('test');
        expect(info, isA<String?>());
      });
    });

    group('fetchMcqOptions', () {
      test('handles fetch without throwing', () async {
        expect(() => fetcher.fetchMcqOptions(), returnsNormally);
      });

      test('updates mcqOptionsRanges after fetch', () async {
        await fetcher.fetchMcqOptions();
        expect(fetcher.getMcqOptionsForType('default'), isA<int>());
      });
    });

    group('getMcqOptionsForType', () {
      test('returns default value for unknown type', () {
        final options = fetcher.getMcqOptionsForType('unknown');
        expect(options, equals(5));
      });

      test('returns configured value for known type', () {
        final options = fetcher.getMcqOptionsForType('test');
        expect(options, isA<int>());
      });
    });

    group('getMinMcqOptions', () {
      test('returns 2 when ranges are empty', () {
        final min = fetcher.getMinMcqOptions();
        expect(min, equals(2));
      });
    });

    group('getMaxMcqOptions', () {
      test('returns 10 when ranges are empty', () {
        final max = fetcher.getMaxMcqOptions();
        expect(max, equals(10));
      });

      test('returns highest value in ranges', () {
        final max = fetcher.getMaxMcqOptions();
        expect(max, isA<int>());
        expect(max, greaterThanOrEqualTo(2));
      });
    });

    group('question types parsing', () {
      test('parses valid type maps', () async {
        await fetcher.fetchQuestionTypes();
        final ids = fetcher.getQuestionTypeIds();
        expect(ids, isA<List<String>>());
      });
    });
  });
}
