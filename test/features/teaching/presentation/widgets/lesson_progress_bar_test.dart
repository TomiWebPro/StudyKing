import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/presentation/widgets/lesson_progress_bar.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('LessonProgressBar', () {
    testWidgets('displays topic title', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 5,
          plannedDurationMinutes: 45,
          exerciseCount: 3,
          correctCount: 2,
          topicTitle: 'Algebra Basics',
        ),
      ));

      expect(find.text('Algebra Basics'), findsOneWidget);
    });

    testWidgets('shows remaining time when within duration', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 10,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
        ),
      ));

      expect(find.text('35 min remaining'), findsOneWidget);
    });

    testWidgets('shows overtime indicator when exceeding duration', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 50,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
        ),
      ));

      expect(find.text('+5m'), findsOneWidget);
    });

    testWidgets('shows zero remaining when exactly at duration', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 45,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
        ),
      ));

      expect(find.text('0 min remaining'), findsOneWidget);
    });

    testWidgets('displays exercise stat chips', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 10,
          plannedDurationMinutes: 45,
          exerciseCount: 5,
          correctCount: 3,
          topicTitle: 'Science',
        ),
      ));

      expect(find.text('5 questions'), findsOneWidget);
      expect(find.text('3 correct'), findsOneWidget);
    });

    testWidgets('displays progress percentage', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 15,
          plannedDurationMinutes: 60,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'History',
        ),
      ));

      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('shows 0% when elapsed is 0', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 0,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
        ),
      ));

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('shows 100% when exceeding planned duration', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 60,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
        ),
      ));

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('displays correct stat with icon', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 10,
          plannedDurationMinutes: 45,
          exerciseCount: 4,
          correctCount: 4,
          topicTitle: 'Physics',
        ),
      ));

      expect(find.byIcon(Icons.quiz_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('displays linear progress indicator', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 20,
          plannedDurationMinutes: 40,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
        ),
      ));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
