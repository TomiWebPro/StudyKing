import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/exceptions.dart';

void main() {
  group('AppException', () {
    test('toString returns message without code when code is null', () {
      const exception = AppException(message: 'Test error');
      expect(exception.toString(), equals('AppException: Test error'));
    });

    test('toString returns message with code when code is provided', () {
      const exception = AppException(message: 'Test error', code: 'TEST_CODE');
      expect(exception.toString(), equals('AppException: Test error (TEST_CODE)'));
    });

    test('stores originalError when provided', () {
      final original = FormatException('bad data');
      final exception = AppException(
        message: 'test',
        originalError: original,
      );
      expect(exception.originalError, equals(original));
    });

    test('originalError is null by default', () {
      const exception = AppException(message: 'test');
      expect(exception.originalError, isNull);
    });

    test('code is null by default', () {
      const exception = AppException(message: 'test');
      expect(exception.code, isNull);
    });

    test('stores message correctly', () {
      const message = 'Something went wrong';
      const exception = AppException(message: message);
      expect(exception.message, equals(message));
    });

    test('type defaults to unknown', () {
      const exception = AppException(message: 'test');
      expect(exception.type, ExceptionType.unknown);
    });

    test('stores type correctly', () {
      const exception = AppException(message: 'test', type: ExceptionType.network);
      expect(exception.type, ExceptionType.network);
    });
  });

  group('ExceptionType enum values', () {
    test('has all expected values', () {
      expect(ExceptionType.values.length, 13);
      expect(ExceptionType.values, containsAll([
        ExceptionType.network,
        ExceptionType.apiKeyMissing,
        ExceptionType.invalidApiKey,
        ExceptionType.apiAuth,
        ExceptionType.apiRateLimit,
        ExceptionType.apiNotFound,
        ExceptionType.apiInternalServer,
        ExceptionType.database,
        ExceptionType.validation,
        ExceptionType.pdfParse,
        ExceptionType.llm,
        ExceptionType.contentGeneration,
        ExceptionType.unknown,
      ]));
    });
  });

  group('AppException - custom type and code', () {
    test('allows custom code', () {
      const exception = AppException(message: 'e', code: 'OVERRIDE');
      expect(exception.code, equals('OVERRIDE'));
    });

    test('allows custom type', () {
      const exception = AppException(message: 'e', type: ExceptionType.validation);
      expect(exception.type, ExceptionType.validation);
    });
  });

  group('AppException toString behavior', () {
    test('toString with empty string code shows parentheses', () {
      const exception = AppException(message: 'test', code: '');
      expect(exception.toString(), equals('AppException: test ()'));
    });

    test('toString with null code shows no parentheses', () {
      const exception = AppException(message: 'test');
      expect(exception.toString(), equals('AppException: test'));
    });

    test('toString with non-null code shows code in parentheses', () {
      const exception = AppException(message: 'test', code: 'ERR001');
      expect(exception.toString(), equals('AppException: test (ERR001)'));
    });

    test('toString with empty message still works', () {
      const exception = AppException(message: '');
      expect(exception.toString(), equals('AppException: '));
    });
  });

  group('AppException - all parameters', () {
    test('can create exception with all parameters', () {
      final original = Exception('cause');
      final exception = AppException(
        message: 'full error',
        type: ExceptionType.apiAuth,
        code: 'AUTH_001',
        originalError: original,
      );
      expect(exception.message, equals('full error'));
      expect(exception.type, ExceptionType.apiAuth);
      expect(exception.code, equals('AUTH_001'));
      expect(exception.originalError, same(original));
      expect(exception.toString(), equals('AppException: full error (AUTH_001)'));
    });

    test('toString does not include code when code is null explicitly', () {
      const exception = AppException(message: 'test', code: null);
      expect(exception.toString(), equals('AppException: test'));
    });

    test('toString with message containing special characters', () {
      const exception = AppException(message: "can't connect, retry?");
      expect(exception.toString(), equals("AppException: can't connect, retry?"));
    });
  });

  group('Exception Equality and Identity', () {
    test('two exceptions with same message are not identical', () {
      const e1 = AppException(message: 'test');
      const e2 = AppException(message: 'test');
      expect(e1, isNot(same(e2)));
      expect(e1.message, equals(e2.message));
    });

    test('exceptions store different originalErrors independently', () {
      final original1 = Exception('error1');
      final original2 = Exception('error2');
      final e1 = AppException(message: 'test', originalError: original1);
      final e2 = AppException(message: 'test', originalError: original2);
      expect(e1.originalError, isNot(equals(e2.originalError)));
    });

    test('exceptions can store various originalError types', () {
      final intError = AppException(message: 'test', originalError: 42);
      expect(intError.originalError, equals(42));

      final stringError = AppException(message: 'test', originalError: 'error string');
      expect(stringError.originalError, equals('error string'));

      final mapError = AppException(message: 'test', originalError: {'key': 'value'});
      expect(mapError.originalError, equals({'key': 'value'}));

      final listError = AppException(message: 'test', originalError: [1, 2, 3]);
      expect(listError.originalError, equals([1, 2, 3]));
    });

    test('AppException with null originalError stores null', () {
      const exception = AppException(message: 'test', originalError: null);
      expect(exception.originalError, isNull);
    });
  });
}
