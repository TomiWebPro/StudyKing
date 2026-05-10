import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/sessions/presentation/session_history_screen.dart';

Widget buildTestApp() {
  return MaterialApp(
    home: const SessionHistoryScreen(),
  );
}

void main() {
  group('SessionHistoryScreen', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('renders app bar with correct title', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.text('Session History'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator while loading', (tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state after load completes', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('No sessions yet'), findsOneWidget);
      expect(find.text('Start studying to track your progress'), findsOneWidget);
    });

    testWidgets('shows filter buttons', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Filter by Date'), findsOneWidget);
      expect(find.text('Filter by Subject'), findsOneWidget);
    });

    testWidgets('filter buttons have correct icons', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('shows summary stat labels', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Total Time'), findsOneWidget);
      expect(find.text('Average'), findsOneWidget);
    });

    testWidgets('shows zero summary stats when empty', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('0'), findsOneWidget);
      expect(find.text('0m'), findsAtLeastNWidgets(1));
    });

    testWidgets('does not show clear filters button when no filters active', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('shows history icon in empty state', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byIcon(Icons.history), findsAtLeastNWidgets(1));
    });

    testWidgets('summary stat icons are displayed', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('filter bar has buttons', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(OutlinedButton), findsWidgets);
    });
  });
}
