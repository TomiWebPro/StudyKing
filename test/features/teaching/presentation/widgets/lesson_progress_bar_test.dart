import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/models/lesson_plan_model.dart';
import 'package:studyking/features/teaching/presentation/widgets/lesson_progress_bar.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
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

    testWidgets('shows section timeline when lessonPlan is provided', (tester) async {
      final plan = LessonPlan(
        goals: ['Learn'],
        sections: [
          LessonSection(title: 'Intro', durationMinutes: 10, type: LessonSectionType.explanation),
          LessonSection(title: 'Practice', durationMinutes: 20, type: LessonSectionType.exercise),
        ],
        checkpoints: ['CP1'],
        estimatedDifficulty: 2,
      );

      await tester.pumpWidget(wrapApp(
        LessonProgressBar(
          elapsedMinutes: 5,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
          lessonPlan: plan,
        ),
      ));

      expect(find.text('Intro'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('10min'), findsOneWidget);
      expect(find.text('20min'), findsOneWidget);
    });

    testWidgets('highlights current section in timeline', (tester) async {
      final plan = LessonPlan(
        goals: ['Learn'],
        sections: [
          LessonSection(title: 'Intro', durationMinutes: 5, type: LessonSectionType.explanation),
          LessonSection(title: 'Main', durationMinutes: 20, type: LessonSectionType.explanation),
        ],
        checkpoints: [],
        estimatedDifficulty: 2,
      );

      await tester.pumpWidget(wrapApp(
        LessonProgressBar(
          elapsedMinutes: 10,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
          lessonPlan: plan,
        ),
      ));

      expect(find.text('Main'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    });

    testWidgets('marks completed sections with check icon', (tester) async {
      final plan = LessonPlan(
        goals: ['Learn'],
        sections: [
          LessonSection(title: 'Intro', durationMinutes: 5, type: LessonSectionType.explanation),
          LessonSection(title: 'Main', durationMinutes: 20, type: LessonSectionType.explanation),
        ],
        checkpoints: [],
        estimatedDifficulty: 2,
      );

      await tester.pumpWidget(wrapApp(
        LessonProgressBar(
          elapsedMinutes: 10,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
          lessonPlan: plan,
        ),
      ));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows warning color when remaining 5 min or less', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 40,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
        ),
      ));

      expect(find.text('5 min remaining'), findsOneWidget);
    });

    testWidgets('shows 1 min remaining for exactly 1 minute left', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 44,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
        ),
      ));

      expect(find.text('1 min remaining'), findsOneWidget);
    });

    testWidgets('lesson plan with empty sections does not show timeline', (tester) async {
      final plan = LessonPlan(
        goals: ['Learn'],
        sections: [],
        checkpoints: [],
        estimatedDifficulty: 2,
      );

      await tester.pumpWidget(wrapApp(
        LessonProgressBar(
          elapsedMinutes: 5,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
          lessonPlan: plan,
        ),
      ));

      expect(find.byIcon(Icons.circle_outlined), findsNothing);
      expect(find.byIcon(Icons.play_circle_filled), findsNothing);
    });

    testWidgets('lesson plan being null does not crash and shows no timeline', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 5,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
        ),
      ));

      expect(find.text('Intro'), findsNothing);
      expect(find.text('Practice'), findsNothing);
    });

    testWidgets('displays zero progress when elapsed is zero', (tester) async {
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
      expect(find.text('45 min remaining'), findsOneWidget);
    });

    testWidgets('correctCount > 0 applies color to stat chip', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 10,
          plannedDurationMinutes: 45,
          exerciseCount: 5,
          correctCount: 3,
          topicTitle: 'Math',
        ),
      ));

      expect(find.text('3 correct'), findsOneWidget);
      expect(find.text('5 questions'), findsOneWidget);
    });
  });
}
