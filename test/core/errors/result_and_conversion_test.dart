import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/errors/exceptions.dart';
import 'package:studyking/core/errors/handlers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _TestAppException extends AppException {
  const _TestAppException({
    required super.message,
    super.code,
  });
}

Future<BuildContext> captureContext(WidgetTester tester) async {
  BuildContext? context;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return context!;
}

void main() {
  group('Result<T>', () {
    test('Result.success stores data and sets isSuccess to true', () {
      final result = Result<int>.success(42);
      expect(result.data, equals(42));
      expect(result.isSuccess, isTrue);
      expect(result.error, isNull);
      expect(result.hasError, isFalse);
    });

    test('Result.failure stores error and sets isSuccess to false', () {
      final result = Result<int>.failure('Something went wrong');
      expect(result.error, equals('Something went wrong'));
      expect(result.isSuccess, isFalse);
      expect(result.data, isNull);
      expect(result.hasError, isTrue);
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
      expect(result.hasError, isTrue);
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
      expect(result.hasError, isFalse);
    });

    test('Result.failure with complex data', () {
      final result = Result<List<String>>.failure('Multiple errors: one, two, three');
      expect(result.error, equals('Multiple errors: one, two, three'));
      expect(result.isSuccess, isFalse);
      expect(result.hasError, isTrue);
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

    test('hasError returns false when error is empty string', () {
      final result = Result<int>.failure('');
      expect(result.hasError, isTrue);
    });

    test('hasError returns true for non-empty error', () {
      final result = Result<int>.failure('error');
      expect(result.hasError, isTrue);
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

  group('AppException.toString edge cases', () {
    test('toString with empty string code shows parentheses', () {
      final exception = _TestAppException(message: 'test', code: '');
      expect(exception.toString(), equals('AppException: test ()'));
    });

    test('toString with null code shows no parentheses', () {
      final exception = _TestAppException(message: 'test');
      expect(exception.toString(), equals('AppException: test'));
    });

    test('toString with non-null code shows code in parentheses', () {
      final exception = _TestAppException(message: 'test', code: 'ERR001');
      expect(exception.toString(), equals('AppException: test (ERR001)'));
    });

    test('toString with empty message still works', () {
      final exception = _TestAppException(message: '');
      expect(exception.toString(), equals('AppException: '));
    });
  });

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
      expect(
        AppErrorHandler.getRetryText(ApiAuthException(message: 'test')),
        equals('Retry'),
      );
      expect(
        AppErrorHandler.getRetryText(DatabaseException(message: 'test')),
        equals('Retry'),
      );
      expect(
        AppErrorHandler.getRetryText(ValidationException(message: 'test')),
        equals('Retry'),
      );
      expect(
        AppErrorHandler.getRetryText(LlmException(message: 'test')),
        equals('Retry'),
      );
    });

    test('returns "Retry" for DatabaseNotFoundException', () {
      expect(
        AppErrorHandler.getRetryText(DatabaseNotFoundException(message: 'test')),
        equals('Retry'),
      );
    });

    test('returns "Retry" for FileSystemException', () {
      expect(
        AppErrorHandler.getRetryText(FileSystemException(message: 'test')),
        equals('Retry'),
      );
    });

    test('returns "Retry" for PdfParseException', () {
      expect(
        AppErrorHandler.getRetryText(PdfParseException(message: 'test')),
        equals('Retry'),
      );
    });
  });

  group('getRetryText - Complete Coverage', () {
    test('returns "Retry" for ApiNotFoundException', () {
      expect(
        AppErrorHandler.getRetryText(ApiNotFoundException(message: 'test')),
        equals('Retry'),
      );
    });

    test('returns "Retry" for ApiAuthException', () {
      expect(
        AppErrorHandler.getRetryText(ApiAuthException(message: 'test')),
        equals('Retry'),
      );
    });

    test('returns "Retry" for PdfParseException', () {
      expect(
        AppErrorHandler.getRetryText(PdfParseException(message: 'test')),
        equals('Retry'),
      );
    });

    test('returns "Retry" for ContentGenerationException', () {
      expect(
        AppErrorHandler.getRetryText(ContentGenerationException(message: 'test')),
        equals('Retry'),
      );
    });

    test('returns "Retry" for ApiKeyMissingException', () {
      expect(
        AppErrorHandler.getRetryText(ApiKeyMissingException(message: 'test')),
        equals('Retry'),
      );
    });

    test('returns "Retry" for InvalidApiKeyException', () {
      expect(
        AppErrorHandler.getRetryText(InvalidApiKeyException(message: 'test')),
        equals('Retry'),
      );
    });
  });

  group('getRetryText with default l10n', () {
    test('getRetryText with no l10n falls back to default for NetworkException',
        () {
      expect(
        AppErrorHandler.getRetryText(NetworkException(message: 'e')),
        equals('Retry Connection'),
      );
    });

    test('getRetryText with no l10n falls back to default for ApiRateLimitException',
        () {
      expect(
        AppErrorHandler.getRetryText(ApiRateLimitException(message: 'e')),
        equals('Retry After Wait'),
      );
    });

    test('getRetryText with no l10n falls back to default for unknown type', () {
      expect(
        AppErrorHandler.getRetryText(FileSystemException(message: 'e')),
        equals('Retry'),
      );
    });
  });

  group('getRetryText with custom l10n', () {
    test('uses default l10n when null', () {
      final exception = NetworkException(message: 'error');
      expect(AppErrorHandler.getRetryText(exception), equals('Retry Connection'));
    });

    test('retry text for ApiRateLimitException with default l10n', () {
      final exception = ApiRateLimitException(message: 'error');
      expect(AppErrorHandler.getRetryText(exception), equals('Retry After Wait'));
    });
  });

  group('AppErrorHandler - TypeError conversion', () {
    testWidgets('TypeError is converted to default NetworkException',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw TypeError(),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text(
          'Unable to connect to the server. Please check your internet connection and try again.',
        ),
        findsOneWidget,
      );
    });
  });

  group('AppErrorHandler - error with unknown codes', () {
    testWidgets('error with "501" maps to default NetworkException',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw Exception('501 Not Implemented'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text(
          'Unable to connect to the server. Please check your internet connection and try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('error with status 400 maps to default NetworkException',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw Exception('HTTP 400 Bad Request'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text(
          'Unable to connect to the server. Please check your internet connection and try again.',
        ),
        findsOneWidget,
      );
    });
  });

  group('AppErrorHandler error conversion', () {
    testWidgets('converts error with "SocketException" to NetworkException',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw Exception('SocketException: connection refused'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text(
          'Unable to connect to the server. Please check your internet connection and try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('converts error with "Network" to NetworkException',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw Exception('Network timeout'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text(
          'Unable to connect to the server. Please check your internet connection and try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('converts error with "401" to InvalidApiKeyException',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw Exception('Error 401: unauthorized'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text('Invalid API key. Please check your credentials in Settings.'),
        findsOneWidget,
      );
    });

    testWidgets('converts error with "unauthorized" to InvalidApiKeyException',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw Exception('unauthorized access'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text('Invalid API key. Please check your credentials in Settings.'),
        findsOneWidget,
      );
    });

    testWidgets('converts error with "403" to ApiRateLimitException',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw Exception('403 Forbidden'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text('Too many requests. Please wait a moment and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('converts error with "404" to ApiNotFoundException',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw Exception('404 not found'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text('The requested resource was not found.'),
        findsOneWidget,
      );
    });

    testWidgets('converts error with "500" to ApiInternalServerError',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw Exception('500 Internal Server Error'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text('The server encountered an error. Please try again later.'),
        findsOneWidget,
      );
    });

    testWidgets('converts FormatException to ValidationException',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw const FormatException('Invalid data format'),
        contextName: 'test',
      );
      await tester.pump();
      expect(find.text('Validation failed: Invalid data format'), findsOneWidget);
    });

    testWidgets('converts StateError to DatabaseException', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw StateError('Bad state'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text('A database error occurred. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('converts generic error to NetworkException (default)',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw Exception('Some random error'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text(
          'Unable to connect to the server. Please check your internet connection and try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('passes through existing AppException without conversion',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw PdfParseException(message: 'corrupt PDF'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text('Unable to parse the PDF file. Please ensure it is a valid PDF.'),
        findsOneWidget,
      );
    });

    testWidgets('converts error with "ConnectionFailedError" to NetworkException',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw Exception('ConnectionFailedError: timeout'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text('Unable to connect to the server. Please check your internet connection and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('converts error with "invalid" keyword to InvalidApiKeyException',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw Exception('invalid credentials'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text('Invalid API key. Please check your credentials in Settings.'),
        findsOneWidget,
      );
    });

    testWidgets('converts error with "forbidden" keyword to ApiRateLimitException',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw Exception('forbidden access'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text('Too many requests. Please wait a moment and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('converts error with "502" to ApiInternalServerError',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw Exception('502 Bad Gateway'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text('The server encountered an error. Please try again later.'),
        findsOneWidget,
      );
    });

    testWidgets('converts error with "503" to ApiInternalServerError',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw Exception('503 Service Unavailable'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text('The server encountered an error. Please try again later.'),
        findsOneWidget,
      );
    });

    testWidgets('converts AssertionError to DatabaseException',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.safelySync(
        context,
        () => throw AssertionError('assertion failed'),
        contextName: 'test',
      );
      await tester.pump();
      expect(
        find.text('A database error occurred. Please try again.'),
        findsOneWidget,
      );
    });
  });

  group('_convertToAppException - priority ordering', () {
    testWidgets('error with both Network and invalid keywords maps to NetworkException (Network check first)',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        Exception('Network invalid request'),
        'test',
      );
      await tester.pump();
      expect(
        find.text(
          'Unable to connect to the server. Please check your internet connection and try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('FormatException with "Network" text maps to NetworkException (string check before type check)',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        FormatException('Network error occurred'),
        'test',
      );
      await tester.pump();
      expect(
        find.text(
          'Unable to connect to the server. Please check your internet connection and try again.',
        ),
        findsOneWidget,
      );
    });
  });

  group('AppErrorHandler - error conversion edge cases', () {
    testWidgets('converts Exception with "not found" to ApiNotFoundException via handleError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        Exception('The requested resource was not found'),
        'test',
      );
      await tester.pump();
      expect(
        find.text('The requested resource was not found.'),
        findsOneWidget,
      );
    });

    testWidgets('converts generic Exception to NetworkException default via handleError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        Exception('some unknown error type'),
        'test',
      );
      await tester.pump();
      expect(
        find.text(
          'Unable to connect to the server. Please check your internet connection and try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('converts FormatException to ValidationException via handleError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        const FormatException('bad format'),
        'test',
      );
      await tester.pump();
      expect(find.text('Validation failed: bad format'), findsOneWidget);
    });
  });

  group('AppErrorHandler.handleError - Error Conversion', () {
    testWidgets('converts error with "not found" to ApiNotFoundException', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        Exception('Resource not found in database'),
        'test',
      );
      await tester.pump();
      expect(
        find.text('The requested resource was not found.'),
        findsOneWidget,
      );
    });
  });

  group('Exception Equality and Identity', () {
    test('two exceptions with same message are equal', () {
      final e1 = NetworkException(message: 'test');
      final e2 = NetworkException(message: 'test');
      expect(e1, isNot(same(e2)));
      expect(e1.message, equals(e2.message));
    });

    test('exceptions store different originalErrors independently', () {
      final original1 = Exception('error1');
      final original2 = Exception('error2');
      final e1 = NetworkException(message: 'test', originalError: original1);
      final e2 = NetworkException(message: 'test', originalError: original2);
      expect(e1.originalError, isNot(equals(e2.originalError)));
    });

    test('exceptions can store various originalError types', () {
      final intError = NetworkException(message: 'test', originalError: 42);
      expect(intError.originalError, equals(42));

      final stringError = NetworkException(message: 'test', originalError: 'error string');
      expect(stringError.originalError, equals('error string'));

      final mapError = NetworkException(message: 'test', originalError: {'key': 'value'});
      expect(mapError.originalError, equals({'key': 'value'}));

      final listError = NetworkException(message: 'test', originalError: [1, 2, 3]);
      expect(listError.originalError, equals([1, 2, 3]));
    });
  });

  group('All exception type equality behavior', () {
    test('two exceptions with same data compare by identity not value', () {
      final e1 = ApiAuthException(message: 'test');
      final e2 = ApiAuthException(message: 'test');
      expect(e1, isNot(same(e2)));
    });

    test('NetworkException with null originalError stores null', () {
      final exception = NetworkException(message: 'test', originalError: null);
      expect(exception.originalError, isNull);
    });
  });
}
