import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';

void main() {
  group('Result<T>', () {
    test('Result.success stores data and sets isSuccess to true', () {
      final result = Result<int>.success(42);
      expect(result.data, equals(42));
      expect(result.isSuccess, isTrue);
      expect(result.error, isNull);
      expect(result.isFailure, isFalse);
    });

    test('Result.failure stores error and sets isSuccess to false', () {
      final result = Result<int>.failure('Something went wrong');
      expect(result.error, equals('Something went wrong'));
      expect(result.isSuccess, isFalse);
      expect(result.data, isNull);
      expect(result.isFailure, isTrue);
    });

    test('Result.success with null data', () {
      final result = Result<String?>.success(null);
      expect(result.data, isNull);
      expect(result.isSuccess, isTrue);
    });

    test('Result.failure with empty error', () {
      final result = Result<int>.failure('');
      expect(result.error, isEmpty);
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
    });
  });

  group('Result<T> - pattern matching on sealed class', () {
    test('isFailure returns false when isSuccess returns true', () {
      final result = Result<int>.success(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('isFailure returns true when isSuccess returns false', () {
      final result = Result<int>.failure('error');
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
    });

    test('SuccessResult created via factory is SuccessResult type', () {
      final result = Result<int>.success(1);
      expect(result, isA<SuccessResult<int>>());
    });

    test('FailureResult created via factory is FailureResult type', () {
      final result = Result<int>.failure('err');
      expect(result, isA<FailureResult<int>>());
    });
  });

  group('Result<T> - Extended Coverage', () {
    test('Result.success with complex data', () {
      final result = Result<Map<String, int>>.success({'a': 1, 'b': 2});
      expect(result.data, equals({'a': 1, 'b': 2}));
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('Result.failure with complex data', () {
      final result = Result<List<String>>.failure('Multiple errors: one, two, three');
      expect(result.error, equals('Multiple errors: one, two, three'));
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
    });

    test('Result.success with empty string data', () {
      final result = Result<String>.success('');
      expect(result.data, isEmpty);
      expect(result.isSuccess, isTrue);
    });

    test('Result.failure with null error', () {
      final result = Result<int>.failure(null);
      expect(result.error, isNull);
      expect(result.isSuccess, isFalse);
    });

    test('isFailure returns true when error is empty string', () {
      final result = Result<int>.failure('');
      expect(result.isFailure, isTrue);
    });

    test('isFailure returns true for non-empty error', () {
      final result = Result<int>.failure('error');
      expect(result.isFailure, isTrue);
    });
  });

  group('Result<T> - isSuccess/isFailure exhaustive guarantee', () {
    test('isSuccess and isFailure are always opposite', () {
      final success = Result<int>.success(1);
      expect(success.isSuccess, equals(!success.isFailure));

      final failure = Result<int>.failure('err');
      expect(failure.isFailure, equals(!failure.isSuccess));
    });
  });

  group('Result.capture', () {
    test('returns success when async block succeeds', () async {
      final result = await Result.capture(() async => 42);
      expect(result.isSuccess, isTrue);
      expect(result.data, equals(42));
      expect(result.error, isNull);
    });

    test('returns failure when async block throws Exception', () async {
      final result = await Result.capture<int>(() async => throw Exception('fail'));
      expect(result.isFailure, isTrue);
      expect(result.data, isNull);
      expect(result.error, contains('fail'));
    });

    test('returns failure when async block throws non-Exception', () async {
      final result = await Result.capture<int>(() async => throw 42);
      expect(result.isFailure, isTrue);
      expect(result.error, equals('42'));
    });

    test('capture with context string does not change return value', () async {
      final result = await Result.capture(() async => 'data', context: 'ctx');
      expect(result.isSuccess, isTrue);
      expect(result.data, equals('data'));
    });

    test('capture preserves null return from async block', () async {
      final result = await Result.capture<String?>(() async => null);
      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    test('capture preserves complex object return', () async {
      final result = await Result.capture(() async => [1, 2, 3]);
      expect(result.isSuccess, isTrue);
      expect(result.data, equals([1, 2, 3]));
    });
  });

  group('Result.captureSync', () {
    test('returns success when sync block succeeds', () {
      final result = Result.captureSync(() => 42);
      expect(result.isSuccess, isTrue);
      expect(result.data, equals(42));
      expect(result.error, isNull);
    });

    test('returns failure when sync block throws Exception', () {
      final result = Result.captureSync<int>(() => throw Exception('sync fail'));
      expect(result.isFailure, isTrue);
      expect(result.data, isNull);
      expect(result.error, contains('sync fail'));
    });

    test('returns failure when sync block throws non-Exception', () {
      final result = Result.captureSync<int>(() => throw 'string error');
      expect(result.isFailure, isTrue);
      expect(result.error, equals('string error'));
    });

    test('captureSync with context string does not change return value', () {
      final result = Result.captureSync(() => 'data', context: 'ctx');
      expect(result.isSuccess, isTrue);
      expect(result.data, equals('data'));
    });

    test('captureSync preserves null return', () {
      final result = Result.captureSync<String?>(() => null);
      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    test('captureSync preserves complex object return', () {
      final result = Result.captureSync(() => {'key': 'value'});
      expect(result.isSuccess, isTrue);
      expect(result.data, equals({'key': 'value'}));
    });
  });
}
