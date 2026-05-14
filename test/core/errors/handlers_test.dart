import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/errors/exceptions.dart';
import 'package:studyking/core/errors/handlers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget buildTestApp() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => const SizedBox(),
      ),
    ),
  );
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

  group('AppErrorHandler.handleSyncError', () {
    testWidgets('shows NetworkException message', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        NetworkException(message: 'network error'),
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

    testWidgets('shows ApiAuthException message', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
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

    testWidgets('shows ApiKeyMissingException message', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        ApiKeyMissingException(message: 'missing key'),
        'test',
      );
      await tester.pump();
      expect(
        find.text('API key is required. Please configure it in Settings.'),
        findsOneWidget,
      );
    });

    testWidgets('shows InvalidApiKeyException message', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
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

    testWidgets('shows ApiRateLimitException message', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        ApiRateLimitException(message: 'rate limited'),
        'test',
      );
      await tester.pump();
      expect(
        find.text('Too many requests. Please wait a moment and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows ApiNotFoundException message', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
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

    testWidgets('shows ApiInternalServerError message', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
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

    testWidgets('shows DatabaseException message', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
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

    testWidgets('shows ValidationException with its own message', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        ValidationException(message: 'Custom validation error'),
        'test',
      );
      await tester.pump();
      expect(find.text('Validation failed: Custom validation error'), findsOneWidget);
    });

    testWidgets('shows PdfParseException message', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
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

    testWidgets('shows ContentGenerationException message', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
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

    testWidgets('shows LlmException message', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        LlmException(message: 'llm error'),
        'test',
      );
      await tester.pump();
      expect(
        find.text('The AI service is temporarily unavailable. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows default message for unknown exception types', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
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

    testWidgets('shows retry button when retry is true and callback provided',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        NetworkException(message: 'network error'),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('calls retry callback when retry button is tapped',
        (tester) async {
      final context = await captureContext(tester);
      bool retryCalled = false;
      AppErrorHandler.handleSyncError(
        context,
        NetworkException(message: 'network error'),
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

    testWidgets('does not show retry button when retry is false',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        NetworkException(message: 'network error'),
        'test',
      );
      await tester.pump();
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('shows error icon when retry is true in handleSyncError',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        NetworkException(message: 'network error'),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
  });

  group('AppErrorHandler.handleError (async)', () {
    testWidgets('shows error message for NetworkException', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        NetworkException(message: 'network error'),
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

    testWidgets('shows error message for ApiRateLimitException', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        ApiRateLimitException(message: 'rate limited'),
        'test',
      );
      await tester.pump();
      expect(
        find.text('Too many requests. Please wait a moment and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows retry button when retry is true and callback provided',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        NetworkException(message: 'network error'),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('calls retry callback when retry button is tapped in handleError',
        (tester) async {
      final context = await captureContext(tester);
      bool retryCalled = false;
      await AppErrorHandler.handleError(
        context,
        NetworkException(message: 'network error'),
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

    testWidgets('shows refresh icon when retry is true in handleError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        NetworkException(message: 'network error'),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows network_check icon for NetworkException via handleError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        NetworkException(message: 'network error'),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.network_check), findsOneWidget);
    });

    testWidgets('shows key_rounded icon for ApiAuthException via handleError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        ApiAuthException(message: 'auth failed'),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.key_rounded), findsOneWidget);
    });

    testWidgets('shows pause_circle icon for ApiRateLimitException via handleError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        ApiRateLimitException(message: 'rate limited'),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.pause_circle), findsOneWidget);
    });

    testWidgets('shows looks_one_outlined icon for ApiNotFoundException via handleError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        ApiNotFoundException(message: 'not found'),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.looks_one_outlined), findsOneWidget);
    });

    testWidgets('shows bug_report icon for ApiInternalServerError via handleError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        ApiInternalServerError(message: 'server error'),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
    });

    testWidgets('shows storage icon for DatabaseException via handleError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        DatabaseException(message: 'db error'),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.storage), findsOneWidget);
    });

    testWidgets('shows info icon for ValidationException via handleError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        ValidationException(message: 'validation error'),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('shows picture_as_pdf icon for PdfParseException via handleError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        PdfParseException(message: 'pdf error'),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('shows wifi_tethering_off icon for LlmException via handleError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        LlmException(message: 'llm error'),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.wifi_tethering_off), findsOneWidget);
    });

    testWidgets('shows error_outline icon for default exception via handleError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        DatabaseNotFoundException(message: 'not found'),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('AppErrorHandler.safely', () {
    testWidgets('returns value from successful operation', (tester) async {
      final context = await captureContext(tester);
      final result = await AppErrorHandler.safely<int>(
        context,
        () async => 42,
        defaultValue: 0,
      );
      expect(result, equals(42));
    });

    testWidgets('returns default value on error and shows error UI',
        (tester) async {
      final context = await captureContext(tester);
      final result = await AppErrorHandler.safely<int>(
        context,
        () async => throw NetworkException(message: 'network error'),
        defaultValue: 0,
        contextName: 'test',
      );
      await tester.pump();
      expect(result, equals(0));
      expect(
        find.text(
          'Unable to connect to the server. Please check your internet connection and try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('returns null default when no default provided', (tester) async {
      final context = await captureContext(tester);
      final result = await AppErrorHandler.safely<int>(
        context,
        () async => throw NetworkException(message: 'error'),
        contextName: 'test',
      );
      expect(result, isNull);
    });
  });

  group('AppErrorHandler.safelySync', () {
    testWidgets('returns value from successful operation', (tester) async {
      final context = await captureContext(tester);
      final result = AppErrorHandler.safelySync<int>(
        context,
        () => 42,
        defaultValue: 0,
      );
      expect(result, equals(42));
    });

    testWidgets('returns default value on error and shows error UI',
        (tester) async {
      final context = await captureContext(tester);
      final result = AppErrorHandler.safelySync<int>(
        context,
        () => throw NetworkException(message: 'network error'),
        defaultValue: -1,
        contextName: 'test',
      );
      await tester.pump();
      expect(result, equals(-1));
      expect(
        find.text(
          'Unable to connect to the server. Please check your internet connection and try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('returns null default when no default provided', (tester) async {
      final context = await captureContext(tester);
      final result = AppErrorHandler.safelySync<int>(
        context,
        () => throw NetworkException(message: 'error'),
        contextName: 'test',
      );
      expect(result, isNull);
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
}
