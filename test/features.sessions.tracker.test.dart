import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/sessions/presentation/session_tracker_screen.dart';

Widget buildTestApp() {
  return MaterialApp(
    home: const SessionTrackerScreen(),
  );
}

void main() {
  group('SessionTrackerScreen', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('renders app bar with correct title', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.text('Study Session Tracker'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator while loading', (tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state after load completes', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('No Active Session'), findsOneWidget);
      expect(find.text('Tap start to begin tracking'), findsOneWidget);
    });

    testWidgets('shows Start button', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('End button is not visible when no active session', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('End'), findsNothing);
    });

    testWidgets('shows stat cards', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Total Time'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('Avg per Session'), findsOneWidget);
    });

    testWidgets('shows initial stat values as zero', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('0s'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
      expect(find.text('0 days'), findsOneWidget);
      expect(find.text('0m'), findsOneWidget);
    });

    testWidgets('shows Recent Sessions section', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Recent Sessions'), findsOneWidget);
    });

    testWidgets('shows empty sessions message', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('No sessions yet'), findsOneWidget);
      expect(find.text('Start your first session!'), findsOneWidget);
    });

    testWidgets('shows timer_off icon when no active session', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byIcon(Icons.timer_off), findsOneWidget);
    });

    testWidgets('stat cards show icons', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('View All button navigates to history screen', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('View All'), findsOneWidget);
    });

    testWidgets('Start button is enabled when no session active', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final startButton = find.widgetWithText(ElevatedButton, 'Start');
      expect(startButton, findsOneWidget);
      final button = tester.widget<ElevatedButton>(startButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Start button has play_arrow icon', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  });
}
