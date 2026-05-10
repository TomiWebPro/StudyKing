import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/pages/lesson_scheduling_page.dart';
import 'package:studyking/providers/llm_engine_provider.dart';

void main() {
  group('LessonSchedulingPage', () {
    late LLMAIEngineProvider engine;

    setUp(() {
      engine = LLMAIEngineProvider();
    });

    testWidgets('renders schedule UI sections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: LessonSchedulingPage(llmProvider: engine)),
      );

      expect(find.text('Lesson Scheduler'), findsOneWidget);
      expect(find.text('Upcoming Lessons'), findsOneWidget);
      expect(find.text('Select Subject'), findsOneWidget);
      expect(find.text('Generate Question Types'), findsOneWidget);
      expect(find.text('Lesson Progress'), findsOneWidget);
      expect(find.text('65% Complete: 5/8 questions generated'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows add lesson bottom sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: LessonSchedulingPage(llmProvider: engine)),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Create New Lesson'), findsOneWidget);
      expect(find.text('Edit Existing Lesson'), findsOneWidget);
    });

    testWidgets('shows calendar dialog and closes it', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: LessonSchedulingPage(llmProvider: engine)),
      );

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      expect(find.text('Schedule Lesson'), findsOneWidget);
      expect(find.text('Select calendar date for lesson'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Schedule Lesson'), findsNothing);
    });
  });
}
