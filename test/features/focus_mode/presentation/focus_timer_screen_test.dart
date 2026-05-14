import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/focus_mode/presentation/focus_timer_screen.dart';

Widget _buildTestApp(Widget widget) {
  return ProviderScope(
    child: MaterialApp(
      home: widget,
    ),
  );
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(dir.path);
    await Hive.openBox<String>('focus_sessions');
  });

  tearDown(() async {
    if (Hive.isBoxOpen('focus_sessions')) {
      await Hive.deleteBoxFromDisk('focus_sessions');
    }
  });

  group('FocusTimerScreen', () {
    testWidgets('shes loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Focus Mode'), findsOneWidget);
    });

    testWidgets('shows setup view after initialization', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New Focus Session'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
    });

    testWidgets('shows duration preset chips', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('5min'), findsOneWidget);
      expect(find.text('15min'), findsOneWidget);
      expect(find.text('25min'), findsOneWidget);
      expect(find.text('30min'), findsOneWidget);
      expect(find.text('45min'), findsOneWidget);
      expect(find.text('60min'), findsOneWidget);
    });

    testWidgets('shows focus button with default duration', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Focus for 25 minutes'), findsOneWidget);
    });

    testWidgets('changes selected duration when chip is tapped', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('45min'));
      await tester.pump();

      expect(find.text('Focus for 45 minutes'), findsOneWidget);
    });

    testWidgets('shows SessionSummaryCard', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Focus Time'), findsOneWidget);
    });

    testWidgets('shows refresh button in app bar', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('accepts preselectedSubjectId parameter', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(preselectedSubjectId: 'subj-1'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New Focus Session'), findsOneWidget);
    });

    testWidgets('accepts preselectedTopicId parameter', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(preselectedTopicId: 'topic-1'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New Focus Session'), findsOneWidget);
    });

    testWidgets('accepts defaultDurationMinutes parameter', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(defaultDurationMinutes: 45),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New Focus Session'), findsOneWidget);
    });

    testWidgets('25min chip is selected by default', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final chip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('25min'),
          matching: find.byType(ChoiceChip),
        ).first,
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('non-default chips are not selected', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const FocusTimerScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final chip5 = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('5min'),
          matching: find.byType(ChoiceChip),
        ).first,
      );
      expect(chip5.selected, isFalse);
    });
  });
}
