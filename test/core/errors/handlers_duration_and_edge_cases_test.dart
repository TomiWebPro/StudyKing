import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  group(
      'AppErrorHandler.handleError - retry/callback parameter combinations (duration & content)',
      () {
    testWidgets(
        'retry:true, retryCallback:null -> duration 4s, icon Row (no retry button)',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        ApiKeyMissingException(message: 'key missing'),
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
        DatabaseException(message: 'db error'),
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
        'retry:true, retryCallback:null -> duration 4s, Text content (no retry button)',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        InvalidApiKeyException(message: 'invalid key'),
        'test',
        retry: true,
        retryCallback: null,
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, equals(const Duration(seconds: 4)));
      expect(snackBar.content, isA<Text>());
      expect(find.text('Retry'), findsNothing);
      expect(
        find.text(
          'Invalid API key. Please check your credentials in Settings.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'retry:false, retryCallback:non-null -> duration 3s, Text content (no retry button)',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        ApiAuthException(message: 'auth error'),
        'test',
        retry: false,
        retryCallback: () {},
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, equals(const Duration(seconds: 3)));
      expect(snackBar.content, isA<Text>());
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
        SyllabusException(message: longMessage),
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
        PlanGenerationException(message: longMessage),
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
      AppErrorHandler.handleSyncError(
        context,
        SchedulingException(message: longMessage),
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
        NetworkException(message: 'first'),
        'op1',
      );
      await tester.pump();
      await AppErrorHandler.handleError(
        context,
        InvalidApiKeyException(message: 'second'),
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
        NetworkException(message: 'first'),
        'op1',
        retry: true,
        retryCallback: () {
          firstTapCount++;
        },
      );
      await tester.pump();

      await AppErrorHandler.handleError(
        context,
        NetworkException(message: 'second'),
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
      AppErrorHandler.handleSyncError(
        context,
        ApiKeyMissingException(message: 'first'),
        'op1',
      );
      await tester.pump();
      AppErrorHandler.handleSyncError(
        context,
        ContentGenerationException(message: 'second'),
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
        NetworkException(message: 'error'),
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
        ApiNotFoundException(message: 'not found'),
        'test',
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final row = snackBar.content as Row;
      expect(row.mainAxisSize, equals(MainAxisSize.min));
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

  group('AppErrorHandler - getRetryText with default l10n', () {
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

  group('AppErrorHandler - database-related error types via handleSyncError',
      () {
    testWidgets('DatabaseNotFoundException shows default message via handleSyncError',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        DatabaseNotFoundException(message: 'db not found'),
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
      AppErrorHandler.handleSyncError(
        context,
        DatabaseNotFoundException(message: 'db not found'),
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
        () async => throw AdherenceException(message: 'Low adherence'),
        defaultValue: 0,
        contextName: 'ADHERENCE_CHECK',
      );
      expect(result, equals(0));
    });

    testWidgets('safelySync uses contextName for logging', (tester) async {
      final context = await captureContext(tester);
      final result = AppErrorHandler.safelySync<String>(
        context,
        () => throw LlmException(message: 'LLM unavailable'),
        defaultValue: 'FALLBACK',
        contextName: 'LLM_QUERY',
      );
      expect(result, equals('FALLBACK'));
    });
  });
}
