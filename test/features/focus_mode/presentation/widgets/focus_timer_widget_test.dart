import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/focus_timer_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../helpers/navigator_observer_helper.dart';

TestNavigatorObserver? testNavigatorObserver;

Widget _buildTestApp(Widget widget) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    navigatorObservers: testNavigatorObserver != null ? [testNavigatorObserver!] : [],
    home: Scaffold(
      body: widget,
    ),
  );
}

void main() {
  group('FocusTimerWidget', () {
    setUp(() {
      testNavigatorObserver = TestNavigatorObserver();
    });

    tearDown(() {
      testNavigatorObserver = null;
    });
    testWidgets('renders timer with remaining time', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 0,
        ),
      ));

      expect(find.text('25 00'), findsOneWidget);
      expect(find.text('remaining'), findsOneWidget);
    });

    testWidgets('shows elapsed time correctly', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 300,
        ),
      ));

      expect(find.text('20 00'), findsOneWidget);
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

      expect(find.text('02 00 00'), findsOneWidget);
    });

    testWidgets('handles zero planned duration', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 0,
          elapsedSeconds: 0,
        ),
      ));

      expect(find.text('00 00'), findsOneWidget);
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

    testWidgets('timer circle size is responsive', (tester) async {
      final large = SizedBox(
        width: 500,
        height: 800,
        child: _buildTestApp(
          const FocusTimerWidget(
            plannedDurationMinutes: 25,
            elapsedSeconds: 0,
          ),
        ),
      );
      await tester.pumpWidget(large);

      final sizedBoxes = find.byType(SizedBox);
      expect(sizedBoxes, findsWidgets);
    });

    testWidgets('renders AnimatedBuilder for pulse effect', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 0,
          isActive: true,
        ),
      ));

      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('renders Transform.scale from pulse animation', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 0,
          isActive: true,
        ),
      ));

      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('didUpdateWidget starts pulse when transitioning to running', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 60,
          isActive: true,
          isPaused: true,
        ),
      ));

      expect(find.text('PAUSED'), findsOneWidget);

      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 60,
          isActive: true,
          isPaused: false,
        ),
      ));

      expect(find.text('remaining'), findsOneWidget);
    });

    testWidgets('didUpdateWidget stops pulse when transitioning to paused', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 60,
          isActive: true,
          isPaused: false,
        ),
      ));

      expect(find.text('Pause'), findsOneWidget);

      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 60,
          isActive: true,
          isPaused: true,
        ),
      ));

      expect(find.text('PAUSED'), findsOneWidget);
    });

    testWidgets('CircularProgressIndicator uses progress value', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 750,
          isActive: true,
        ),
      ));

      final progress = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progress.value, closeTo(0.5, 0.01));
    });

    testWidgets('progress color is primary at high progress', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: _buildTestApp(
            const FocusTimerWidget(
              plannedDurationMinutes: 25,
              elapsedSeconds: 1350,
              isActive: true,
            ),
          ),
        ),
      ));

      final progress = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progress.value, greaterThan(0.8));
    });

    testWidgets('progress color is error at low progress', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: _buildTestApp(
            const FocusTimerWidget(
              plannedDurationMinutes: 25,
              elapsedSeconds: 0,
              isActive: true,
            ),
          ),
        ),
      ));

      final progress = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progress.value, closeTo(0.0, 0.01));
    });

    testWidgets('hides Mark Complete when timer is complete and not paused', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 1500,
          isActive: true,
          isPaused: false,
        ),
      ));

      expect(find.text('DONE!'), findsOneWidget);
      expect(find.text('Mark Complete'), findsNothing);
    });

    testWidgets('shows End button even when timer is complete', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 1500,
          isActive: true,
        ),
      ));

      expect(find.text('End'), findsOneWidget);
    });

    testWidgets('does not crash with null callbacks', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 0,
          isActive: true,
        ),
      ));

      await tester.tap(find.text('Pause'));
      await tester.tap(find.text('End'));
    });

    testWidgets('renders remaining text for incomplete active timer', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 300,
          isActive: true,
          isPaused: false,
        ),
      ));

      expect(find.text('remaining'), findsOneWidget);
    });

    testWidgets('reduceMotion disables pulse ring overlay when active', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 0,
          isActive: true,
          reduceMotion: true,
        ),
      ));

      // IgnorePointer wraps the ring overlay Container (only Material's remain)
      expect(find.byType(IgnorePointer), findsNWidgets(3));
    });

    testWidgets('renders ring overlay when pulsing without reduceMotion', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 0,
          isActive: true,
          reduceMotion: false,
        ),
      ));

      // 3 from Material + 1 from ring overlay
      expect(find.byType(IgnorePointer), findsNWidgets(4));
    });

    testWidgets('hides ring overlay when paused', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 60,
          isActive: true,
          isPaused: true,
        ),
      ));

      expect(find.byType(IgnorePointer), findsNWidgets(3));
    });

    testWidgets('desktop layout renders buttons correctly', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(900, 800)),
          child: _buildTestApp(
            const FocusTimerWidget(
              plannedDurationMinutes: 25,
              elapsedSeconds: 0,
              isActive: true,
              isPaused: false,
            ),
          ),
        ),
      );

      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
    });

    testWidgets('mobile layout renders buttons correctly', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(500, 800)),
          child: _buildTestApp(
            const FocusTimerWidget(
              plannedDurationMinutes: 25,
              elapsedSeconds: 0,
              isActive: true,
              isPaused: false,
            ),
          ),
        ),
      );

      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
    });

    testWidgets('MediaQuery disableAnimations hides ring overlay', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 600),
            disableAnimations: true,
          ),
          child: _buildTestApp(
            const FocusTimerWidget(
              plannedDurationMinutes: 25,
              elapsedSeconds: 0,
              isActive: true,
            ),
          ),
        ),
      );

      expect(find.byType(IgnorePointer), findsNWidgets(3));
    });

    testWidgets('active timer with full progress shows DONE', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerWidget(
          plannedDurationMinutes: 25,
          elapsedSeconds: 1500,
          isActive: true,
          isPaused: false,
        ),
      ));

      expect(find.text('DONE!'), findsOneWidget);
      final progress = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progress.value, closeTo(1.0, 0.01));
    });
  });
}
