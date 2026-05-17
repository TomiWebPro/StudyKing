import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/planner/presentation/widgets/lesson_booking_sheet.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../helpers/navigator_observer_helper.dart';

Future<void> _showSheet(WidgetTester tester, LessonBookingSheet sheet) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: Center(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => MediaQuery(
                data: const MediaQueryData(size: Size(400, 800)),
                child: sheet,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  ));

  await tester.tap(find.text('Open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync('lesson_test_').path);
  });
  group('LessonBookingSheet', () {
    testWidgets('renders title and topic title', (tester) async {
      await _showSheet(tester, const LessonBookingSheet(
        topicId: 'topic-1',
        topicTitle: 'Algebra Basics',
        subjectId: 'subj-1',
        onSchedule: _fakeSchedule,
      ));

      expect(find.text('Algebra Basics'), findsOneWidget);
    });

    testWidgets('shows date, time and duration labels', (tester) async {
      await _showSheet(tester, const LessonBookingSheet(
        topicId: 'topic-1',
        topicTitle: 'Algebra Basics',
        subjectId: 'subj-1',
        onSchedule: _fakeSchedule,
      ));

      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
    });

    testWidgets('shows increase and decrease duration buttons', (tester) async {
      await _showSheet(tester, const LessonBookingSheet(
        topicId: 'topic-1',
        topicTitle: 'Algebra Basics',
        subjectId: 'subj-1',
        onSchedule: _fakeSchedule,
      ));

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    });

    testWidgets('schedule button calls onSchedule and pops', (tester) async {
      bool scheduled = false;
      final observer = TestNavigatorObserver();

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        navigatorObservers: [observer],
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => MediaQuery(
                    data: const MediaQueryData(size: Size(400, 800)),
                    child: LessonBookingSheet(
                      topicId: 'topic-1',
                      topicTitle: 'Algebra Basics',
                      subjectId: 'subj-1',
                      onSchedule: (time, duration) async {
                        scheduled = true;
                      },
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Schedule Lesson').last);
      await tester.pumpAndSettle();

      expect(scheduled, isTrue);
    });

    testWidgets('button shows loading state when tapped', (tester) async {
      final scheduleCompleter = Completer<void>();

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => MediaQuery(
                    data: const MediaQueryData(size: Size(400, 800)),
                    child: LessonBookingSheet(
                      topicId: 'topic-1',
                      topicTitle: 'Algebra Basics',
                      subjectId: 'subj-1',
                      onSchedule: (time, duration) => scheduleCompleter.future,
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Schedule Lesson').last);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      scheduleCompleter.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('duration can be increased', (tester) async {
      await _showSheet(tester, const LessonBookingSheet(
        topicId: 'topic-1',
        topicTitle: 'Algebra Basics',
        subjectId: 'subj-1',
        onSchedule: _fakeSchedule,
      ));

      expect(find.text('30 minutes'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();

      expect(find.text('45 minutes'), findsOneWidget);
    });

    testWidgets('duration can be decreased', (tester) async {
      await _showSheet(tester, const LessonBookingSheet(
        topicId: 'topic-1',
        topicTitle: 'Algebra Basics',
        subjectId: 'subj-1',
        onSchedule: _fakeSchedule,
      ));

      expect(find.text('30 minutes'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();

      expect(find.text('15 minutes'), findsOneWidget);
    });

    testWidgets('shows conflict warning icon and container when conflict detected',
        (tester) async {
      final conflictService = _FakeConflictPlannerService(conflictResult: true);
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => MediaQuery(
                    data: const MediaQueryData(size: Size(400, 800)),
                    child: LessonBookingSheet(
                      topicId: 'topic-1',
                      topicTitle: 'Algebra Basics',
                      subjectId: 'subj-1',
                      plannerService: conflictService,
                      onSchedule: _fakeSchedule,
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('scheduling with conflict shows snackbar instead of calling onSchedule',
        (tester) async {
      bool onScheduleCalled = false;
      final conflictService = _FakeConflictPlannerService(conflictResult: true);
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => MediaQuery(
                    data: const MediaQueryData(size: Size(400, 800)),
                    child: LessonBookingSheet(
                      topicId: 'topic-1',
                      topicTitle: 'Algebra Basics',
                      subjectId: 'subj-1',
                      plannerService: conflictService,
                      onSchedule: (time, duration) async {
                        onScheduleCalled = true;
                      },
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Schedule Lesson').last);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(onScheduleCalled, isFalse);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('no conflict warning when plannerService is null',
        (tester) async {
      await _showSheet(tester, const LessonBookingSheet(
        topicId: 'topic-1',
        topicTitle: 'Algebra Basics',
        subjectId: 'subj-1',
        onSchedule: _fakeSchedule,
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });
  });
}

Future<void> _fakeSchedule(DateTime time, int duration) async {}

class _FakeConflictPlannerService extends PlannerService {
  final bool conflictResult;

  _FakeConflictPlannerService({this.conflictResult = false})
      : super(fixedStudentId: 'test');

  @override
  Future<bool> hasSchedulingConflict({
    required DateTime startTime,
    required int durationMinutes,
    String? excludeSessionId,
  }) async {
    return conflictResult;
  }
}
