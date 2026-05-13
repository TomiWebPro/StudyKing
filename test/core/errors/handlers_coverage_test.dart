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
  group('AppErrorHandler.handleError - retry edge cases', () {
    testWidgets('handleError with retry:true and retryCallback:null shows icon not retry button',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        NetworkException(message: 'error'),
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
        ApiRateLimitException(message: 'rate limit'),
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
        NetworkException(message: 'error'),
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
    testWidgets('handleError shows default message for FileSystemException',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
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

    testWidgets('handleError shows ApiRateLimitException message with retry',
        (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        ApiRateLimitException(message: 'rate limit'),
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
      AppErrorHandler.handleSyncError(
        context,
        ApiAuthException(message: 'auth error'),
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
      AppErrorHandler.handleSyncError(
        context,
        NetworkException(message: 'network error'),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.text('Retry Connection'), findsOneWidget);
    });

    testWidgets('handleSyncError shows retry-specific text for ApiRateLimitException',
        (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        ApiRateLimitException(message: 'rate limit'),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.text('Retry After Wait'), findsOneWidget);
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

  group('AppErrorHandler - sequential error handling', () {
    testWidgets('multiple sequential handleSyncError calls show correct messages',
        (tester) async {
      final context = await captureContext(tester);

      AppErrorHandler.handleSyncError(
        context,
        LlmException(message: 'llm error'),
        'op1',
      );
      await tester.pump();
      ScaffoldMessenger.of(context).clearSnackBars();
      await tester.pumpAndSettle();

      AppErrorHandler.handleSyncError(
        context,
        DatabaseNotFoundException(message: 'db not found'),
        'op2',
      );
      await tester.pump();
      expect(
        find.text('An unexpected error occurred. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('multiple sequential handleError calls show correct messages',
        (tester) async {
      final context = await captureContext(tester);

      await AppErrorHandler.handleError(
        context,
        ContentGenerationException(message: 'gen error'),
        'op1',
      );
      await tester.pump();
      ScaffoldMessenger.of(context).clearSnackBars();
      await tester.pumpAndSettle();

      await AppErrorHandler.handleError(
        context,
        InvalidApiKeyException(message: 'invalid key'),
        'op2',
      );
      await tester.pump();
      expect(
        find.text('Invalid API key. Please check your credentials in Settings.'),
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
      expect(find.text('Invalid data format'), findsOneWidget);
    });
  });
}
