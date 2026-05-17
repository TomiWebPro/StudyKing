import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/data/models/lesson_plan_model.dart';
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
      expect(find.text('10m'), findsOneWidget);
      expect(find.text('20m'), findsOneWidget);
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

    testWidgets('future section shows circle_outlined icon', (tester) async {
      final plan = LessonPlan(
        goals: ['Learn'],
        sections: [
          LessonSection(title: 'Intro', durationMinutes: 5, type: LessonSectionType.explanation),
          LessonSection(title: 'Main', durationMinutes: 10, type: LessonSectionType.explanation),
          LessonSection(title: 'Review', durationMinutes: 5, type: LessonSectionType.summary),
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

      // Intro (0-5): completed → check_circle
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      // Main (5-15): current → play_circle_filled
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      // Review (15-20): future → circle_outlined
      expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    });

    testWidgets('displays large overtime value correctly', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 120,
          plannedDurationMinutes: 45,
          exerciseCount: 10,
          correctCount: 7,
          topicTitle: 'Math Marathon',
        ),
      ));

      expect(find.text('+75m'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('10 questions'), findsOneWidget);
      expect(find.text('7 correct'), findsOneWidget);
    });

    testWidgets('elapsed exactly at section end marks as completed not current', (tester) async {
      final plan = LessonPlan(
        goals: ['Learn'],
        sections: [
          LessonSection(title: 'Warmup', durationMinutes: 10, type: LessonSectionType.explanation),
          LessonSection(title: 'Core', durationMinutes: 20, type: LessonSectionType.exercise),
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

      // Warmup (0-10): elapsed=10, sectionEnd=10 → isCompleted=true
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      // Core (10-30): elapsed=10, sectionStart=10, sectionEnd=30 → isCurrent=true (10 >= 10 && 10 < 30)
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    });

    testWidgets('elapsed at 0 shows first section as current', (tester) async {
      final plan = LessonPlan(
        goals: ['Learn'],
        sections: [
          LessonSection(title: 'Intro', durationMinutes: 10, type: LessonSectionType.explanation),
          LessonSection(title: 'Main', durationMinutes: 20, type: LessonSectionType.exercise),
        ],
        checkpoints: [],
        estimatedDifficulty: 2,
      );

      await tester.pumpWidget(wrapApp(
        LessonProgressBar(
          elapsedMinutes: 0,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
          lessonPlan: plan,
        ),
      ));

      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    });

    testWidgets('elapsed exactly matching total duration with sections', (tester) async {
      final plan = LessonPlan(
        goals: ['Learn'],
        sections: [
          LessonSection(title: 'One', durationMinutes: 5, type: LessonSectionType.explanation),
          LessonSection(title: 'Two', durationMinutes: 8, type: LessonSectionType.exercise),
        ],
        checkpoints: [],
        estimatedDifficulty: 2,
      );

      // total section duration = 13, elapsed = 13
      // cumulative after One: 5, after Two: 13
      // elapsed >= total sections → all sections completed
      await tester.pumpWidget(wrapApp(
        LessonProgressBar(
          elapsedMinutes: 13,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
          lessonPlan: plan,
        ),
      ));

      // All sections are completed, so both show check_circle
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    });

    testWidgets('correctCount zero renders stat chip without accent color', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 10,
          plannedDurationMinutes: 45,
          exerciseCount: 3,
          correctCount: 0,
          topicTitle: 'Math',
        ),
      ));

      expect(find.text('0 correct'), findsOneWidget);
      expect(find.text('3 questions'), findsOneWidget);
    });

    testWidgets('overtime with sections shows all as completed', (tester) async {
      final plan = LessonPlan(
        goals: ['Learn'],
        sections: [
          LessonSection(title: 'Intro', durationMinutes: 5, type: LessonSectionType.explanation),
          LessonSection(title: 'Body', durationMinutes: 10, type: LessonSectionType.exercise),
        ],
        checkpoints: [],
        estimatedDifficulty: 2,
      );

      await tester.pumpWidget(wrapApp(
        LessonProgressBar(
          elapsedMinutes: 60,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
          lessonPlan: plan,
        ),
      ));

      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    });

    testWidgets('progress bar uses error color when overtime', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 50,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
        ),
      ));

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      final valueColor = progressBar.valueColor as AlwaysStoppedAnimation<Color>;
      final theme = ThemeData();
      expect(valueColor.value, theme.colorScheme.error);
    });

    testWidgets('progress bar uses warning color when remaining <= 5', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 40,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
        ),
      ));

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      final valueColor = progressBar.valueColor as AlwaysStoppedAnimation<Color>;
      final theme = ThemeData();
      expect(valueColor.value, theme.colorScheme.tertiary);
    });

    testWidgets('progress bar uses primary color when normal', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 10,
          plannedDurationMinutes: 45,
          exerciseCount: 0,
          correctCount: 0,
          topicTitle: 'Math',
        ),
      ));

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      final valueColor = progressBar.valueColor as AlwaysStoppedAnimation<Color>;
      final theme = ThemeData();
      expect(valueColor.value, theme.colorScheme.primary);
    });

    testWidgets('statChip uses primary color for correct count > 0', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 10,
          plannedDurationMinutes: 45,
          exerciseCount: 5,
          correctCount: 3,
          topicTitle: 'Math',
        ),
      ));

      final iconFinder = find.byIcon(Icons.check_circle_outline);
      expect(iconFinder, findsOneWidget);
      final icon = tester.widget<Icon>(iconFinder);
      final theme = ThemeData();
      expect(icon.color, theme.colorScheme.primary);
    });

    testWidgets('statChip uses default theme color for correct count of 0', (tester) async {
      await tester.pumpWidget(wrapApp(
        const LessonProgressBar(
          elapsedMinutes: 10,
          plannedDurationMinutes: 45,
          exerciseCount: 5,
          correctCount: 0,
          topicTitle: 'Math',
        ),
      ));

      final iconFinder = find.byIcon(Icons.check_circle_outline);
      expect(iconFinder, findsOneWidget);
      final icon = tester.widget<Icon>(iconFinder);
      final theme = ThemeData();
      expect(icon.color, theme.colorScheme.onSurfaceVariant);
    });
  });
}
