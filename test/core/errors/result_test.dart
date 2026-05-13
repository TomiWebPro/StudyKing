import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';

void main() {
  group('Result<T>', () {
    group('Result.success', () {
      test('stores data and sets isSuccess to true', () {
        final result = Result<int>.success(42);
        expect(result.data, equals(42));
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.error, isNull);
        expect(result.hasError, isFalse);
      });

      test('with String data', () {
        final result = Result<String>.success('hello');
        expect(result.data, equals('hello'));
        expect(result.isSuccess, isTrue);
      });

      test('with complex data type (Map)', () {
        final result = Result<Map<String, int>>.success({'a': 1, 'b': 2});
        expect(result.data, equals({'a': 1, 'b': 2}));
        expect(result.isSuccess, isTrue);
      });

      test('with List data', () {
        final result = Result<List<int>>.success([1, 2, 3]);
        expect(result.data, equals([1, 2, 3]));
        expect(result.isSuccess, isTrue);
      });

      test('with empty data (empty string)', () {
        final result = Result<String>.success('');
        expect(result.data, isEmpty);
        expect(result.isSuccess, isTrue);
      });

      test('with null data (nullable type)', () {
        final result = Result<String?>.success(null);
        expect(result.data, isNull);
        expect(result.isSuccess, isTrue);
        expect(result.hasError, isFalse);
      });

      test('error is always null', () {
        final result = Result<int>.success(99);
        expect(result.error, isNull);
      });
    });

    group('Result.failure', () {
      test('stores error and sets isSuccess to false', () {
        final result = Result<int>.failure('Something went wrong');
        expect(result.error, equals('Something went wrong'));
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.data, isNull);
        expect(result.hasError, isTrue);
      });

      test('with empty error string', () {
        final result = Result<int>.failure('');
        expect(result.error, isEmpty);
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.hasError, isTrue);
      });

      test('with null error', () {
        final result = Result<int>.failure(null);
        expect(result.error, isNull);
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.hasError, isFalse);
      });

      test('with detailed error message', () {
        final result = Result<List<String>>.failure('Multiple errors: one, two');
        expect(result.error, equals('Multiple errors: one, two'));
        expect(result.isSuccess, isFalse);
      });

      test('data is always null', () {
        final result = Result<int>.failure('error');
        expect(result.data, isNull);
      });
    });

    group('isSuccess', () {
      test('returns true for success', () {
        expect(Result<int>.success(1).isSuccess, isTrue);
      });

      test('returns false for failure', () {
        expect(Result<int>.failure('error').isSuccess, isFalse);
      });
    });

    group('isFailure', () {
      test('returns true for failure', () {
        expect(Result<int>.failure('error').isFailure, isTrue);
      });

      test('returns false for success', () {
        expect(Result<int>.success(1).isFailure, isFalse);
      });

      test('returns true for failure with null error', () {
        expect(Result<int>.failure(null).isFailure, isTrue);
      });
    });

    group('hasError', () {
      test('returns false for success', () {
        expect(Result<int>.success(1).hasError, isFalse);
      });

      test('returns false for success with nullable type', () {
        expect(Result<String?>.success(null).hasError, isFalse);
      });

      test('returns true for failure with non-null error', () {
        expect(Result<int>.failure('error').hasError, isTrue);
      });

      test('returns true for failure with empty string error', () {
        expect(Result<int>.failure('').hasError, isTrue);
      });

      test('returns false for failure with null error', () {
        expect(Result<int>.failure(null).hasError, isFalse);
      });
    });

    group('generic type inference', () {
      test('works with int type', () {
        final result = Result<int>.success(42);
        expect(result, isA<Result<int>>());
      });

      test('works with String type', () {
        final result = Result<String>.success('test');
        expect(result, isA<Result<String>>());
      });

      test('works with double type', () {
        final result = Result<double>.success(3.14);
        expect(result, isA<Result<double>>());
      });

      test('works with bool type', () {
        final result = Result<bool>.success(true);
        expect(result, isA<Result<bool>>());
      });
    });

    group('SuccessResult class', () {
      test('is a subtype of Result', () {
        final result = SuccessResult<int>(42);
        expect(result, isA<Result<int>>());
        expect(result, isA<SuccessResult<int>>());
      });

      test('stores data correctly', () {
        final result = SuccessResult<String>('direct');
        expect(result.data, equals('direct'));
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.error, isNull);
        expect(result.hasError, isFalse);
      });

      test('is created by Result.success factory', () {
        final result = Result<int>.success(1);
        expect(result, isA<SuccessResult<int>>());
      });
    });

    group('FailureResult class', () {
      test('is a subtype of Result', () {
        final result = FailureResult<int>('error');
        expect(result, isA<Result<int>>());
        expect(result, isA<FailureResult<int>>());
      });

      test('stores error correctly', () {
        final result = FailureResult<String>('error message');
        expect(result.error, equals('error message'));
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.data, isNull);
        expect(result.hasError, isTrue);
      });

      test('is created by Result.failure factory', () {
        final result = Result<int>.failure('error');
        expect(result, isA<FailureResult<int>>());
      });
    });

    group('sealed class exhaustiveness', () {
      test('can be pattern matched', () {
        Result<int> result = Result<int>.success(10);
        final value = switch (result) {
          SuccessResult<int>(:final data) => 'success $data',
          FailureResult<int>(:final error) => 'failure $error',
        };
        expect(value, equals('success 10'));

        result = Result<int>.failure('fail');
        final value2 = switch (result) {
          SuccessResult<int>(:final data) => 'success $data',
          FailureResult<int>(:final error) => 'failure $error',
        };
        expect(value2, equals('failure fail'));
      });

      test('isSuccess and isFailure are consistent with sealed types', () {
        final success = Result<int>.success(1);
        expect(success is SuccessResult<int>, equals(success.isSuccess));
        expect(success is FailureResult<int>, equals(success.isFailure));

        final failure = Result<int>.failure('err');
        expect(failure is FailureResult<int>, equals(failure.isFailure));
        expect(failure is SuccessResult<int>, equals(failure.isSuccess));
      });
    });
  });
}
