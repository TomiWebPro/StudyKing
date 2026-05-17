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
      const exception = AppException(message: 'test', type: ExceptionType.network);
      expect(AppErrorHandler.getRetryText(exception), equals('Retry Connection'));
    });

    test('returns "Retry After Wait" for ApiRateLimitException', () {
      const exception = AppException(message: 'test', type: ExceptionType.apiRateLimit);
      expect(AppErrorHandler.getRetryText(exception), equals('Retry After Wait'));
    });

    test('returns "Try again" for ApiInternalServerError', () {
      const exception = AppException(message: 'test', type: ExceptionType.apiInternalServer);
      expect(AppErrorHandler.getRetryText(exception), equals('Try again'));
    });

    test('returns "Retry" for other exception types', () {
      expect(AppErrorHandler.getRetryText(const AppException(message: 'test', type: ExceptionType.apiAuth)), equals('Retry'));
      expect(AppErrorHandler.getRetryText(const AppException(message: 'test', type: ExceptionType.database)), equals('Retry'));
      expect(AppErrorHandler.getRetryText(const AppException(message: 'test', type: ExceptionType.validation)), equals('Retry'));
      expect(AppErrorHandler.getRetryText(const AppException(message: 'test', type: ExceptionType.llm)), equals('Retry'));
      expect(AppErrorHandler.getRetryText(const AppException(message: 'test', type: ExceptionType.apiNotFound)), equals('Retry'));
      expect(AppErrorHandler.getRetryText(const AppException(message: 'test', type: ExceptionType.contentGeneration)), equals('Retry'));
      expect(AppErrorHandler.getRetryText(const AppException(message: 'test', type: ExceptionType.apiKeyMissing)), equals('Retry'));
      expect(AppErrorHandler.getRetryText(const AppException(message: 'test', type: ExceptionType.invalidApiKey)), equals('Retry'));
      expect(AppErrorHandler.getRetryText(const AppException(message: 'test', type: ExceptionType.pdfParse)), equals('Retry'));
    });
  });

  group('AppErrorHandler.convertToAppException', () {
    test('passes through existing AppException without conversion', () {
      const original = AppException(message: 'network error', type: ExceptionType.network);
      final result = AppErrorHandler.convertToAppException(original);
      expect(result, same(original));
      expect(result.type, ExceptionType.network);
    });

    test('converts ConnectionFailedError to AppException(network)', () {
      final error = Exception('ConnectionFailedError: timeout');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.network);
    });

    test('converts SocketException to AppException(network)', () {
      final error = Exception('SocketException: connection refused');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.network);
    });

    test('converts error with Network keyword to AppException(network)', () {
      final error = Exception('Network timeout');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.network);
    });

    test('converts error with "401" to AppException(invalidApiKey)', () {
      final error = Exception('401 Unauthorized');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.invalidApiKey);
    });

    test('converts error with "unauthorized" to AppException(invalidApiKey)', () {
      final error = Exception('unauthorized access');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.invalidApiKey);
    });

    test('converts error with "invalid" keyword to AppException(invalidApiKey)', () {
      final error = Exception('invalid credentials');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.invalidApiKey);
    });

    test('converts error with "403" to AppException(apiRateLimit)', () {
      final error = Exception('403 Forbidden');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.apiRateLimit);
    });

    test('converts error with "forbidden" keyword to AppException(apiRateLimit)', () {
      final error = Exception('forbidden access');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.apiRateLimit);
    });

    test('converts error with "404" to AppException(apiNotFound)', () {
      final error = Exception('404 Not Found');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.apiNotFound);
    });

    test('converts error with "not found" to AppException(apiNotFound)', () {
      final error = Exception('resource not found');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.apiNotFound);
    });

    test('converts error with "500" to AppException(apiInternalServer)', () {
      final error = Exception('500 Internal Server Error');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.apiInternalServer);
    });

    test('converts error with "502" to AppException(apiInternalServer)', () {
      final error = Exception('502 Bad Gateway');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.apiInternalServer);
    });

    test('converts error with "503" to AppException(apiInternalServer)', () {
      final error = Exception('503 Service Unavailable');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.apiInternalServer);
    });

    test('converts FormatException to AppException(validation)', () {
      final error = const FormatException('Invalid data format');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.validation);
    });

    test('converts StateError to AppException(database)', () {
      final error = StateError('Bad state');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.database);
    });

    test('converts AssertionError to AppException(database)', () {
      final error = AssertionError('assertion failed');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.database);
    });

    test('converts unknown generic error to AppException(network - default)', () {
      final error = Exception('Some random error');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.network);
    });

    test('priority: Network keyword takes precedence over invalid keyword', () {
      final error = Exception('Network invalid request');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.network);
    });

    test('error with "501" maps to default AppException(network)', () {
      final error = Exception('501 Not Implemented');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.network);
    });

    test('error with status 400 maps to default AppException(network)', () {
      final error = Exception('HTTP 400 Bad Request');
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.network);
    });

    test('TypeError is converted to default AppException(network)', () {
      final error = TypeError();
      final result = AppErrorHandler.convertToAppException(error);
      expect(result.type, ExceptionType.network);
    });
  });

  group('AppErrorHandler.logError (via logger spy)', () {
    test('logs error with correct tag and message', () {
      final spy = _SpyLogger();
      final originalLogger = AppErrorHandler.logger;
      AppErrorHandler.logger = spy;

      AppErrorHandler.logError(
        AppException(message: 'connection failed', type: ExceptionType.network),
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

      AppErrorHandler.logError(AppException(message: 'bad input', type: ExceptionType.validation), 'VALIDATION');

      AppErrorHandler.logger = originalLogger;

      expect(spy.errorMessages, isNotEmpty);
      expect(spy.errorMessages.first, contains('VALIDATION'));
    });
  });
}
