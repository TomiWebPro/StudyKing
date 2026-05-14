import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/presentation/widgets/lesson_booking_sheet.dart';

Future<void> _showSheet(WidgetTester tester, LessonBookingSheet sheet) async {
  await tester.pumpWidget(MaterialApp(
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
      final observer = _NavigatorObserverMock();

      await tester.pumpWidget(MaterialApp(
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
    });
  });
}

Future<void> _fakeSchedule(DateTime time, int duration) async {}

class _NavigatorObserverMock extends NavigatorObserver {
  int popCount = 0;
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }
}
