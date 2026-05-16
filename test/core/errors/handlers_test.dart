import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/exceptions.dart';
import 'package:studyking/core/errors/handlers.dart';
import 'package:studyking/core/utils/logger.dart';

class _SpyLogger extends Logger {
  final List<String> errorMessages = [];

  _SpyLogger() : super('AppErrorHandler');

  @override
  void e(String message, [Object? error, StackTrace? stack]) {
    errorMessages.add(message);
  }
}

void main() {
  group('AppErrorHandler.getRetryText', () {
    test('returns "Retry Connection" for NetworkException', () {
      final exception = NetworkException(message: 'test');
      expect(AppErrorHandler.getRetryText(exception), equals('Retry Connection'));
    });

    test('returns "Retry After Wait" for ApiRateLimitException', () {
      final exception = ApiRateLimitException(message: 'test');
      expect(AppErrorHandler.getRetryText(exception), equals('Retry After Wait'));
    });

    test('returns "Try again" for ApiInternalServerError', () {
      final exception = ApiInternalServerError(message: 'test');
      expect(AppErrorHandler.getRetryText(exception), equals('Try again'));
    });

    test('returns "Retry" for other exception types', () {
      expect(AppErrorHandler.getRetryText(ApiAuthException(message: 'test')), equals('Retry'));
      expect(AppErrorHandler.getRetryText(DatabaseException(message: 'test')), equals('Retry'));
      expect(AppErrorHandler.getRetryText(ValidationException(message: 'test')), equals('Retry'));
      expect(AppErrorHandler.getRetryText(LlmException(message: 'test')), equals('Retry'));
      expect(AppErrorHandler.getRetryText(DatabaseNotFoundException(message: 'test')), equals('Retry'));
      expect(AppErrorHandler.getRetryText(FileSystemException(message: 'test')), equals('Retry'));
      expect(AppErrorHandler.getRetryText(PdfParseException(message: 'test')), equals('Retry'));
      expect(AppErrorHandler.getRetryText(ApiNotFoundException(message: 'test')), equals('Retry'));
      expect(AppErrorHandler.getRetryText(ContentGenerationException(message: 'test')), equals('Retry'));
      expect(AppErrorHandler.getRetryText(ApiKeyMissingException(message: 'test')), equals('Retry'));
      expect(AppErrorHandler.getRetryText(InvalidApiKeyException(message: 'test')), equals('Retry'));
      expect(AppErrorHandler.getRetryText(SyllabusException(message: 'test')), equals('Retry'));
      expect(AppErrorHandler.getRetryText(PlanGenerationException(message: 'test')), equals('Retry'));
      expect(AppErrorHandler.getRetryText(SchedulingException(message: 'test')), equals('Retry'));
      expect(AppErrorHandler.getRetryText(AdherenceException(message: 'test')), equals('Retry'));
    });
  });

  group('AppErrorHandler.convertToAppException', () {
    test('passes through existing AppException without conversion', () {
      final original = NetworkException(message: 'network error');
      final result = AppErrorHandler.convertToAppException(original);
      expect(result, same(original));
      expect(result, isA<NetworkException>());
    });

    test('converts ConnectionFailedError to NetworkException', () {
      final error = Exception('ConnectionFailedError: timeout');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<NetworkException>());
    });

    test('converts SocketException to NetworkException', () {
      final error = Exception('SocketException: connection refused');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<NetworkException>());
    });

    test('converts error with Network keyword to NetworkException', () {
      final error = Exception('Network timeout');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<NetworkException>());
    });

    test('converts error with "401" to InvalidApiKeyException', () {
      final error = Exception('401 Unauthorized');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<InvalidApiKeyException>());
    });

    test('converts error with "unauthorized" to InvalidApiKeyException', () {
      final error = Exception('unauthorized access');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<InvalidApiKeyException>());
    });

    test('converts error with "invalid" keyword to InvalidApiKeyException', () {
      final error = Exception('invalid credentials');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<InvalidApiKeyException>());
    });

    test('converts error with "403" to ApiRateLimitException', () {
      final error = Exception('403 Forbidden');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<ApiRateLimitException>());
    });

    test('converts error with "forbidden" keyword to ApiRateLimitException', () {
      final error = Exception('forbidden access');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<ApiRateLimitException>());
    });

    test('converts error with "404" to ApiNotFoundException', () {
      final error = Exception('404 Not Found');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<ApiNotFoundException>());
    });

    test('converts error with "not found" to ApiNotFoundException', () {
      final error = Exception('resource not found');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<ApiNotFoundException>());
    });

    test('converts error with "500" to ApiInternalServerError', () {
      final error = Exception('500 Internal Server Error');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<ApiInternalServerError>());
    });

    test('converts error with "502" to ApiInternalServerError', () {
      final error = Exception('502 Bad Gateway');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<ApiInternalServerError>());
    });

    test('converts error with "503" to ApiInternalServerError', () {
      final error = Exception('503 Service Unavailable');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<ApiInternalServerError>());
    });

    test('converts FormatException to ValidationException', () {
      final error = const FormatException('Invalid data format');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<ValidationException>());
      expect((result as ValidationException).message, contains('Invalid data format'));
    });

    test('converts StateError to DatabaseException', () {
      final error = StateError('Bad state');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<DatabaseException>());
    });

    test('converts AssertionError to DatabaseException', () {
      final error = AssertionError('assertion failed');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<DatabaseException>());
    });

    test('converts unknown generic error to NetworkException (default)', () {
      final error = Exception('Some random error');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<NetworkException>());
    });

    test('priority: Network keyword takes precedence over invalid keyword', () {
      final error = Exception('Network invalid request');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<NetworkException>());
    });

    test('FormatException with Network text maps to NetworkException (string check before type check)', () {
      final error = FormatException('Network error occurred');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<NetworkException>());
    });

    test('error with "501" maps to default NetworkException', () {
      final error = Exception('501 Not Implemented');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<NetworkException>());
    });

    test('error with status 400 maps to default NetworkException', () {
      final error = Exception('HTTP 400 Bad Request');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<NetworkException>());
    });

    test('TypeError is converted to default NetworkException', () {
      final error = TypeError();
      final result = AppErrorHandler.convertToAppException(error);
      expect(result, isA<NetworkException>());
    });
  });

  group('AppErrorHandler.logError (via logger spy)', () {
    test('logs error with correct tag and message', () {
      final spy = _SpyLogger();
      final originalLogger = AppErrorHandler.logger;
      AppErrorHandler.logger = spy;

      AppErrorHandler.logError(
        NetworkException(message: 'connection failed'),
        'TEST_OP',
      );

      AppErrorHandler.logger = originalLogger;

      expect(spy.errorMessages, isNotEmpty);
      expect(spy.errorMessages.first, contains('TEST_OP'));
      expect(spy.errorMessages.first, contains('connection failed'));
    });

    test('logs correct context name for different operations', () {
      final spy = _SpyLogger();
      final originalLogger = AppErrorHandler.logger;
      AppErrorHandler.logger = spy;

      AppErrorHandler.logError(ValidationException(message: 'bad input'), 'VALIDATION');

      AppErrorHandler.logger = originalLogger;

      expect(spy.errorMessages, isNotEmpty);
      expect(spy.errorMessages.first, contains('VALIDATION'));
    });
  });
}
