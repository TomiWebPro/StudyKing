import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/focus_timer_widget.dart';

Widget _buildTestApp(Widget widget) {
  return MaterialApp(
    home: Scaffold(
      body: widget,
    ),
  );
}

void main() {
  group('FocusTimerWidget', () {
    testWidgets('renders timer with remaining time', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 0,
        ),
      ));

      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('remaining'), findsOneWidget);
    });

    testWidgets('shows elapsed time correctly', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 300,
        ),
      ));

      expect(find.text('20:00'), findsOneWidget);
    });

    testWidgets('shows PAUSED state', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 60,
          isPaused: true,
        ),
      ));

      expect(find.text('PAUSED'), findsOneWidget);
    });

    testWidgets('shows DONE when elapsed equals planned', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 1500,
          isActive: true,
        ),
      ));

      expect(find.text('DONE!'), findsOneWidget);
    });

    testWidgets('shows pause button when active and not paused', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 0,
          isActive: true,
          isPaused: false,
        ),
      ));

      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Resume'), findsNothing);
    });

    testWidgets('shows resume button when paused', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 60,
          isActive: true,
          isPaused: true,
        ),
      ));

      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Pause'), findsNothing);
    });

    testWidgets('shows End button when active', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 0,
          isActive: true,
        ),
      ));

      expect(find.text('End'), findsOneWidget);
    });

    testWidgets('shows Mark Complete button when active and not paused', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 60,
          isActive: true,
          isPaused: false,
        ),
      ));

      expect(find.text('Mark Complete'), findsOneWidget);
    });

    testWidgets('hides Mark Complete when paused', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 60,
          isActive: true,
          isPaused: true,
        ),
      ));

      expect(find.text('Mark Complete'), findsNothing);
    });

    testWidgets('hides control buttons when not active', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 0,
          isActive: false,
        ),
      ));

      expect(find.text('Pause'), findsNothing);
      expect(find.text('Resume'), findsNothing);
      expect(find.text('End'), findsNothing);
      expect(find.text('Mark Complete'), findsNothing);
    });

    testWidgets('calls onPause when pause button tapped', (tester) async {
      bool paused = false;
      await tester.pumpWidget(_buildTestApp(
        FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 0,
          isActive: true,
          onPause: () => paused = true,
        ),
      ));

      await tester.tap(find.text('Pause'));
      expect(paused, isTrue);
    });

    testWidgets('calls onResume when resume button tapped', (tester) async {
      bool resumed = false;
      await tester.pumpWidget(_buildTestApp(
        FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 60,
          isActive: true,
          isPaused: true,
          onResume: () => resumed = true,
        ),
      ));

      await tester.tap(find.text('Resume'));
      expect(resumed, isTrue);
    });

    testWidgets('calls onCancel when End button tapped', (tester) async {
      bool cancelled = false;
      await tester.pumpWidget(_buildTestApp(
        FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 0,
          isActive: true,
          onCancel: () => cancelled = true,
        ),
      ));

      await tester.tap(find.text('End'));
      expect(cancelled, isTrue);
    });

    testWidgets('calls onComplete when Mark Complete tapped', (tester) async {
      bool completed = false;
      await tester.pumpWidget(_buildTestApp(
        FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 60,
          isActive: true,
          onComplete: () => completed = true,
        ),
      ));

      await tester.tap(find.text('Mark Complete'));
      expect(completed, isTrue);
    });

    testWidgets('hides Mark Complete when remaining is 0', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 1500,
          isActive: true,
          isPaused: false,
        ),
      ));

      expect(find.text('Mark Complete'), findsNothing);
    });

    testWidgets('formats hours correctly', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 120,
          elapsedSeconds: 0,
        ),
      ));

      expect(find.text('02:00:00'), findsOneWidget);
    });

    testWidgets('handles zero planned duration', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 0,
          elapsedSeconds: 0,
        ),
      ));

      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('shows circular progress indicator', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 0,
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
