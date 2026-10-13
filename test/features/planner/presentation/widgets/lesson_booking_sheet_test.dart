import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/features/planner/data/adapters/student_availability_adapter.dart';
import 'package:studyking/features/planner/data/models/student_availability_model.dart';
import 'package:studyking/features/planner/presentation/widgets/lesson_booking_sheet.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../helpers/navigator_observer_helper.dart';

Future<void> _showSheet(WidgetTester tester, LessonBookingSheet sheet,
    {Locale locale = const Locale('en')}) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
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
  group('LessonBookingSheet', () {
    setUpAll(() {
      Hive.init(
        Directory.systemTemp.createTempSync('lesson_booking_').path,
      );
      if (!Hive.isAdapterRegistered(
        StudentAvailabilityModelAdapter().typeId,
      )) {
        Hive.registerAdapter(StudentAvailabilityModelAdapter());
      }
    });

    setUp(() async {
      // Start each test with an empty availability box so a record
      // written by one test cannot leak into another.
      final box = await Hive.openBox<StudentAvailabilityModel>(
        HiveBoxNames.studentAvailability,
      );
      await box.clear();
    });

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

    testWidgets('decrease button is disabled at 15 minutes', (tester) async {
      await _showSheet(tester, const LessonBookingSheet(
        topicId: 'topic-1',
        topicTitle: 'Algebra Basics',
        subjectId: 'subj-1',
        onSchedule: _fakeSchedule,
      ));

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();

      final decreaseButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.remove_circle_outline),
          matching: find.byType(IconButton),
        ),
      );
      expect(decreaseButton.onPressed, isNull);
    });

    testWidgets('increase button is disabled at 120 minutes', (tester) async {
      await _showSheet(tester, const LessonBookingSheet(
        topicId: 'topic-1',
        topicTitle: 'Algebra Basics',
        subjectId: 'subj-1',
        onSchedule: _fakeSchedule,
      ));

      for (var i = 0; i < 6; i++) {
        await tester.tap(find.byIcon(Icons.add_circle_outline));
      }
      await tester.pump();

      expect(find.text('120 minutes'), findsOneWidget);

      final increaseButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.add_circle_outline),
          matching: find.byType(IconButton),
        ),
      );
      expect(increaseButton.onPressed, isNull);
    });

    testWidgets(
        'shows conflict warning icon and container when conflict detected',
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

    testWidgets(
        'scheduling with conflict shows snackbar instead of calling onSchedule',
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

    testWidgets('renders schedule icon on button', (tester) async {
      await _showSheet(tester, const LessonBookingSheet(
        topicId: 'topic-1',
        topicTitle: 'Algebra Basics',
        subjectId: 'subj-1',
        onSchedule: _fakeSchedule,
      ));

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('renders drag handle at top', (tester) async {
      await _showSheet(tester, const LessonBookingSheet(
        topicId: 'topic-1',
        topicTitle: 'Algebra Basics',
        subjectId: 'subj-1',
        onSchedule: _fakeSchedule,
      ));

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets(
      'default time wraps past midnight (23:30 shows 12:00 AM, schedules at midnight)',
      (tester) async {
        DateTime? scheduledAt;
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
                        clock: _FakeClock(DateTime(2026, 10, 12, 23, 30)),
                        onSchedule: (time, duration) async {
                          scheduledAt = time;
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

        // One hour from 23:30 is hour 0, which renders as "12:00 AM" —
        // not "12:00 PM" (the old hour-24 behavior).
        expect(find.text('12:00 AM'), findsOneWidget);
        expect(find.text('12:00 PM'), findsNothing);

        await tester.tap(find.text('Schedule Lesson').last);
        await tester.pump();
        await tester.pumpAndSettle();

        // The scheduled DateTime must match the displayed midnight time on the
        // same day, not the next-day normalization of an invalid hour 24.
        expect(scheduledAt, DateTime(2026, 10, 12, 0, 0));
      },
    );

    testWidgets(
      'default time is one hour from now before midnight',
      (tester) async {
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
                        clock: _FakeClock(DateTime(2026, 10, 12, 10, 30)),
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

        expect(find.text('11:00 AM'), findsOneWidget);
      },
    );

    testWidgets(
      'localizes the reschedule confirmation dialog for the es locale',
      (tester) async {
        await _showSheet(
          tester,
          LessonBookingSheet(
            topicId: 'topic-1',
            topicTitle: 'Algebra Basics',
            subjectId: 'subj-1',
            initialDate: DateTime(2026, 1, 10, 10, 0),
            excludeSessionId: 'session-1',
            onSchedule: _fakeSchedule,
          ),
          locale: const Locale('es'),
        );

        await tester.tap(find.text('Programar Lección').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Reprogramar lección'), findsOneWidget);
        expect(
          find.textContaining('¿Mover la lección de Algebra Basics de'),
          findsOneWidget,
        );
        expect(find.textContaining('Esto actualizará tu horario.'), findsOneWidget);

        await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'cancelling the reschedule dialog after the sheet is removed does not setState after dispose',
      (tester) async {
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
                        initialDate: DateTime(2026, 1, 10, 10, 0),
                        excludeSessionId: 'session-1',
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

        // Scheduling an existing session opens the reschedule
        // confirmation dialog. Discrete pumps: the scheduling button
        // shows an indeterminate spinner while _isScheduling is true.
        await tester.tap(find.text('Schedule Lesson').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Reschedule lesson'), findsOneWidget);

        // The sheet's route is removed programmatically while the
        // confirmation dialog is open, disposing the sheet State.
        final sheetContext = tester.element(find.byType(LessonBookingSheet));
        final navigator = Navigator.of(sheetContext);
        navigator.removeRoute(ModalRoute.of(sheetContext)!);
        await tester.pump();
        expect(find.byType(LessonBookingSheet), findsNothing);

        // Cancelling completes the dialog future after disposal. The
        // finally block still resets _isScheduling, but only when
        // mounted — no "setState() called after dispose()".
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'reschedule keeps the lesson time and duration despite saved availability defaults',
      (tester) async {
        // The box is opened in setUp (normal zone); seeding a
        // record is real I/O, so it must run via runAsync —
        // real I/O events never fire inside a testWidgets body.
        final box = Hive.box<StudentAvailabilityModel>(
          HiveBoxNames.studentAvailability,
        );
        // Availability defaults differ from the lesson's scheduled
        // time (3:00 PM) and duration (45 minutes).
        await tester.runAsync(
          () => box.put(
            'test',
            StudentAvailabilityModel(
              studentId: 'test',
              preferredStartHour: 8,
              defaultSessionDurationMinutes: 90,
            ),
          ),
        );

        DateTime? scheduledAt;
        int? scheduledDuration;
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
                        plannerService:
                            _FakeConflictPlannerService(conflictResult: false),
                        initialDate: DateTime(2026, 1, 10, 15, 0),
                        initialDuration: 45,
                        excludeSessionId: 'session-1',
                        onSchedule: (time, duration) async {
                          scheduledAt = time;
                          scheduledDuration = duration;
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
        // _loadAvailability only reads the already-open box
        // in memory, so its microtasks are flushed by pump
        // and the rebuilt values are shown.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // The lesson's scheduled time (3:00 PM) and duration (45
        // minutes) win over the availability defaults (8:00 AM /
        // 90 minutes) on the reschedule path.
        expect(find.text('3:00 PM'), findsOneWidget);
        expect(find.text('8:00 AM'), findsNothing);
        expect(find.text('45 minutes'), findsOneWidget);
        expect(find.text('90 minutes'), findsNothing);

        // Confirming the reschedule writes the lesson's own values,
        // not the availability defaults.
        await tester.tap(find.text('Schedule Lesson').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Reschedule lesson'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(scheduledAt, DateTime(2026, 1, 10, 15, 0));
        expect(scheduledDuration, 45);
      },
    );

    testWidgets(
      'new booking applies saved availability defaults without crashing',
      (tester) async {
        // The box is opened in setUp (normal zone); seeding a
        // record is real I/O, so it must run via runAsync —
        // real I/O events never fire inside a testWidgets body.
        final box = Hive.box<StudentAvailabilityModel>(
          HiveBoxNames.studentAvailability,
        );
        await tester.runAsync(
          () => box.put(
            'test',
            StudentAvailabilityModel(
              studentId: 'test',
              preferredStartHour: 8,
              defaultSessionDurationMinutes: 90,
            ),
          ),
        );

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
                        plannerService:
                            _FakeConflictPlannerService(conflictResult: false),
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
        // _loadAvailability only reads the already-open box
        // in memory, so its microtasks are flushed by pump
        // and the rebuilt values are shown.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Availability defaults are applied for a new booking: the
        // preferred start hour (8:00 AM) and default duration (90
        // minutes) are shown, and no LateInitializationError is
        // thrown when updating the (mutable) selected time.
        expect(find.text('8:00 AM'), findsOneWidget);
        expect(find.text('90 minutes'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

class _FakeClock implements Clock {
  final DateTime fixed;

  _FakeClock(this.fixed);

  @override
  DateTime now() => fixed;
}

Future<void> _fakeSchedule(DateTime time, int duration) async {}

class _FakeConflictPlannerService extends PlannerService {
  final bool conflictResult;

  _FakeConflictPlannerService({this.conflictResult = false})
      : super(fixedStudentId: 'test');

  @override
  Future<Result<bool>> hasSchedulingConflict({
    required DateTime startTime,
    required int durationMinutes,
    String? excludeSessionId,
  }) async {
    return Result.success(conflictResult);
  }
}
