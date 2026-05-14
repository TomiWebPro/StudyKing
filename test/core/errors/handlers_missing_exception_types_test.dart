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
  group('AppErrorHandler - SyllabusException', () {
    testWidgets('handleError displays exception.message', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        SyllabusException(message: 'Syllabus format is invalid'),
        'test',
      );
      await tester.pump();
      expect(find.text('Syllabus format is invalid'), findsOneWidget);
    });

    testWidgets('handleSyncError displays exception.message', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        SyllabusException(message: 'Syllabus parsing failed'),
        'test',
      );
      await tester.pump();
      expect(find.text('Syllabus parsing failed'), findsOneWidget);
    });

    test('getRetryText returns Retry', () {
      expect(
        AppErrorHandler.getRetryText(SyllabusException(message: 'test')),
        equals('Retry'),
      );
    });

    testWidgets('handleError shows error_outline icon', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        SyllabusException(message: 'test'),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('handleSyncError with retry shows retry button', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        SyllabusException(message: 'test'),
        'test',
        retry: true,
        retryCallback: () {},
      );
      await tester.pump();
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('AppErrorHandler - PlanGenerationException', () {
    testWidgets('handleError displays exception.message', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        PlanGenerationException(message: 'Plan generation timeout'),
        'test',
      );
      await tester.pump();
      expect(find.text('Plan generation timeout'), findsOneWidget);
    });

    testWidgets('handleSyncError displays exception.message', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        PlanGenerationException(message: 'No topics to plan'),
        'test',
      );
      await tester.pump();
      expect(find.text('No topics to plan'), findsOneWidget);
    });

    test('getRetryText returns Retry', () {
      expect(
        AppErrorHandler.getRetryText(PlanGenerationException(message: 'test')),
        equals('Retry'),
      );
    });

    testWidgets('handleError shows error_outline icon', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        PlanGenerationException(message: 'test'),
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
        PlanGenerationException(message: 'test'),
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
      AppErrorHandler.handleSyncError(
        context,
        PlanGenerationException(message: 'test'),
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
    testWidgets('handleError displays exception.message', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        SchedulingException(message: 'Time slot unavailable'),
        'test',
      );
      await tester.pump();
      expect(find.text('Time slot unavailable'), findsOneWidget);
    });

    testWidgets('handleSyncError displays exception.message', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        SchedulingException(message: 'Schedule conflict detected'),
        'test',
      );
      await tester.pump();
      expect(find.text('Schedule conflict detected'), findsOneWidget);
    });

    test('getRetryText returns Retry', () {
      expect(
        AppErrorHandler.getRetryText(SchedulingException(message: 'test')),
        equals('Retry'),
      );
    });

    testWidgets('handleError shows error_outline icon', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        SchedulingException(message: 'test'),
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
        SchedulingException(message: 'test'),
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
    testWidgets('handleError displays exception.message', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AdherenceException(message: 'Study adherence below threshold'),
        'test',
      );
      await tester.pump();
      expect(find.text('Study adherence below threshold'), findsOneWidget);
    });

    testWidgets('handleSyncError displays exception.message', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        AdherenceException(message: 'Missed too many sessions'),
        'test',
      );
      await tester.pump();
      expect(find.text('Missed too many sessions'), findsOneWidget);
    });

    test('getRetryText returns Retry', () {
      expect(
        AppErrorHandler.getRetryText(AdherenceException(message: 'test')),
        equals('Retry'),
      );
    });

    testWidgets('handleError shows error_outline icon', (tester) async {
      final context = await captureContext(tester);
      await AppErrorHandler.handleError(
        context,
        AdherenceException(message: 'test'),
        'test',
      );
      await tester.pump();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('handleSyncError SnackBar has correct duration', (tester) async {
      final context = await captureContext(tester);
      AppErrorHandler.handleSyncError(
        context,
        AdherenceException(message: 'test'),
        'test',
      );
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, equals(const Duration(seconds: 3)));
    });
  });

  group('AppErrorHandler - getRetryText coverage for all missing types', () {
    test('returns Retry for SyllabusException', () {
      expect(
        AppErrorHandler.getRetryText(SyllabusException(message: 'e')),
        equals('Retry'),
      );
    });

    test('returns Retry for PlanGenerationException', () {
      expect(
        AppErrorHandler.getRetryText(PlanGenerationException(message: 'e')),
        equals('Retry'),
      );
    });

    test('returns Retry for SchedulingException', () {
      expect(
        AppErrorHandler.getRetryText(SchedulingException(message: 'e')),
        equals('Retry'),
      );
    });

    test('returns Retry for AdherenceException', () {
      expect(
        AppErrorHandler.getRetryText(AdherenceException(message: 'e')),
        equals('Retry'),
      );
    });
  });
}
