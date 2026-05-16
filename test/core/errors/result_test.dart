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
}
