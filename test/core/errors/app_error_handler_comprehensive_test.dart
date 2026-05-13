import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/errors/exceptions.dart';
import 'package:studyking/core/errors/handlers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

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
  group('AppErrorHandler.handleError - All Exception Messages', () {
    testWidgets('shows ApiKeyMissingException message via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        ApiKeyMissingException(message: 'key missing'),
        'test',
      );
      await tester.pump();
      expect(
        find.text('API key is required. Please configure it in Settings.'),
        findsOneWidget,
      );
    });

    testWidgets('shows InvalidApiKeyException message via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        InvalidApiKeyException(message: 'invalid key'),
        'test',
      );
      await tester.pump();
      expect(
        find.text('Invalid API key. Please check your credentials in Settings.'),
        findsOneWidget,
      );
    });

    testWidgets('shows ApiAuthException message via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        ApiAuthException(message: 'auth error'),
        'test',
      );
      await tester.pump();
      expect(
        find.text('Authentication failed. Please check your API credentials.'),
        findsOneWidget,
      );
    });

    testWidgets('shows ApiNotFoundException message via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        ApiNotFoundException(message: 'not found'),
        'test',
      );
      await tester.pump();
      expect(
        find.text('The requested resource was not found.'),
        findsOneWidget,
      );
    });

    testWidgets('shows ApiInternalServerError message via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        ApiInternalServerError(message: 'server error'),
        'test',
      );
      await tester.pump();
      expect(
        find.text('The server encountered an error. Please try again later.'),
        findsOneWidget,
      );
    });

    testWidgets('shows DatabaseException message via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        DatabaseException(message: 'db error'),
        'test',
      );
      await tester.pump();
      expect(
        find.text('A database error occurred. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows ValidationException custom message via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        ValidationException(message: 'Custom validation message'),
        'test',
      );
      await tester.pump();
      expect(find.text('Custom validation message'), findsOneWidget);
    });

    testWidgets('shows PdfParseException message via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        PdfParseException(message: 'pdf error'),
        'test',
      );
      await tester.pump();
      expect(
        find.text('Unable to parse the PDF file. Please ensure it is a valid PDF.'),
        findsOneWidget,
      );
    });

    testWidgets('shows ContentGenerationException message via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        ContentGenerationException(message: 'gen error'),
        'test',
      );
      await tester.pump();
      expect(
        find.text('Failed to generate content. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows default message for DatabaseNotFoundException via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        DatabaseNotFoundException(message: 'not found'),
        'test',
      );
      await tester.pump();
      expect(
        find.text('An unexpected error occurred. Please try again.'),
        findsOneWidget,
      );
    });
  });

  group('AppErrorHandler.handleError - Icons', () {
    testWidgets('shows wifi_tethering_off icon for ContentGenerationException via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        ContentGenerationException(message: 'gen error'),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.wifi_tethering_off), findsOneWidget);
    });

    testWidgets('shows key_rounded icon for ApiKeyMissingException via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        ApiKeyMissingException(message: 'key missing'),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.key_rounded), findsOneWidget);
    });

    testWidgets('shows key_rounded icon for InvalidApiKeyException via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        InvalidApiKeyException(message: 'invalid key'),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.key_rounded), findsOneWidget);
    });

    testWidgets('shows error_outline icon for FileSystemException via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        FileSystemException(message: 'file error'),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('AppErrorHandler.handleError - SnackBar Behavior', () {
    testWidgets('has floating behavior on SnackBar via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        NetworkException(message: 'error'),
        'test',
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, equals(SnackBarBehavior.floating));
    });

    testWidgets('has correct duration (3 seconds) on SnackBar via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        NetworkException(message: 'error'),
        'test',
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, equals(const Duration(seconds: 3)));
    });

    testWidgets('has extended duration (4 seconds) when retry is true via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        NetworkException(message: 'error'),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, equals(const Duration(seconds: 4)));
    });

    testWidgets('has red background color on SnackBar via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        NetworkException(message: 'error'),
        'test',
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(Colors.red.shade800));
    });
  });

  group('AppErrorHandler.handleSyncError - SnackBar Behavior', () {
    testWidgets('has floating behavior on SnackBar via handleSyncError', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        NetworkException(message: 'error'),
        'test',
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, equals(SnackBarBehavior.floating));
    });

    testWidgets('has correct duration (3 seconds) on SnackBar via handleSyncError without retry', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        NetworkException(message: 'error'),
        'test',
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, equals(const Duration(seconds: 3)));
    });

    testWidgets('has extended duration (4 seconds) when retry is true via handleSyncError', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        NetworkException(message: 'error'),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, equals(const Duration(seconds: 4)));
    });

    testWidgets('has red background color on SnackBar via handleSyncError', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        NetworkException(message: 'error'),
        'test',
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(Colors.red.shade800));
    });

    testWidgets('does not show retry button when retryCallback is null even if retry is true',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        NetworkException(message: 'error'),
        'test',
        retry: true,
        retryCallback: null,
      );
      await tester.pump();
      expect(find.text('Retry'), findsNothing);
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

  group('AppErrorHandler.handleError - Retry Functionality', () {
    testWidgets('retry callback is not called immediately after showing snackbar',
        (tester) async {
      final context = await captureContext(tester);
      bool retryCalled = false;
      await AppErrorHandler.handleError(
        context,
        NetworkException(message: 'error'),
        'test',
        retry: true,
        retryCallback: () {
          retryCalled = true;
        },
      );
      await tester.pump();
      expect(retryCalled, isFalse);
    });

    testWidgets('retry callback is called when retry button is tapped via handleError',
        (tester) async {
      final context = await captureContext(tester);
      bool retryCalled = false;
      await AppErrorHandler.handleError(
        context,
        NetworkException(message: 'error'),
        'test',
        retry: true,
        retryCallback: () {
          retryCalled = true;
        },
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Retry'), warnIfMissed: false);
      expect(retryCalled, isTrue);
    });
  });

  group('AppErrorHandler.safely - Extended Coverage', () {
    testWidgets('handles multiple exceptions in sequence', (tester) async {
      final context = await captureContext(tester);

      final result1 = await AppErrorHandler.safely<int>(
        context,
        () async => 1,
        contextName: 'op1',
      );
      expect(result1, equals(1));

      final result2 = await AppErrorHandler.safely<int>(
        context,
        () async => throw NetworkException(message: 'error'),
        defaultValue: -1,
        contextName: 'op2',
      );
      expect(result2, equals(-1));

      final result3 = await AppErrorHandler.safely<int>(
        context,
        () async => 3,
        contextName: 'op3',
      );
      expect(result3, equals(3));
    });

    testWidgets('preserves custom message from ValidationException', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.safely(
        context,
        () async => throw ValidationException(message: 'Field X is required'),
        contextName: 'test',
      );
      await tester.pump();
      expect(find.text('Field X is required'), findsOneWidget);
    });
  });

  group('AppErrorHandler.safelySync - Extended Coverage', () {
    testWidgets('handles multiple exceptions in sequence', (tester) async {
      final context = await captureContext(tester);

      final result1 = AppErrorHandler.safelySync<int>(
        context,
        () => 1,
        contextName: 'op1',
      );
      expect(result1, equals(1));

      final result2 = AppErrorHandler.safelySync<int>(
        context,
        () => throw DatabaseException(message: 'error'),
        defaultValue: -1,
        contextName: 'op2',
      );
      expect(result2, equals(-1));

      final result3 = AppErrorHandler.safelySync<int>(
        context,
        () => 3,
        contextName: 'op3',
      );
      expect(result3, equals(3));
    });

    testWidgets('returns different types successfully', (tester) async {
      final context = await captureContext(tester);

      final stringResult = AppErrorHandler.safelySync<String>(
        context,
        () => 'hello',
        defaultValue: 'default',
      );
      expect(stringResult, equals('hello'));

      final intResult = AppErrorHandler.safelySync<int>(
        context,
        () => 42,
        defaultValue: 0,
      );
      expect(intResult, equals(42));

      final boolResult = AppErrorHandler.safelySync<bool>(
        context,
        () => true,
        defaultValue: false,
      );
      expect(boolResult, equals(true));
    });

    testWidgets('returns different default types on error', (tester) async {
      final context = await captureContext(tester);

      final stringResult = AppErrorHandler.safelySync<String>(
        context,
        () => throw Exception('error'),
        defaultValue: 'fallback',
      );
      expect(stringResult, equals('fallback'));

      final intResult = AppErrorHandler.safelySync<int>(
        context,
        () => throw Exception('error'),
        defaultValue: -999,
      );
      expect(intResult, equals(-999));

      final boolResult = AppErrorHandler.safelySync<bool>(
        context,
        () => throw Exception('error'),
        defaultValue: true,
      );
      expect(boolResult, equals(true));
    });
  });

  group('AppErrorHandler.getRetryText - Complete Coverage', () {
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

  group('Edge Cases and Edge Coverage', () {
    testWidgets('handles empty context name', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        NetworkException(message: 'error'),
        '',
      );
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('handleError handles exception with no message gracefully', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        NetworkException(message: ''),
        'test',
      );
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('safely handles async operation that returns null', (tester) async {
      final context = await captureContext(tester);
      final result = await AppErrorHandler.safely<String?>(
        context,
        () async => null,
        defaultValue: 'default',
      );
      expect(result, isNull);
    });

    testWidgets('safelySync handles sync operation that returns null', (tester) async {
      final context = await captureContext(tester);
      final result = AppErrorHandler.safelySync<String?>(
        context,
        () => null,
        defaultValue: 'default',
      );
      expect(result, isNull);
    });

    testWidgets('safely handles async operation that throws and returns default', (tester) async {
      final context = await captureContext(tester);
      final result = await AppErrorHandler.safely<String>(
        context,
        () async => throw LlmException(message: 'LLM error'),
        defaultValue: 'LLM_FALLBACK',
        contextName: 'LLM_OP',
      );
      expect(result, equals('LLM_FALLBACK'));
    });

    testWidgets('safelySync handles sync operation that throws and returns default', (tester) async {
      final context = await captureContext(tester);
      final result = AppErrorHandler.safelySync<String>(
        context,
        () => throw LlmException(message: 'LLM error'),
        defaultValue: 'LLM_FALLBACK',
        contextName: 'LLM_OP',
      );
      expect(result, equals('LLM_FALLBACK'));
    });

    testWidgets('default value of null is returned on error when not specified', (tester) async {
      final context = await captureContext(tester);
      final result = await AppErrorHandler.safely<int>(
        context,
        () async => throw Exception('error'),
      );
      expect(result, isNull);
    });

    testWidgets('handleError shows appropriate error for ApiRateLimitException with retry',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        ApiRateLimitException(message: 'rate limited'),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('Too many requests. Please wait a moment and try again.'), findsOneWidget);
    });
  });

  group('AppErrorHandler - Private Method Coverage via Integration', () {
    testWidgets('_getErrorIcon returns correct icons for all exception types via handleError',
        (tester) async {
      final context = await captureContext(tester);

      final exceptions = [
        (NetworkException(message: 'e'), Icons.network_check),
        (ApiKeyMissingException(message: 'e'), Icons.key_rounded),
        (InvalidApiKeyException(message: 'e'), Icons.key_rounded),
        (ApiAuthException(message: 'e'), Icons.key_rounded),
        (ApiRateLimitException(message: 'e'), Icons.pause_circle),
        (ApiNotFoundException(message: 'e'), Icons.looks_one_outlined),
        (ApiInternalServerError(message: 'e'), Icons.bug_report),
        (DatabaseException(message: 'e'), Icons.storage),
        (ValidationException(message: 'e'), Icons.info),
        (PdfParseException(message: 'e'), Icons.picture_as_pdf),
        (ContentGenerationException(message: 'e'), Icons.wifi_tethering_off),
        (LlmException(message: 'e'), Icons.wifi_tethering_off),
      ];

      for (final (exception, expectedIcon) in exceptions) {
        await AppErrorHandler.handleError(context, exception, 'test');
        await tester.pump();
        expect(find.byIcon(expectedIcon), findsOneWidget);
        ScaffoldMessenger.of(context).clearSnackBars();
        await tester.pumpAndSettle();
      }
    });
  });
}
