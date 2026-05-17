import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/exceptions.dart';
import 'package:studyking/core/errors/handlers.dart';
import 'shared_test_helpers.dart';

void main() {
  group('AppErrorHandler - SyllabusException', () {
    testWidgets('handleError displays localized message for unknown type', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'Syllabus format is invalid', type: ExceptionType.unknown),
        'test',
      );
      await tester.pump();
      expect(find.text('An unexpected error occurred. Please try again.'), findsOneWidget);
    });

    testWidgets('handleSyncError displays localized message for unknown type', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'Syllabus parsing failed', type: ExceptionType.unknown),
        'test',
      );
      await tester.pump();
      expect(find.text('An unexpected error occurred. Please try again.'), findsOneWidget);
    });

    testWidgets('handleError shows error_outline icon', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'test', type: ExceptionType.unknown),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('handleSyncError with retry shows retry button', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'test', type: ExceptionType.unknown),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('AppErrorHandler - PlanGenerationException', () {
    testWidgets('handleError displays localized message for unknown type', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'Plan generation timeout', type: ExceptionType.unknown),
        'test',
      );
      await tester.pump();
      expect(find.text('An unexpected error occurred. Please try again.'), findsOneWidget);
    });

    testWidgets('handleSyncError displays localized message for unknown type', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'No topics to plan', type: ExceptionType.unknown),
        'test',
      );
      await tester.pump();
      expect(find.text('An unexpected error occurred. Please try again.'), findsOneWidget);
    });

    testWidgets('handleError shows error_outline icon', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'test', type: ExceptionType.unknown),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('handleError with retry shows refresh icon and retry button',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'test', type: ExceptionType.unknown),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('handleSyncError with retry retryCallback is called',
        (tester) async {
      final context = await captureContext(tester);
      bool tapped = false;
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'test', type: ExceptionType.unknown),
        'test',
        retry: true,
        retryCallback: () {
          tapped = true;
        },
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Retry'), warnIfMissed: false);
      expect(tapped, isTrue);
    });
  });

  group('AppErrorHandler - SchedulingException', () {
    testWidgets('handleError displays localized message for unknown type', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'Time slot unavailable', type: ExceptionType.unknown),
        'test',
      );
      await tester.pump();
      expect(find.text('An unexpected error occurred. Please try again.'), findsOneWidget);
    });

    testWidgets('handleSyncError displays localized message for unknown type', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'Schedule conflict detected', type: ExceptionType.unknown),
        'test',
      );
      await tester.pump();
      expect(find.text('An unexpected error occurred. Please try again.'), findsOneWidget);
    });

    testWidgets('handleError shows error_outline icon', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'test', type: ExceptionType.unknown),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('handleError with retry callback is called', (tester) async {
      final context = await captureContext(tester);
      bool tapped = false;
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'test', type: ExceptionType.unknown),
        'test',
        retry: true,
        retryCallback: () {
          tapped = true;
        },
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Retry'), warnIfMissed: false);
      expect(tapped, isTrue);
    });
  });

  group('AppErrorHandler - AdherenceException', () {
    testWidgets('handleError displays localized message for unknown type', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'Study adherence below threshold', type: ExceptionType.unknown),
        'test',
      );
      await tester.pump();
      expect(find.text('An unexpected error occurred. Please try again.'), findsOneWidget);
    });

    testWidgets('handleSyncError displays localized message for unknown type', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'Missed too many sessions', type: ExceptionType.unknown),
        'test',
      );
      await tester.pump();
      expect(find.text('An unexpected error occurred. Please try again.'), findsOneWidget);
    });

    testWidgets('handleError shows error_outline icon', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'test', type: ExceptionType.unknown),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('handleSyncError SnackBar has correct duration', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'test', type: ExceptionType.unknown),
        'test',
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, equals(const Duration(seconds: 3)));
    });
  });

  group('AppErrorHandler.handleError - Icons', () {
    testWidgets('shows wifi_tethering_off icon for ContentGenerationException via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'gen error', type: ExceptionType.contentGeneration),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.wifi_tethering_off), findsOneWidget);
    });

    testWidgets('shows key_rounded icon for ApiKeyMissingException via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'key missing', type: ExceptionType.apiKeyMissing),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.key_rounded), findsOneWidget);
    });

    testWidgets('shows key_rounded icon for InvalidApiKeyException via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'invalid key', type: ExceptionType.invalidApiKey),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.key_rounded), findsOneWidget);
    });

    testWidgets('shows storage icon for FileSystemException via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'file error', type: ExceptionType.database),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.storage), findsOneWidget);
    });
  });

  group('AppErrorHandler - Private Method Coverage via Integration', () {
    testWidgets('_getErrorIcon returns correct icons for all exception types via handleError',
        (tester) async {
      final context = await captureContext(tester);

      final exceptions = [
        (AppException(message: 'e', type: ExceptionType.network), Icons.network_check),
        (AppException(message: 'e', type: ExceptionType.apiKeyMissing), Icons.key_rounded),
        (AppException(message: 'e', type: ExceptionType.invalidApiKey), Icons.key_rounded),
        (AppException(message: 'e', type: ExceptionType.apiAuth), Icons.key_rounded),
        (AppException(message: 'e', type: ExceptionType.apiRateLimit), Icons.pause_circle),
        (AppException(message: 'e', type: ExceptionType.apiNotFound), Icons.looks_one_outlined),
        (AppException(message: 'e', type: ExceptionType.apiInternalServer), Icons.bug_report),
        (AppException(message: 'e', type: ExceptionType.database), Icons.storage),
        (AppException(message: 'e', type: ExceptionType.validation), Icons.info),
        (AppException(message: 'e', type: ExceptionType.pdfParse), Icons.picture_as_pdf),
        (AppException(message: 'e', type: ExceptionType.contentGeneration), Icons.wifi_tethering_off),
        (AppException(message: 'e', type: ExceptionType.llm), Icons.wifi_tethering_off),
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

  group('AppErrorHandler.handleSyncError', () {
    testWidgets('shows NetworkException message', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'network error', type: ExceptionType.network),
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
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'auth error', type: ExceptionType.apiAuth),
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
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'missing key', type: ExceptionType.apiKeyMissing),
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
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'invalid key', type: ExceptionType.invalidApiKey),
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
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'rate limited', type: ExceptionType.apiRateLimit),
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
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'not found', type: ExceptionType.apiNotFound),
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
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'server error', type: ExceptionType.apiInternalServer),
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
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'db error', type: ExceptionType.database),
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
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'Custom validation error', type: ExceptionType.validation),
        'test',
      );
      await tester.pump();
      expect(find.text('Validation failed: Custom validation error'), findsOneWidget);
    });

    testWidgets('shows PdfParseException message', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'pdf error', type: ExceptionType.pdfParse),
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
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'gen error', type: ExceptionType.contentGeneration),
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
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'llm error', type: ExceptionType.llm),
        'test',
      );
      await tester.pump();
      expect(
        find.text('The AI service is temporarily unavailable. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows database error message for database exception type', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'not found', type: ExceptionType.database),
        'test',
      );
      await tester.pump();
      expect(
        find.text('A database error occurred. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows retry button when retry is true and callback provided',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'network error', type: ExceptionType.network),
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
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'network error', type: ExceptionType.network),
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
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'network error', type: ExceptionType.network),
        'test',
      );
      await tester.pump();
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('shows refresh icon when retry is true in handleSyncError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'network error', type: ExceptionType.network),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('AppErrorHandler.handleError (async)', () {
    testWidgets('shows error message for NetworkException', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'network error', type: ExceptionType.network),
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
        AppException(message: 'rate limited', type: ExceptionType.apiRateLimit),
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
        AppException(message: 'network error', type: ExceptionType.network),
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
        AppException(message: 'network error', type: ExceptionType.network),
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
        AppException(message: 'network error', type: ExceptionType.network),
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
        AppException(message: 'network error', type: ExceptionType.network),
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
        AppException(message: 'auth failed', type: ExceptionType.apiAuth),
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
        AppException(message: 'rate limited', type: ExceptionType.apiRateLimit),
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
        AppException(message: 'not found', type: ExceptionType.apiNotFound),
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
        AppException(message: 'server error', type: ExceptionType.apiInternalServer),
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
        AppException(message: 'db error', type: ExceptionType.database),
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
        AppException(message: 'validation error', type: ExceptionType.validation),
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
        AppException(message: 'pdf error', type: ExceptionType.pdfParse),
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
        AppException(message: 'llm error', type: ExceptionType.llm),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.wifi_tethering_off), findsOneWidget);
    });

    testWidgets('shows storage icon for database exception via handleError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'not found', type: ExceptionType.database),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.storage), findsOneWidget);
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
        () async => throw AppException(message: 'network error', type: ExceptionType.network),
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
        () async => throw AppException(message: 'error', type: ExceptionType.network),
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
        () => throw AppException(message: 'network error', type: ExceptionType.network),
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
        () => throw AppException(message: 'error', type: ExceptionType.network),
        contextName: 'test',
      );
      expect(result, isNull);
    });
  });

  group('AppErrorHandler.handleError - retry edge cases', () {
    testWidgets('handleError with retry:true and retryCallback:null shows icon not retry button',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'error', type: ExceptionType.network),
        'test',
        retry: true,
        retryCallback: null,
      );
      await tester.pump();
      expect(find.byIcon(Icons.network_check), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('handleError with retry:false and retryCallback:non-null shows icon not retry button',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'rate limit', type: ExceptionType.apiRateLimit),
        'test',
        retry: false,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.byIcon(Icons.pause_circle), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('handleError with retry:true callback:non-null shows refresh icon and retry button',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'error', type: ExceptionType.network),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('AppErrorHandler.handleError - message edge cases', () {
    testWidgets('handleError shows database error message for database exception',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'file error', type: ExceptionType.database),
        'test',
      );
      await tester.pump();
      expect(
        find.text('A database error occurred. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('handleError shows ApiRateLimitException message with retry',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'rate limit', type: ExceptionType.apiRateLimit),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(
        find.text('Too many requests. Please wait a moment and try again.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('AppErrorHandler.handleSyncError - retry edge cases', () {
    testWidgets('handleSyncError with retry:false and callback:non-null shows no retry button',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'auth error', type: ExceptionType.apiAuth),
        'test',
        retry: false,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.text('Retry'), findsNothing);
      expect(
        find.text('Authentication failed. Please check your API credentials.'),
        findsOneWidget,
      );
    });

    testWidgets('handleSyncError shows retry-specific text from getRetryText for NetworkException',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'network error', type: ExceptionType.network),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('handleSyncError shows retry-specific text for ApiRateLimitException',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'rate limit', type: ExceptionType.apiRateLimit),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('AppErrorHandler - sequential error handling', () {
    testWidgets('multiple sequential handleSyncError calls show correct messages',
        (tester) async {
      final context = await captureContext(tester);

      await AppErrorHandler.handleError(
        context,
        AppException(message: 'llm error', type: ExceptionType.llm),
        'op1',
      );
      await tester.pump();
      ScaffoldMessenger.of(context).clearSnackBars();
      await tester.pumpAndSettle();

      await AppErrorHandler.handleError(
        context,
        AppException(message: 'db not found', type: ExceptionType.database),
        'op2',
      );
      await tester.pump();
      expect(
        find.text('A database error occurred. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('multiple sequential handleError calls show correct messages',
        (tester) async {
      final context = await captureContext(tester);

      await AppErrorHandler.handleError(
        context,
        AppException(message: 'gen error', type: ExceptionType.contentGeneration),
        'op1',
      );
      await tester.pump();
      ScaffoldMessenger.of(context).clearSnackBars();
      await tester.pumpAndSettle();

      await AppErrorHandler.handleError(
        context,
        AppException(message: 'invalid key', type: ExceptionType.invalidApiKey),
        'op2',
      );
      await tester.pump();
      expect(
        find.text('Invalid API key. Please check your credentials in Settings.'),
        findsOneWidget,
      );
    });
  });

  group(
      'AppErrorHandler.handleError - retry/callback parameter combinations (duration & content)',
      () {
    testWidgets(
        'retry:true, retryCallback:null -> duration 4s, Row content with icon (no retry button)',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'key missing', type: ExceptionType.apiKeyMissing),
        'test',
        retry: true,
        retryCallback: null,
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, equals(const Duration(seconds: 4)));
      expect(snackBar.content, isA<Row>());
      expect(find.text('Retry'), findsNothing);
      expect(find.byIcon(Icons.key_rounded), findsOneWidget);
    });

    testWidgets(
        'retry:false, retryCallback:non-null -> duration 3s, icon Row (no retry button)',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'db error', type: ExceptionType.database),
        'test',
        retry: false,
        retryCallback: () {},
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, equals(const Duration(seconds: 3)));
      expect(snackBar.content, isA<Row>());
      expect(find.text('Retry'), findsNothing);
      expect(find.byIcon(Icons.storage), findsOneWidget);
    });
  });

  group(
      'AppErrorHandler.handleSyncError - retry/callback parameter combinations (duration & content)',
      () {
    testWidgets(
        'retry:true, retryCallback:null -> duration 3s, Text content (no retry button)',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'invalid key', type: ExceptionType.invalidApiKey),
        'test',
        retry: true,
        retryCallback: null,
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, equals(const Duration(seconds: 3)));
      expect(snackBar.content, isA<Row>());
      expect(find.text('Retry'), findsNothing);
      expect(
        find.text(
          'Invalid API key. Please check your credentials in Settings.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'retry:false, retryCallback:non-null -> duration 3s, Row content with icon (no retry button)',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'auth error', type: ExceptionType.apiAuth),
        'test',
        retry: false,
        retryCallback: () {},
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, equals(const Duration(seconds: 3)));
      expect(snackBar.content, isA<Row>());
      expect(find.text('Retry'), findsNothing);
      expect(
        find.text('Authentication failed. Please check your API credentials.'),
        findsOneWidget,
      );
    });
  });

  group('AppErrorHandler.handleError - long message content', () {
    testWidgets('very long error message truncates gracefully via Row layout',
        (tester) async {
      final context = await captureContext(tester);
      final longMessage = 'A' * 500;
      await AppErrorHandler.handleError(
        context,
        AppException(message: longMessage, type: ExceptionType.unknown),
        'test',
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.content, isA<Row>());
      expect(find.text(longMessage), findsOneWidget);
    });

    testWidgets('long message with retry shows truncated message and retry button',
        (tester) async {
      final context = await captureContext(tester);
      final longMessage = 'B' * 300;
      await AppErrorHandler.handleError(
        context,
        AppException(message: longMessage, type: ExceptionType.unknown),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.text(longMessage), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('AppErrorHandler.handleSyncError - long message content', () {
    testWidgets('very long error message in Text content', (tester) async {
      final context = await captureContext(tester);
      final longMessage = 'C' * 400;
      await AppErrorHandler.handleError(
        context,
        AppException(message: longMessage, type: ExceptionType.unknown),
        'test',
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.content, isA<Text>());
      expect(find.text(longMessage), findsOneWidget);
    });
  });

  group('AppErrorHandler.handleError - repeated calls without clearing', () {
    testWidgets('multiple handleError calls show the latest error',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'first', type: ExceptionType.network),
        'op1',
      );
      await tester.pump();
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'second', type: ExceptionType.invalidApiKey),
        'op2',
      );
      await tester.pump();
      expect(
        find.text(
          'Invalid API key. Please check your credentials in Settings.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('retry callback from first call is superseded by second',
        (tester) async {
      final context = await captureContext(tester);
      int firstTapCount = 0;
      int secondTapCount = 0;

      await AppErrorHandler.handleError(
        context,
        AppException(message: 'first', type: ExceptionType.network),
        'op1',
        retry: true,
        retryCallback: () {
          firstTapCount++;
        },
      );
      await tester.pump();

      await AppErrorHandler.handleError(
        context,
        AppException(message: 'second', type: ExceptionType.network),
        'op2',
        retry: true,
        retryCallback: () {
          secondTapCount++;
        },
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Retry'), warnIfMissed: false);
      expect(secondTapCount, equals(1));
      expect(firstTapCount, equals(0));
    });
  });

  group('AppErrorHandler.handleSyncError - repeated calls without clearing',
      () {
    testWidgets('multiple handleSyncError calls show the latest error',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'first', type: ExceptionType.apiKeyMissing),
        'op1',
      );
      await tester.pump();
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'second', type: ExceptionType.contentGeneration),
        'op2',
      );
      await tester.pump();
      expect(
        find.text('Failed to generate content. Please try again.'),
        findsOneWidget,
      );
    });
  });

  group('AppErrorHandler - multiple retry button taps', () {
    testWidgets('tapping retry button twice calls callback twice via handleError',
        (tester) async {
      final context = await captureContext(tester);
      int tapCount = 0;
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'error', type: ExceptionType.network),
        'test',
        retry: true,
        retryCallback: () {
          tapCount++;
        },
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Retry'), warnIfMissed: false);
      await tester.tap(find.text('Retry'), warnIfMissed: false);
      expect(tapCount, equals(2));
    });
  });

  group(
      'AppErrorHandler.handleError - SnackBar content type for non-retry Row',
      () {
    testWidgets('non-retry error content uses Row with mainAxisSize.min',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'not found', type: ExceptionType.apiNotFound),
        'test',
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final row = snackBar.content as Row;
      expect(row.mainAxisSize, equals(MainAxisSize.min));
    });
  });

  group('AppErrorHandler - database-related error types via handleSyncError',
      () {
    testWidgets('DatabaseNotFoundException shows default message via handleSyncError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'db not found', type: ExceptionType.database),
        'test',
      );
      await tester.pump();
      expect(
        find.text('An unexpected error occurred. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'DatabaseNotFoundException with retry shows retry button and default message',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'db not found', type: ExceptionType.database),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(
        find.text('An unexpected error occurred. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('AppErrorHandler - safely with various context names', () {
    testWidgets('safely uses contextName for logging', (tester) async {
      final context = await captureContext(tester);
      final result = await AppErrorHandler.safely<int>(
        context,
        () async => throw AppException(message: 'Low adherence', type: ExceptionType.unknown),
        defaultValue: 0,
        contextName: 'ADHERENCE_CHECK',
      );
      expect(result, equals(0));
    });

    testWidgets('safelySync uses contextName for logging', (tester) async {
      final context = await captureContext(tester);
      final result = AppErrorHandler.safelySync<String>(
        context,
        () => throw AppException(message: 'LLM unavailable', type: ExceptionType.llm),
        defaultValue: 'FALLBACK',
        contextName: 'LLM_QUERY',
      );
      expect(result, equals('FALLBACK'));
    });
  });

  group('AppErrorHandler.handleError - SnackBar Behavior', () {
    testWidgets('has floating behavior on SnackBar via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'error', type: ExceptionType.network),
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
        AppException(message: 'error', type: ExceptionType.network),
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
        AppException(message: 'error', type: ExceptionType.network),
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
        AppException(message: 'error', type: ExceptionType.network),
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
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'error', type: ExceptionType.network),
        'test',
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, equals(SnackBarBehavior.floating));
    });

    testWidgets('has correct duration (3 seconds) on SnackBar via handleSyncError without retry', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'error', type: ExceptionType.network),
        'test',
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, equals(const Duration(seconds: 3)));
    });

    testWidgets('has extended duration (4 seconds) when retry is true via handleSyncError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'error', type: ExceptionType.network),
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
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'error', type: ExceptionType.network),
        'test',
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(Colors.red.shade800));
    });

    testWidgets('does not show retry button when retryCallback is null even if retry is true',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'error', type: ExceptionType.network),
        'test',
        retry: true,
        retryCallback: null,
      );
      await tester.pump();
      expect(find.text('Retry'), findsNothing);
    });
  });

  group('AppErrorHandler.handleError - Retry Functionality', () {
    testWidgets('retry callback is not called immediately after showing snackbar',
        (tester) async {
      final context = await captureContext(tester);
      bool retryCalled = false;
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'error', type: ExceptionType.network),
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
        AppException(message: 'error', type: ExceptionType.network),
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
        () async => throw AppException(message: 'error', type: ExceptionType.network),
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
        () async => throw AppException(message: 'Field X is required', type: ExceptionType.validation),
        contextName: 'test',
      );
      await tester.pump();
      expect(find.text('Validation failed: Field X is required'), findsOneWidget);
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
        () => throw AppException(message: 'error', type: ExceptionType.database),
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

  group('Edge Cases and Edge Coverage', () {
    testWidgets('handles empty context name', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'error', type: ExceptionType.network),
        '',
      );
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('handleError handles exception with no message gracefully', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: '', type: ExceptionType.network),
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
        () async => throw AppException(message: 'LLM error', type: ExceptionType.llm),
        defaultValue: 'LLM_FALLBACK',
        contextName: 'LLM_OP',
      );
      expect(result, equals('LLM_FALLBACK'));
    });

    testWidgets('safelySync handles sync operation that throws and returns default', (tester) async {
      final context = await captureContext(tester);
      final result = AppErrorHandler.safelySync<String>(
        context,
        () => throw AppException(message: 'LLM error', type: ExceptionType.llm),
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
        AppException(message: 'rate limited', type: ExceptionType.apiRateLimit),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('Too many requests. Please wait a moment and try again.'), findsOneWidget);
    });
  });

  group('handleSyncError - missing exception message tests', () {
    testWidgets('shows default message for FileSystemException via handleSyncError',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'file error', type: ExceptionType.database),
        'test',
      );
      await tester.pump();
      expect(
        find.text('An unexpected error occurred. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('handleSyncError with retry shows retry button for FileSystemException',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'file error', type: ExceptionType.database),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('handleError - LlmException message test', () {
    testWidgets('shows LlmException message via handleError', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'llm error', type: ExceptionType.llm),
        'test',
      );
      await tester.pump();
      expect(
        find.text('The AI service is temporarily unavailable. Please try again.'),
        findsOneWidget,
      );
    });
  });

  group('handleError - SnackBar content structure', () {
    testWidgets('non-retry SnackBar shows error icon Row', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'error', type: ExceptionType.network),
        'test',
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.content, isA<Row>());
    });
  });

  group('handleSyncError - SnackBar content structure', () {
    testWidgets('non-retry SnackBar shows Text content', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'error', type: ExceptionType.network),
        'test',
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.content, isA<Text>());
    });

    testWidgets('retry SnackBar shows Row with error icon and retry button',
        (tester) async {
      final context = await captureContext(tester);
      bool tapped = false;
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'error', type: ExceptionType.network),
        'test',
        retry: true,
        retryCallback: () {
          tapped = true;
        },
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.content, isA<Row>());

      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Retry'), warnIfMissed: false);
      expect(tapped, isTrue);
    });

    testWidgets('retry SnackBar shows error icon', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AppException(message: 'error', type: ExceptionType.network),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
  });
}
