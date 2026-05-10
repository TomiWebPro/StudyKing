import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/exceptions.dart';

class _TestAppException extends AppException {
  const _TestAppException({
    required super.message,
    super.code,
    super.originalError,
  });
}

void main() {
  group('AppException', () {
    test('toString returns message without code when code is null', () {
      final exception = _TestAppException(message: 'Test error');
      expect(exception.toString(), equals('AppException: Test error'));
    });

    test('toString returns message with code when code is provided', () {
      final exception = _TestAppException(message: 'Test error', code: 'TEST_CODE');
      expect(exception.toString(), equals('AppException: Test error (TEST_CODE)'));
    });

    test('stores originalError when provided', () {
      final original = FormatException('bad data');
      final exception = _TestAppException(
        message: 'test',
        originalError: original,
      );
      expect(exception.originalError, equals(original));
    });

    test('originalError is null by default', () {
      final exception = _TestAppException(message: 'test');
      expect(exception.originalError, isNull);
    });

    test('code is null by default', () {
      final exception = _TestAppException(message: 'test');
      expect(exception.code, isNull);
    });

    test('stores message correctly', () {
      const message = 'Something went wrong';
      final exception = _TestAppException(message: message);
      expect(exception.message, equals(message));
    });
  });

  group('NetworkException', () {
    test('has correct default code', () {
      final exception = NetworkException(message: 'Network error');
      expect(exception.code, equals('NETWORK_ERROR'));
    });

    test('implements AppException', () {
      final exception = NetworkException(message: 'test');
      expect(exception, isA<AppException>());
    });

    test('stores originalError', () {
      final original = Exception('timeout');
      final exception = NetworkException(
        message: 'test',
        originalError: original,
      );
      expect(exception.originalError, equals(original));
    });

    test('custom code overrides default', () {
      final exception = NetworkException(message: 'test', code: 'CUSTOM');
      expect(exception.code, equals('CUSTOM'));
    });
  });

  group('ApiAuthException', () {
    test('has correct default code', () {
      final exception = ApiAuthException(message: 'Auth failed');
      expect(exception.code, equals('AUTH_ERROR'));
    });

    test('implements AppException', () {
      final exception = ApiAuthException(message: 'test');
      expect(exception, isA<AppException>());
    });

    test('stores originalError', () {
      final original = Exception('token expired');
      final exception = ApiAuthException(
        message: 'test',
        originalError: original,
      );
      expect(exception.originalError, equals(original));
    });
  });

  group('ApiRateLimitException', () {
    test('has correct default code', () {
      final exception = ApiRateLimitException(message: 'Rate limited');
      expect(exception.code, equals('RATE_LIMIT_ERROR'));
    });

    test('implements AppException', () {
      final exception = ApiRateLimitException(message: 'test');
      expect(exception, isA<AppException>());
    });
  });

  group('ApiNotFoundException', () {
    test('has correct default code', () {
      final exception = ApiNotFoundException(message: 'Not found');
      expect(exception.code, equals('NOT_FOUND_ERROR'));
    });

    test('implements AppException', () {
      final exception = ApiNotFoundException(message: 'test');
      expect(exception, isA<AppException>());
    });
  });

  group('ApiInternalServerError', () {
    test('has correct default code', () {
      final exception = ApiInternalServerError(message: 'Server error');
      expect(exception.code, equals('SERVER_ERROR'));
    });

    test('implements AppException', () {
      final exception = ApiInternalServerError(message: 'test');
      expect(exception, isA<AppException>());
    });
  });

  group('DatabaseException', () {
    test('has correct default code', () {
      final exception = DatabaseException(message: 'DB error');
      expect(exception.code, equals('DATABASE_ERROR'));
    });

    test('implements AppException', () {
      final exception = DatabaseException(message: 'test');
      expect(exception, isA<AppException>());
    });
  });

  group('DatabaseNotFoundException', () {
    test('has correct default code', () {
      final exception = DatabaseNotFoundException(message: 'Not found');
      expect(exception.code, equals('NOT_FOUND_ERROR'));
    });

    test('implements AppException', () {
      final exception = DatabaseNotFoundException(message: 'test');
      expect(exception, isA<AppException>());
    });
  });

  group('ValidationException', () {
    test('has correct default code', () {
      final exception = ValidationException(message: 'Invalid input');
      expect(exception.code, equals('VALIDATION_ERROR'));
    });

    test('implements AppException', () {
      final exception = ValidationException(message: 'test');
      expect(exception, isA<AppException>());
    });
  });

  group('FileSystemException', () {
    test('has correct default code', () {
      final exception = FileSystemException(message: 'File error');
      expect(exception.code, equals('FILE_SYSTEM_ERROR'));
    });

    test('implements AppException', () {
      final exception = FileSystemException(message: 'test');
      expect(exception, isA<AppException>());
    });
  });

  group('PdfParseException', () {
    test('has correct default code', () {
      final exception = PdfParseException(message: 'PDF error');
      expect(exception.code, equals('PDF_PARSE_ERROR'));
    });

    test('implements AppException', () {
      final exception = PdfParseException(message: 'test');
      expect(exception, isA<AppException>());
    });
  });

  group('ContentGenerationException', () {
    test('has correct default code', () {
      final exception = ContentGenerationException(message: 'Gen error');
      expect(exception.code, equals('GENERATION_ERROR'));
    });

    test('implements AppException', () {
      final exception = ContentGenerationException(message: 'test');
      expect(exception, isA<AppException>());
    });
  });

  group('LlmException', () {
    test('has correct default code', () {
      final exception = LlmException(message: 'LLM error');
      expect(exception.code, equals('LLM_ERROR'));
    });

    test('implements AppException', () {
      final exception = LlmException(message: 'test');
      expect(exception, isA<AppException>());
    });
  });

  group('ApiKeyMissingException', () {
    test('has correct default code', () {
      final exception = ApiKeyMissingException(message: 'Key missing');
      expect(exception.code, equals('API_KEY_MISSING'));
    });

    test('implements AppException', () {
      final exception = ApiKeyMissingException(message: 'test');
      expect(exception, isA<AppException>());
    });
  });

  group('InvalidApiKeyException', () {
    test('has correct default code', () {
      final exception = InvalidApiKeyException(message: 'Invalid key');
      expect(exception.code, equals('INVALID_API_KEY'));
    });

    test('implements AppException', () {
      final exception = InvalidApiKeyException(message: 'test');
      expect(exception, isA<AppException>());
    });
  });

  group('All exception types - constructor defaults', () {
    test('all exceptions can be created with only message', () {
      expect(NetworkException(message: 'e'), isA<AppException>());
      expect(ApiAuthException(message: 'e'), isA<AppException>());
      expect(ApiRateLimitException(message: 'e'), isA<AppException>());
      expect(ApiNotFoundException(message: 'e'), isA<AppException>());
      expect(ApiInternalServerError(message: 'e'), isA<AppException>());
      expect(DatabaseException(message: 'e'), isA<AppException>());
      expect(DatabaseNotFoundException(message: 'e'), isA<AppException>());
      expect(ValidationException(message: 'e'), isA<AppException>());
      expect(FileSystemException(message: 'e'), isA<AppException>());
      expect(PdfParseException(message: 'e'), isA<AppException>());
      expect(ContentGenerationException(message: 'e'), isA<AppException>());
      expect(LlmException(message: 'e'), isA<AppException>());
      expect(ApiKeyMissingException(message: 'e'), isA<AppException>());
      expect(InvalidApiKeyException(message: 'e'), isA<AppException>());
    });

    test('all exceptions have non-null message', () {
      expect(NetworkException(message: '').message, isNotNull);
      expect(ApiAuthException(message: '').message, isNotNull);
      expect(ApiRateLimitException(message: '').message, isNotNull);
      expect(ApiNotFoundException(message: '').message, isNotNull);
      expect(ApiInternalServerError(message: '').message, isNotNull);
      expect(DatabaseException(message: '').message, isNotNull);
      expect(DatabaseNotFoundException(message: '').message, isNotNull);
      expect(ValidationException(message: '').message, isNotNull);
      expect(FileSystemException(message: '').message, isNotNull);
      expect(PdfParseException(message: '').message, isNotNull);
      expect(ContentGenerationException(message: '').message, isNotNull);
      expect(LlmException(message: '').message, isNotNull);
      expect(ApiKeyMissingException(message: '').message, isNotNull);
      expect(InvalidApiKeyException(message: '').message, isNotNull);
    });
  });

  group('All exception types - originalError', () {
    test('stores originalError when provided for all exception types', () {
      final original = Exception('test error');
      expect(NetworkException(message: 'e', originalError: original).originalError,
          equals(original));
      expect(ApiAuthException(message: 'e', originalError: original).originalError,
          equals(original));
      expect(ApiRateLimitException(message: 'e', originalError: original).originalError,
          equals(original));
      expect(ApiNotFoundException(message: 'e', originalError: original).originalError,
          equals(original));
      expect(ApiInternalServerError(message: 'e', originalError: original).originalError,
          equals(original));
      expect(DatabaseException(message: 'e', originalError: original).originalError,
          equals(original));
      expect(DatabaseNotFoundException(message: 'e', originalError: original).originalError,
          equals(original));
      expect(ValidationException(message: 'e', originalError: original).originalError,
          equals(original));
      expect(FileSystemException(message: 'e', originalError: original).originalError,
          equals(original));
      expect(PdfParseException(message: 'e', originalError: original).originalError,
          equals(original));
      expect(ContentGenerationException(message: 'e', originalError: original).originalError,
          equals(original));
      expect(LlmException(message: 'e', originalError: original).originalError,
          equals(original));
      expect(ApiKeyMissingException(message: 'e', originalError: original).originalError,
          equals(original));
      expect(InvalidApiKeyException(message: 'e', originalError: original).originalError,
          equals(original));
    });

    test('originalError is null by default for all exception types', () {
      expect(NetworkException(message: 'e').originalError, isNull);
      expect(ApiAuthException(message: 'e').originalError, isNull);
      expect(ApiRateLimitException(message: 'e').originalError, isNull);
      expect(ApiNotFoundException(message: 'e').originalError, isNull);
      expect(ApiInternalServerError(message: 'e').originalError, isNull);
      expect(DatabaseException(message: 'e').originalError, isNull);
      expect(DatabaseNotFoundException(message: 'e').originalError, isNull);
      expect(ValidationException(message: 'e').originalError, isNull);
      expect(FileSystemException(message: 'e').originalError, isNull);
      expect(PdfParseException(message: 'e').originalError, isNull);
      expect(ContentGenerationException(message: 'e').originalError, isNull);
      expect(LlmException(message: 'e').originalError, isNull);
      expect(ApiKeyMissingException(message: 'e').originalError, isNull);
      expect(InvalidApiKeyException(message: 'e').originalError, isNull);
    });
  });

  group('All exception types - custom code override', () {
    test('allows custom code to override default for all exception types', () {
      expect(NetworkException(message: 'e', code: 'OVERRIDE').code, equals('OVERRIDE'));
      expect(ApiAuthException(message: 'e', code: 'OVERRIDE').code, equals('OVERRIDE'));
      expect(ApiRateLimitException(message: 'e', code: 'OVERRIDE').code, equals('OVERRIDE'));
      expect(ApiNotFoundException(message: 'e', code: 'OVERRIDE').code, equals('OVERRIDE'));
      expect(ApiInternalServerError(message: 'e', code: 'OVERRIDE').code, equals('OVERRIDE'));
      expect(DatabaseException(message: 'e', code: 'OVERRIDE').code, equals('OVERRIDE'));
      expect(DatabaseNotFoundException(message: 'e', code: 'OVERRIDE').code, equals('OVERRIDE'));
      expect(ValidationException(message: 'e', code: 'OVERRIDE').code, equals('OVERRIDE'));
      expect(FileSystemException(message: 'e', code: 'OVERRIDE').code, equals('OVERRIDE'));
      expect(PdfParseException(message: 'e', code: 'OVERRIDE').code, equals('OVERRIDE'));
      expect(ContentGenerationException(message: 'e', code: 'OVERRIDE').code, equals('OVERRIDE'));
      expect(LlmException(message: 'e', code: 'OVERRIDE').code, equals('OVERRIDE'));
      expect(ApiKeyMissingException(message: 'e', code: 'OVERRIDE').code, equals('OVERRIDE'));
      expect(InvalidApiKeyException(message: 'e', code: 'OVERRIDE').code, equals('OVERRIDE'));
    });
  });

  group('All exception types - toString behavior', () {
    test('concrete exceptions use Object toString since they implement (not extend) AppException', () {
      expect(NetworkException(message: 'e').toString(), contains('Instance of'));
      expect(ApiAuthException(message: 'e').toString(), contains('Instance of'));
      expect(ApiRateLimitException(message: 'e').toString(), contains('Instance of'));
      expect(ApiNotFoundException(message: 'e').toString(), contains('Instance of'));
      expect(ApiInternalServerError(message: 'e').toString(), contains('Instance of'));
      expect(DatabaseException(message: 'e').toString(), contains('Instance of'));
      expect(DatabaseNotFoundException(message: 'e').toString(), contains('Instance of'));
      expect(ValidationException(message: 'e').toString(), contains('Instance of'));
      expect(FileSystemException(message: 'e').toString(), contains('Instance of'));
      expect(PdfParseException(message: 'e').toString(), contains('Instance of'));
      expect(ContentGenerationException(message: 'e').toString(), contains('Instance of'));
      expect(LlmException(message: 'e').toString(), contains('Instance of'));
      expect(ApiKeyMissingException(message: 'e').toString(), contains('Instance of'));
      expect(InvalidApiKeyException(message: 'e').toString(), contains('Instance of'));
    });

    test('AppException toString works correctly via class that extends AppException', () {
      const ex = _TestAppException(message: 'test message');
      expect(ex.toString(), equals('AppException: test message'));
    });
  });
}
