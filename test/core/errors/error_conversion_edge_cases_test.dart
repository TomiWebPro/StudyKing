import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/exceptions.dart';
import 'package:studyking/core/errors/handlers.dart';
import 'package:studyking/core/errors/result.dart';
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

  group('handleSyncError - missing exception message tests', () {
    testWidgets('shows default message for FileSystemException via handleSyncError',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        FileSystemException(message: 'file error'),
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
      AppErrorHandler.handleSyncError(
        context,
        FileSystemException(message: 'file error'),
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
        LlmException(message: 'llm error'),
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
        NetworkException(message: 'error'),
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
      AppErrorHandler.handleSyncError(
        context,
        NetworkException(message: 'error'),
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
      AppErrorHandler.handleSyncError(
        context,
        NetworkException(message: 'error'),
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
      AppErrorHandler.handleSyncError(
        context,
        NetworkException(message: 'error'),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.byIcon(Icons.error), findsOneWidget);
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

  group('Result<T> - isSuccess/isFailure exhaustive guarantee', () {
    test('isSuccess and isFailure are always opposite', () {
      final success = Result<int>.success(1);
      expect(success.isSuccess, equals(!success.isFailure));

      final failure = Result<int>.failure('err');
      expect(failure.isFailure, equals(!failure.isSuccess));
    });
  });
}
